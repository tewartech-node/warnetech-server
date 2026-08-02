-- warnetech-server-data — vault support for local forwarding
-- Adds a vault concept (e.g. "Personal Vault") that groups forwarding
-- rules and ties their secret material to a Cloudflare storage backend,
-- with optional periodic backup of vault metadata to Google Drive.
-- Created: 2026-08-02

CREATE TABLE IF NOT EXISTS vaults (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  owner TEXT NOT NULL,
  storage_backend TEXT DEFAULT 'cloudflare_kv',
  cloudflare_namespace_id TEXT,
  cloudflare_account_id TEXT,
  drive_backup_enabled INTEGER DEFAULT 0,
  drive_backup_folder_id TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- Seed the default vault seen in the client UI ("Personal Vault").
-- Created 2026-08-02 with real Cloudflare KV namespace and Google Drive backup folder.
INSERT OR IGNORE INTO vaults (name, owner, storage_backend, cloudflare_namespace_id, drive_backup_enabled, drive_backup_folder_id)
VALUES ('Personal Vault', 'default', 'cloudflare_kv', 'd02d4b37379145119df99831045c5d0b', 1, '1PfrZcW75b41dzUiKeTf9lpdjt-tO6Wy9');

-- Link each forwarding config to the vault it belongs to.
ALTER TABLE local_forwarding_configs ADD COLUMN vault_id INTEGER REFERENCES vaults(id);

-- Backfill existing rows to the default vault.
UPDATE local_forwarding_configs
SET vault_id = (SELECT id FROM vaults WHERE name = 'Personal Vault')
WHERE vault_id IS NULL;

-- Record of each export of a vault's config data to Google Drive.
CREATE TABLE IF NOT EXISTS vault_backups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vault_id INTEGER NOT NULL,
  drive_file_id TEXT NOT NULL,
  drive_file_url TEXT,
  backup_type TEXT DEFAULT 'full',
  record_count INTEGER,
  status TEXT DEFAULT 'completed',
  error TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (vault_id) REFERENCES vaults(id)
);

CREATE INDEX IF NOT EXISTS idx_forwarding_configs_vault_id ON local_forwarding_configs(vault_id);
CREATE INDEX IF NOT EXISTS idx_vault_backups_vault_id ON vault_backups(vault_id);
CREATE INDEX IF NOT EXISTS idx_vault_backups_created_at ON vault_backups(created_at);
