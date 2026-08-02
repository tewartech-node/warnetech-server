# Warnetech-Server Service Registry

**Naming Convention:** `warnetech-server-*` for all project resources.

## Cloudflare

| Service | Type | ID | Purpose |
|---|---|---|---|
| warnetech-server-worker | Worker | — | Main app (not yet deployed) |
| warnetech-server-data | D1 | f347b59b-bf32-451c-ae81-2c87182ee364 | Core database |
| warnetech-server-vault | KV | 13ae17b9d3e64a6a87745c62a2941e1d | Connector credentials |
| warnetech-server-sessions | KV | 8c39c2864e30456d8dcc9fe2eb9e6314 | Session state |
| warnetech-server-personal-vault | KV | d02d4b37379145119df99831045c5d0b | Forwarding rule secrets |
| warnetech-server-ratelimit | KV | e8c2dd383e2c4227bd6159d2149753fd | Rate limiting |
| warnetech-server-backup | R2 | — | Backups (Phase 3) |

## GitHub

| Repo | Role |
|---|---|
| warnetech-server | Docs & schema (this repo) |
| llm-chat-app-template | App source code |

## Google Drive

| Folder | Purpose |
|---|---|
| Warnetech Vault Backups | Forwarding rule metadata backups |

**All new services use `warnetech-server-{purpose}` naming.**
