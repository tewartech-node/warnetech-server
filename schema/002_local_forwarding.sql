-- warnetech-server-data — local forwarding schema
-- Tracks local port forwarding configurations for secure tunnels
-- Created: 2026-08-02

-- Store local forwarding configurations
CREATE TABLE IF NOT EXISTS local_forwarding_configs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  config_name TEXT NOT NULL UNIQUE,
  local_port INTEGER NOT NULL,
  bind_address TEXT DEFAULT '127.0.0.1',
  remote_host TEXT NOT NULL,
  remote_port INTEGER NOT NULL,
  tunnel_type TEXT DEFAULT 'ssh',
  status TEXT DEFAULT 'inactive',
  created_by TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- Track active forwarding sessions/tunnels
CREATE TABLE IF NOT EXISTS forwarding_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  config_id INTEGER NOT NULL,
  session_id TEXT NOT NULL UNIQUE,
  tunnel_host TEXT NOT NULL,
  tunnel_port INTEGER NOT NULL,
  credentials_ref TEXT,
  status TEXT DEFAULT 'establishing',
  established_at TEXT,
  closed_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (config_id) REFERENCES local_forwarding_configs(id)
);

-- Audit trail for forwarding activities
CREATE TABLE IF NOT EXISTS forwarding_audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  config_id INTEGER,
  session_id INTEGER,
  event_type TEXT NOT NULL,
  details TEXT,
  timestamp TEXT DEFAULT (datetime('now')),
  user TEXT
);

-- Performance metrics for forwarding sessions
CREATE TABLE IF NOT EXISTS forwarding_metrics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  bytes_sent INTEGER DEFAULT 0,
  bytes_received INTEGER DEFAULT 0,
  active_connections INTEGER DEFAULT 0,
  latency_ms INTEGER,
  last_activity_at TEXT,
  recorded_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (session_id) REFERENCES forwarding_sessions(id)
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_forwarding_configs_status ON local_forwarding_configs(status);
CREATE INDEX IF NOT EXISTS idx_forwarding_configs_created_by ON local_forwarding_configs(created_by);
CREATE INDEX IF NOT EXISTS idx_forwarding_sessions_config_id ON forwarding_sessions(config_id);
CREATE INDEX IF NOT EXISTS idx_forwarding_sessions_status ON forwarding_sessions(status);
CREATE INDEX IF NOT EXISTS idx_forwarding_audit_config_id ON forwarding_audit_log(config_id);
CREATE INDEX IF NOT EXISTS idx_forwarding_audit_timestamp ON forwarding_audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_forwarding_metrics_session_id ON forwarding_metrics(session_id);
