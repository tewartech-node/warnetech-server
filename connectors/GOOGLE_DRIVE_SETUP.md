# warnetech-server — Google Drive Backup Setup Guide

**Backup Account:** warnet.dev01@gmail.com  
**Purpose:** Isolated automated backups (separate from personal account)  
**Status:** Ready for configuration

---

## 📋 Setup Steps (30 minutes)

### Step 1: Create Google Cloud Project

```bash
# 1. Go to Google Cloud Console
#    https://console.cloud.google.com

# 2. Create new project
#    - Name: warnetech-server-backups
#    - Organization: (optional)
#    - Project ID: warnetech-server-backups-RANDOM

# 3. Enable APIs
#    - Search for "Google Drive API"
#    - Click "Enable"
#    - Wait for activation (~ 30 seconds)

# 4. Note your Project ID (you'll need it)
```

**Save:** Project ID (e.g., `warnetech-server-backups-abc123`)

---

### Step 2: Create Service Account

```bash
# 1. In Google Cloud Console:
#    APIs & Services → Credentials → Create Credentials

# 2. Select: Service Account
#    - Service account name: warnetech-backup-service
#    - Service account ID: (auto-generated)
#    - Description: Automated backups for warnetech-server

# 3. Grant roles (click "Continue"):
#    - Editor (for full Drive access)
#    - Or minimal: roles/drive.file

# 4. Create key:
#    - Key type: JSON
#    - Click "Create"
#    - **DOWNLOAD THE JSON FILE - SAVE SECURELY**

# The downloaded file should contain:
# {
#   "type": "service_account",
#   "project_id": "...",
#   "private_key_id": "...",
#   "private_key": "...",
#   "client_email": "warnetech-backup-service@...",
#   "client_id": "...",
#   "auth_uri": "...",
#   "token_uri": "...",
#   "auth_provider_x509_cert_url": "..."
# }
```

**Save:** 
- Service Account Email (e.g., `warnetech-backup-service@warnetech-server-backups-abc123.iam.gserviceaccount.com`)
- JSON key file (keep secure - do NOT commit to git)

---

### Step 3: Create Backup Folder in warnet.dev01@gmail.com

```bash
# 1. Log into warnet.dev01@gmail.com

# 2. Create folder structure:
#    Google Drive → New → Folder
#    Name: warnetech-server-backups
#
#    Inside it, create:
#    ├── daily/
#    ├── weekly/
#    ├── monthly/
#    ├── logs/
#    ├── audit/
#    ├── documents/
#    └── metadata/

# 3. Get folder ID:
#    - Right-click "warnetech-server-backups" → Share
#    - Copy the folder ID from URL
#    # URL looks like: https://drive.google.com/drive/folders/FOLDER-ID
#    # FOLDER-ID is what you need

# 4. Share with service account:
#    - Click Share
#    - Paste service account email:
#      warnetech-backup-service@...iam.gserviceaccount.com
#    - Role: Editor
#    - Send (notification not needed)
```

**Save:** Folder ID (e.g., `1abc2def3ghi4jkl5mno6pqr7stu8vwx`)

---

### Step 4: Store Credentials in Cloudflare KV

```bash
# 1. Upload JSON key to secure location
#    DO NOT commit to git
#    DO NOT upload to GitHub
#
#    Store it:
#    - In a password manager (Bitwarden, 1Password, etc.)
#    - Or in Cloudflare KV (encrypted by the Worker)

# 2. Via Wrangler (recommended - encrypted in KV):
wrangler kv:key put \
  --namespace-id=13ae17b9d3e64a6a87745c62a2941e1d \
  google-backup-service-key \
  @path/to/service-account-key.json

# 3. Verify it's stored:
wrangler kv:key list \
  --namespace-id=13ae17b9d3e64a6a87745c62a2941e1d | grep google
```

---

### Step 5: Update Configuration Files

Edit `google-drive-backup-config.json`:

```json
{
  "authentication": {
    "serviceAccountEmail": "warnetech-backup-service@warnetech-server-backups-PROJECTID.iam.gserviceaccount.com"
  },
  "storage": {
    "rootFolderId": "YOUR-FOLDER-ID"
  }
}
```

Replace:
- `PROJECTID` - Your Google Cloud Project ID
- `YOUR-FOLDER-ID` - Folder ID from Step 3

---

### Step 6: Deploy Worker Code

```bash
# 1. Copy the backup functions to your Worker

# 2. Update wrangler.toml:
[env.production]
vars = { BACKUP_FOLDER_ID = "YOUR-FOLDER-ID" }

# 3. Deploy
npm run deploy
```

---

### Step 7: Test the Backup

```bash
# 1. Trigger a test backup:
curl -X POST https://testllm.warnetwork.cloud/api/backup/test \
  -H "Authorization: Bearer YOUR-SERVICE-TOKEN"

# 2. Check response:
# Expected: { "status": "success", "file_id": "..." }

# 3. Verify in Google Drive:
# - Log into warnet.dev01@gmail.com
# - Open warnetech-server-backups folder
# - Check for new files in daily/ subfolder
```

---

## 🔐 Security Checklist

```
☐ Service account created in Google Cloud
☐ JSON key downloaded and stored securely (NOT in git)
☐ Folder created in warnet.dev01@gmail.com
☐ Folder shared with service account email
☐ Credentials uploaded to Cloudflare KV (encrypted)
☐ Configuration updated with correct IDs
☐ Test backup succeeded
☐ Files visible in Google Drive backup folder
☐ Old JSON key can be deleted from local machine
```

---

## 📊 Backup Schedule

Once deployed, backups run automatically:

| Backup Type | Frequency | Time | Retention | Destination |
|-------------|-----------|------|-----------|------------|
| Database | Daily | 02:00 UTC | 30 days | daily/ |
| Audit Logs | Hourly | Every hour | 90 days | logs/ |
| Full Export | Weekly | Sunday 03:00 UTC | 90 days | weekly/ |
| Monthly Archive | Monthly | 1st of month 04:00 UTC | 1 year | monthly/ |

---

## 🆘 Troubleshooting

### Error: "Access denied" when uploading

**Cause:** Folder not shared with service account  
**Fix:**
1. Log into warnet.dev01@gmail.com
2. Right-click warnetech-server-backups folder → Share
3. Paste service account email → Editor role → Save

### Error: "Quota exceeded"

**Cause:** Backup folder too large (> 50GB)  
**Fix:**
1. Delete old backups from daily/ folder (keep 7 recent)
2. Or contact Google for quota increase
3. Monitor: Check MONITORING alerts weekly

### Error: "Service account key invalid"

**Cause:** KV credential is corrupted or expired  
**Fix:**
1. Generate new service account key in Google Cloud
2. Update in Cloudflare KV:
   ```bash
   wrangler kv:key put \
     --namespace-id=13ae17b9d3e64a6a87745c62a2941e1d \
     google-backup-service-key \
     @new-key.json
   ```
3. Redeploy Worker

### Backups not appearing in Google Drive

**Debug:**
1. Check Worker logs: `npx wrangler tail`
2. Verify folder ID is correct
3. Verify service account has permissions
4. Run manual test with verbose logging

---

## 📝 File Naming Convention

Backups follow this pattern:

```
daily/
  warnetech-server-data-2026-08-02T02:00:00Z.json.gz
  warnetech-server-data-2026-08-03T02:00:00Z.json.gz

weekly/
  warnetech-server-full-export-2026-08-04T03:00:00Z.sql

logs/
  audit-2026-08-02T12:34:56Z.json
  audit-2026-08-02T13:34:56Z.json

monthly/
  warnetech-server-archive-2026-08.zip
```

---

## 🔄 Recovery Process

If you need to restore from backup:

1. **List available backups:**
   ```bash
   # Via warnet.dev01@gmail.com Google Drive
   # Open warnetech-server-backups/daily folder
   # Pick the date you want
   ```

2. **Download backup file:**
   ```bash
   # Right-click → Download
   # Save locally
   ```

3. **Restore to D1:**
   ```bash
   # See RESTORE.md in this repo
   gunzip warnetech-server-data-2026-08-02T02:00:00Z.json.gz
   wrangler d1 import warnetech-server-data warnetech-server-data-2026-08-02T02:00:00Z.json
   ```

---

## 📞 Support

- **Configuration questions:** See `google-drive-backup-config.json`
- **Database restore:** See `schema/RESTORE.md`
- **Troubleshooting:** See `RUNBOOK.md` § Predictable failures → D1 wiped

---

## ✅ Next Steps

1. Complete Steps 1-7 above (30 minutes)
2. Verify test backup succeeds
3. Monitor first week of automated backups
4. Document any custom folder structures in this file
5. Set calendar reminder for quarterly restore test

**Status:** Ready to deploy  
**Estimated setup time:** 30 minutes  
**Required:** Google Cloud account + warnet.dev01@gmail.com access
