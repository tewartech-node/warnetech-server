-- warnetech-server-data — base schema
-- Applied to the D1 database on 2026-08-01 after the account reset wiped it.
-- Idempotent: safe to re-run against an existing database.

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT,
  username TEXT,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS memories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL,
  fact TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS shared_knowledge (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  insight TEXT NOT NULL,
  source_session TEXT,
  hits INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);

-- Audit trail for every connector call made through /api/connectors/:name/execute.
-- Separate from the fuller agent_actions table Phase 2 will add, which tracks
-- agent *decisions* (plan + rationale), not just raw connector I/O.
CREATE TABLE IF NOT EXISTS connector_audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT DEFAULT (datetime('now')),
  connector TEXT NOT NULL,
  action TEXT NOT NULL,
  params_json TEXT,
  success INTEGER NOT NULL,
  error TEXT,
  source TEXT
);

CREATE INDEX IF NOT EXISTS idx_messages_username ON messages(username);
CREATE INDEX IF NOT EXISTS idx_memories_username ON memories(username);
CREATE INDEX IF NOT EXISTS idx_connector_audit_timestamp ON connector_audit_log(timestamp);
