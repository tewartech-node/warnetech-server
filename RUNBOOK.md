# warnetech-server — Failure & Recovery Runbook

Procedures for when something goes wrong, sorted into **predictable** failures
(things that will eventually happen in the normal course of running this
system) and **unpredictable** ones (rarer, harder-to-anticipate incidents).
Each entry gives: how you'd notice, what to do, and how to prevent recurrence.

Pair this with `RESOURCE_INVENTORY.md` for exact resource names/IDs, and
`schema/RESTORE.md` for the database-specific restore steps.

---

## Predictable failures

### 1. D1 database wiped, corrupted, or schema drifted
**Notice:** API calls return SQL errors ("no such table"); `/api/history` or
`/api/memories` return empty when they shouldn't.
**Fix:**
1. Confirm scope: `d1_database_query` a `SELECT name FROM sqlite_master WHERE type='table'` against `warnetech-server-data` to see what tables actually exist.
2. Reapply `schema/001_initial_schema.sql` from this repo (idempotent — uses `CREATE TABLE IF NOT EXISTS`).
3. If data itself is gone (not just schema), restore from the most recent backup once Phase 3 backups exist (Google Drive / S3 / GitHub — see `RESOURCE_INVENTORY.md` §4 for current status). Before Phase 3 ships, **there is no automated backup** — this is a known gap.
**Prevent:** Prioritize Phase 3's distributed backup system; until then, periodically export the DB manually (`wrangler d1 export warnetech-server-data`).

### 2. Worker deploy fails or ships a regression
**Notice:** `npm run deploy` errors, or `npx wrangler tail` shows a spike in 500s after a deploy.
**Fix:**
1. `npx wrangler tail` to see the live error.
2. Roll back by redeploying the last known-good commit: `git checkout <last-good-sha> -- . && npm run deploy` (or use the Cloudflare dashboard's deployment rollback if available).
3. Fix forward on a branch, verify with `npm run check` locally before redeploying.
**Prevent:** Always run `npm run check` before deploying; treat it as a hard gate even though CI doesn't enforce it (`.github/workflows/deploy.yml` has no test/lint gate today).

### 3. A connector's credentials expire or are revoked
**Notice:** `POST /api/connectors/<name>/execute` starts returning `"not authenticated"` or a 401/403 from the underlying API.
**Fix:**
1. Check `GET /api/connectors/status` to confirm which connector dropped.
2. Re-authenticate: `POST /api/connectors/auth` with fresh credentials for that connector.
   - GitHub: mint a new PAT.
   - Google Drive: the refresh token itself may have been revoked (e.g. user removed app access in Google account settings) — redo the OAuth consent flow to get a new refresh token.
   - AWS: rotate the IAM access key in the AWS console, then re-auth with the new pair.
**Prevent:** None of this is currently monitored proactively — Phase 2/3 anomaly detection should eventually alert on repeated connector auth failures instead of finding out from a failed task.

### 4. Rate limit exhausted (legitimate high traffic or a runaway loop)
**Notice:** `429 rate_limited` responses from `/api/connectors/<name>/execute`.
**Fix:** Wait for the 1-minute window to roll over (limit is 10 calls/min per connector, enforced via the `RATELIMIT` KV namespace — see `src/index.ts`). If it's a genuine runaway loop (e.g. Phase 2 agent stuck retrying), stop whatever is issuing the calls before the window resets, not after — otherwise it just re-triggers the limit.
**Prevent:** Once Phase 2's guardrails and kill switch exist, use them to halt agent execution rather than waiting out rate limits.

### 5. Full account reset happens again (accidental or intentional)
**Notice:** Cloudflare dashboard shows the Worker/D1/KV/R2 resources missing; deploys fail with "not found."
**Fix:** This exact scenario already happened once (2026-08-01) — this runbook and `RESOURCE_INVENTORY.md` exist because of it. To rebuild:
1. Recreate D1 (`warnetech-server-data`), KV namespaces (`warnetech-server-sessions`, `-ratelimit`, `-vault`), and the R2 bucket (`warnetech-server-backup`) using the same names.
2. Update the new IDs into `wrangler.jsonc` (D1 `database_id`, KV `id`s) — they will differ from the ones recorded in `RESOURCE_INVENTORY.md`, since IDs aren't preserved across recreation.
3. Reapply `schema/001_initial_schema.sql`.
4. Re-set the `VAULT_ENCRYPTION_KEY` secret (a new one is fine — it just means previously-vaulted credentials, which are gone anyway, don't need to decrypt).
5. Re-authenticate every connector from scratch.
6. Deploy from the `llm-chat-app-template` repo's latest `main`.
**Prevent:** Nothing prevents a deliberate reset — it's a manual account action. The mitigation is that this repo makes rebuilding fast and repeatable instead of starting from memory.

---

## Unpredictable failures

### 6. Cloudflare account suspension or billing issue
**Notice:** Dashboard access blocked, or API calls start returning auth/billing errors unrelated to any code change.
**Fix:** Check the Cloudflare account status page and billing settings directly (not through the Worker, which will be down). Contact Cloudflare support if suspension seems erroneous. There is no automated fallback host for this app today — it is single-provider.
**Prevent:** Keep billing current; consider whether a secondary deploy target is worth the complexity once the system is business-critical (not scoped in the current plan).

### 7. Vault encryption key compromised or lost
**Notice (compromised):** Evidence of unauthorized connector activity in `connector_audit_log` that you didn't trigger.
**Notice (lost):** `VAULT_ENCRYPTION_KEY` secret value is gone (e.g. accidentally overwritten) — `getCredential()` in `src/vault.ts` will start returning `null` for everything instead of throwing, so this can look identical to "no connector was ever authenticated."
**Fix:**
1. Rotate: `wrangler secret put VAULT_ENCRYPTION_KEY` with a newly generated value.
2. Every existing vault entry becomes permanently undecryptable the moment the key changes (by design — `vault.ts` degrades gracefully on decrypt failure rather than throwing). Re-authenticate all connectors from scratch afterward.
3. If compromise (not just loss) is suspected, treat every credential that was in the vault as burned: rotate the underlying GitHub PAT, Google OAuth app, and AWS IAM keys themselves, not just the vault encryption key.
**Prevent:** Nothing stores the encryption key outside the Worker secret — that's intentional (a KV-only compromise shouldn't expose it), but it means there's no recovery path if the secret itself is lost. Consider recording it in a password manager at creation time, outside this repo.

### 8. GitHub org access revoked or PAT scope changed underneath you
**Notice:** GitHub connector calls fail; since the `shell` connector piggybacks on the same token, it fails too, silently taking down "CLI execution" along with GitHub actions.
**Fix:** Check the PAT's scope/expiry directly on GitHub. Re-issue and re-authenticate via `/api/connectors/auth`.
**Prevent:** None currently — this is a good candidate for the anomaly detection work in Phase 3 (alert on N consecutive auth failures from the same connector).

### 9. Malicious or misleading content reaches the agent through a connector
**Notice:** Agent takes an action that doesn't match what was asked — e.g. a file fetched via the GitHub or Google Drive connector contains instructions the agent then follows.
**Fix:** This is a prompt-injection-via-tool-output risk. Once Phase 2 guardrails exist, any destructive or credential-touching action should require explicit confirmation regardless of what a connector's *data* says to do — data from connectors must never be treated as instructions with the same authority as the actual user/task. Review `agent_actions` audit log to see exactly what triggered the anomalous action and add a guardrail rule for that pattern.
**Prevent:** Build guardrails (Phase 2, task #12) before granting the agent any connector with write/execute power over untrusted content sources.

### 10. Something genuinely novel
**Fix (general incident checklist):**
1. `npx wrangler tail` for live logs.
2. Check `connector_audit_log` (and, once built, `agent_actions`) in D1 for what actually ran.
3. If it's actively harmful, the fastest kill switch today is removing the `routes` entry from `wrangler.jsonc` and redeploying (takes the custom domain offline) — there is no dedicated agent kill switch until Phase 2 builds one.
4. Document what happened as a new entry in this runbook once resolved, so it moves from "unpredictable" to "predictable."
