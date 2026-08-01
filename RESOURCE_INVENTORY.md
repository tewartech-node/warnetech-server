# warnetech-server — Resource Inventory & Account Record

**Keep this document somewhere safe.** It is the authoritative record of every
Cloudflare and GitHub resource behind the warnetech-server AI system, what
each one is for, and how the current names relate to what existed before the
2026-08-01 account reset. Nothing in this file is a secret by itself (no keys
or tokens are recorded here), but it is the map you'd need to rebuild the
system from scratch, so treat it as sensitive infrastructure documentation.

**Record date:** 2026-08-01
**Context:** The user ran a full reset on both the Cloudflare and GitHub
accounts on 2026-08-01 to remove a prior mistaken setup. This document
reflects state *after* that reset, with the new `warnetech-server-*` naming
convention applied going forward.

---

## 1. Cloudflare resources

| Resource | Type | Current name | ID | Prior name (pre-reset) | Status |
|---|---|---|---|---|---|
| Worker | Cloudflare Worker | `warnetech-server-worker` | — (assigned on first deploy) | `servtechllmv2worker` | **Not yet deployed.** Config is ready in `wrangler.jsonc`; the reset deleted the previously deployed Worker. First `npm run deploy` will create it. |
| D1 database | D1 | `warnetech-server-data` | `f347b59b-bf32-451c-ae81-2c87182ee364` | `servtechllmv2db` (`24b91c9b-290b-4b73-ac11-24a695fb6182`) | **Live.** Recreated empty by the reset; base schema (`users`, `messages`, `memories`, `shared_knowledge`, `connector_audit_log`) has been reapplied — see `schema/001_initial_schema.sql` in this repo. |
| R2 bucket | R2 | `warnetech-server-backup` | — (buckets aren't ID'd, name is the identifier) | `servtechllmv2r2` (existed but was never bound to the Worker) | **Live, unbound.** Created for Phase 3 distributed backups; not yet wired into any code. |
| R2 bucket (unrelated) | R2 | `warnetworkcloud` | — | — | Pre-existing, untouched by this project. Not part of warnetech-server. |
| KV namespace | KV | `warnetech-server-sessions` | `8c39c2864e30456d8dcc9fe2eb9e6314` | `warnetwork-llm-sessions` (renamed in place, same ID/data) | **Live, unbound in code yet.** Intended for future session state. |
| KV namespace | KV | `warnetech-server-ratelimit` | `e8c2dd383e2c4227bd6159d2149753fd` | `warnetwork-llm-ratelimit` (renamed in place, same ID/data) | **Live, bound.** Used by the connector API rate limiter (10 calls/min per connector). |
| KV namespace | KV | `warnetech-server-vault` | `13ae17b9d3e64a6a87745c62a2941e1d` | — (new) | **Live, bound.** Holds AES-256-GCM encrypted connector credentials (GitHub token, Google OAuth creds, AWS keys). Encryption key is a separate Worker secret, not stored here. |
| Custom domain route | DNS/Route | `testllm.warnetwork.cloud` → `warnetech-server-worker` | — | same domain, previously routed to `servtechllmv2worker` | Configured in `wrangler.jsonc`; will attach on next deploy. Zone `warnetwork.cloud` already exists in the account. |
| Secret | Worker secret | `VAULT_ENCRYPTION_KEY` | — | — (new) | **Not yet set.** Must be created via `wrangler secret put VAULT_ENCRYPTION_KEY` before first deploy — 32 random bytes, base64-encoded (e.g. `openssl rand -base64 32`). Without it, the credential vault cannot encrypt/decrypt and no connector can authenticate. |

### Do NOT confuse with `servtechdb`

A separate, unrelated Cloudflare Worker (`servtechworker`) backs the actual
authenticated ServTech app and uses its own database, `servtechdb` (formerly
`warnetworkllm-db`). It has a different schema (`user_id` foreign keys, real
auth) and must never be pointed to by the `DB` binding here — doing so would
let anyone read/write ServTech's real user data through a guessed username.

---

## 2. GitHub repositories (all under `tewartech-node`)

| Repo | Visibility | Role in this project |
|---|---|---|
| `llm-chat-app-template` | public | **Main application code.** The Cloudflare Worker source (`src/index.ts`, connectors, vault, agent core as it's built). This is what gets deployed. |
| `warnetech-server` | private | **This repo.** Infrastructure knowledge base: DB schema, restore procedures, resource inventory, runbook, connector reference — files the agent (and you) can pull from without re-deriving them. |
| `AI-Defense` | private | Source of the real adaptive firewall code (`AI-Defense-Starter-Kit/defense_core.py`, `AI-Firewall-Defense-Framework/core/`) that Phase 3 ports into the Worker. Built by the user with Gemini. |
| `AI-Firewall-Pentest-Trial` | public | Related firewall/pentest material — not yet surveyed in detail. |
| `FIREWALL_SUMMERY` | private | Related firewall material — not yet surveyed in detail. |
| `sql-anomaly-detection-repo` | public | Likely relevant to Phase 3 anomaly detection — not yet surveyed. |
| `Claude-GitHub`, `claude_code_auth`, `warnetworkllm`, `termux-dev-bootstrap` | mixed | Adjacent projects, not currently wired into warnetech-server. |

---

## 3. Third-party accounts/services the agent can integrate with (Phase 1 connectors)

None of these are authenticated yet — the connector code exists, but no
credentials have been stored in the vault. Each needs a one-time
`POST /api/connectors/auth` call once the Worker is deployed.

| Connector | Service | Auth type | What it needs |
|---|---|---|---|
| `github` | GitHub API | Personal access token | A PAT with repo scope, stored via `/api/connectors/auth` |
| `google-drive` | Google Drive API | OAuth 2.0 (refresh token) | `clientId`, `clientSecret`, `refreshToken` from a Google Cloud OAuth app |
| `aws` | AWS (S3, Lambda, CloudWatch Logs) | IAM access key | `accessKeyId`, `secretAccessKey`, `region` |
| `shell` | (via GitHub Actions) | Piggybacks on the `github` connector's token | No separate auth — dispatches allow-listed commands as `workflow_dispatch` events, since Workers can't spawn real processes |
| `d1` | Cloudflare D1 (this project's own DB) | Implicit (Worker binding) | No credential needed — Cloudflare grants this at deploy time |

The Google Drive folder `warnetech-server-documents` (id
`1wQQMxCBPXwFXckYvXKNe14yPtpVgFWjd`) was created under the account's Drive
root on 2026-08-01 and holds copies of the project-relevant files that were
loose in the root (firewall docs, wrangler configs, RESTORE.md, chat app
files). Originals remain in the Drive root — the available Drive tools only
support copy, not move/delete, so nothing was removed from its original
location.

---

## 4. What's built vs. what's planned

- **Phase 1 (complete):** Connector infrastructure — GitHub, Google Drive,
  AWS, Shell, D1 connectors; encrypted vault; rate limiting; audit logging;
  `/api/connectors/*` endpoints.
- **Phase 2 (not started):** Autonomous agent core — LLM-based task planner,
  executor, guardrails, learning/memory, `agent_actions` / `agent_learnings`
  D1 tables.
- **Phase 3 (not started):** Adaptive firewall integration (ported from
  `AI-Defense`), anomaly detection, distributed backups (Google Drive + S3 +
  GitHub), continuous learning loop.

Full plan: see the project's plan file, or ask the agent to summarize current
status against `TaskList`.
