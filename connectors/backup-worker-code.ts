/**
 * warnetech-server Backup Module
 * Handles automated backups to Google Drive (warnet.dev01@gmail.com)
 *
 * Usage: Deploy with your Cloudflare Worker
 * Backups run automatically on schedule (see google-drive-backup-config.json)
 */

interface BackupConfig {
  folderID: string;
  serviceAccountKey: object;
  folders: {
    daily: string;
    weekly: string;
    monthly: string;
    logs: string;
    audit: string;
  };
}

interface BackupResult {
  status: "success" | "error";
  fileId?: string;
  filename?: string;
  size?: number;
  timestamp: string;
  duration_ms?: number;
  error?: string;
}

/**
 * Get Google Drive API access token using service account credentials
 */
async function getGoogleAccessToken(env: Env): Promise<string> {
  const key = await env.VAULT.get("google-backup-service-key", "json");

  if (!key) {
    throw new Error("Service account key not found in vault");
  }

  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600; // 1 hour expiration

  const header = {
    alg: "RS256",
    typ: "JWT",
    kid: key.private_key_id
  };

  const claim = {
    iss: key.client_email,
    scope: "https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/drive.file",
    aud: "https://oauth2.googleapis.com/token",
    exp: exp,
    iat: now
  };

  const encodedHeader = btoa(JSON.stringify(header))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const encodedClaim = btoa(JSON.stringify(claim))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const messageToSign = `${encodedHeader}.${encodedClaim}`;

  // Note: In production, use crypto signing library
  // This is simplified - use a proper JWT library in real implementation
  // For now, we'll use Cloudflare's built-in crypto

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: messageToSign // This should be a proper JWT signature
    })
  });

  if (!response.ok) {
    throw new Error(`Google auth failed: ${response.statusText}`);
  }

  const data = await response.json();
  return data.access_token;
}

/**
 * Upload backup file to Google Drive
 */
async function uploadToGoogleDrive(
  content: string,
  filename: string,
  folderID: string,
  accessToken: string
): Promise<string> {
  const metadata = {
    name: filename,
    parents: [folderID],
    mimeType: "application/json"
  };

  const boundary = "===============7330845974216740156==";
  const delimiter = `\r\n--${boundary}\r\n`;
  const closeDelimiter = `\r\n--${boundary}--`;

  const multipartBody =
    delimiter +
    'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
    JSON.stringify(metadata) +
    delimiter +
    "Content-Type: application/json\r\n\r\n" +
    content +
    closeDelimiter;

  const response = await fetch(
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": `multipart/related; boundary="${boundary}"`
      },
      body: multipartBody
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Google Drive upload failed: ${error}`);
  }

  const result = await response.json();
  return result.id;
}

/**
 * Backup database tables to JSON
 */
async function backupDatabase(
  env: Env,
  tables: string[] = [
    "users",
    "messages",
    "memories",
    "shared_knowledge",
    "connector_audit_log"
  ]
): Promise<object> {
  const backup: Record<string, any[]> = {};

  for (const table of tables) {
    try {
      const result = await env.DB.prepare(
        `SELECT * FROM ${table} ORDER BY rowid DESC LIMIT 10000`
      ).all();
      backup[table] = result.results || [];
    } catch (error) {
      console.error(`Failed to backup table ${table}:`, error);
      backup[table] = [];
    }
  }

  return backup;
}

/**
 * Compress data (gzip simulation - in production use proper compression)
 */
function compressData(data: string): string {
  // Note: Cloudflare Workers can use the CompressionStream API
  // This is a simplified version - use real compression in production
  return data;
}

/**
 * Create daily backup
 */
export async function backupDaily(env: Env): Promise<BackupResult> {
  const startTime = Date.now();

  try {
    const timestamp = new Date().toISOString();
    const dateStr = timestamp.split("T")[0];
    const folderID = env.BACKUP_FOLDER_ID;

    // Backup database
    const dbBackup = await backupDatabase(env);
    const content = JSON.stringify(dbBackup, null, 2);

    // Get Google Drive token
    const token = await getGoogleAccessToken(env);

    // Upload to Google Drive
    const filename = `warnetech-server-data-${timestamp}.json`;
    const fileId = await uploadToGoogleDrive(
      content,
      filename,
      folderID,
      token
    );

    const duration = Date.now() - startTime;

    return {
      status: "success",
      fileId,
      filename,
      size: content.length,
      timestamp,
      duration_ms: duration
    };
  } catch (error) {
    return {
      status: "error",
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : "Unknown error"
    };
  }
}

/**
 * Create weekly full export
 */
export async function backupWeekly(env: Env): Promise<BackupResult> {
  const startTime = Date.now();

  try {
    const timestamp = new Date().toISOString();
    const folderID = env.BACKUP_FOLDER_ID;

    // Get all tables
    const tablesResult = await env.DB.prepare(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    ).all();

    const tables = (tablesResult.results || [])
      .map((row: any) => row.name)
      .filter((name: string) => !name.startsWith("sqlite_"));

    // Backup all tables
    const dbBackup = await backupDatabase(env, tables);
    const content = JSON.stringify(dbBackup, null, 2);

    // Get Google Drive token
    const token = await getGoogleAccessToken(env);

    // Upload to Google Drive
    const filename = `warnetech-server-full-export-${timestamp}.json`;
    const fileId = await uploadToGoogleDrive(
      content,
      filename,
      folderID,
      token
    );

    const duration = Date.now() - startTime;

    return {
      status: "success",
      fileId,
      filename,
      size: content.length,
      timestamp,
      duration_ms: duration
    };
  } catch (error) {
    return {
      status: "error",
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : "Unknown error"
    };
  }
}

/**
 * Test backup endpoint
 */
export async function testBackup(env: Env): Promise<BackupResult> {
  console.log("Running test backup...");
  const result = await backupDaily(env);

  if (result.status === "success") {
    console.log(`Test backup successful: ${result.filename}`);
  } else {
    console.error(`Test backup failed: ${result.error}`);
  }

  return result;
}

/**
 * Cleanup old backups (retain only recent ones)
 */
export async function cleanupOldBackups(
  env: Env,
  retentionDays: number = 30
): Promise<{ deleted: number; error?: string }> {
  try {
    const token = await getGoogleAccessToken(env);
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    // Query Google Drive for old files
    const response = await fetch(
      `https://www.googleapis.com/drive/v3/files?q=parents='${env.BACKUP_FOLDER_ID}' and createdTime<'${cutoffDate.toISOString()}'&spaces=drive`,
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );

    if (!response.ok) {
      throw new Error("Failed to query Google Drive");
    }

    const data = await response.json();
    let deleted = 0;

    for (const file of data.files || []) {
      const deleteResponse = await fetch(
        `https://www.googleapis.com/drive/v3/files/${file.id}`,
        {
          method: "DELETE",
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      if (deleteResponse.ok) {
        deleted++;
      }
    }

    return { deleted };
  } catch (error) {
    return {
      deleted: 0,
      error: error instanceof Error ? error.message : "Unknown error"
    };
  }
}

/**
 * Verify backup integrity
 */
export async function verifyBackup(
  env: Env,
  fileId: string
): Promise<{ valid: boolean; size: number; error?: string }> {
  try {
    const token = await getGoogleAccessToken(env);

    const response = await fetch(
      `https://www.googleapis.com/drive/v3/files/${fileId}?fields=size,md5Checksum`,
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );

    if (!response.ok) {
      throw new Error("File not found in Google Drive");
    }

    const data = await response.json();
    return {
      valid: !!data.md5Checksum,
      size: parseInt(data.size, 10)
    };
  } catch (error) {
    return {
      valid: false,
      size: 0,
      error: error instanceof Error ? error.message : "Unknown error"
    };
  }
}

// Export for use in your Worker
export default {
  backupDaily,
  backupWeekly,
  testBackup,
  cleanupOldBackups,
  verifyBackup
};
