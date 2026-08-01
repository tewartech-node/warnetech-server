# Restoring warnetech-server-data

Two scenarios: the **database exists but the schema is missing/wrong**, or
the **database itself is gone** (e.g. after an account reset). Both end at
the same schema-apply step.

## Scenario A — database exists, schema missing or drifted

Apply the schema directly (idempotent, safe to re-run):

```bash
npx wrangler d1 execute warnetech-server-data --remote --file=schema/001_initial_schema.sql
```

Verify:

```bash
npx wrangler d1 execute warnetech-server-data --remote \
  --command="SELECT name FROM sqlite_master WHERE type='table'"
```

You should see: `users`, `messages`, `memories`, `shared_knowledge`,
`connector_audit_log`.

## Scenario B — database itself is gone

1. Recreate it:
   ```bash
   npx wrangler d1 create warnetech-server-data
   ```
   This prints a new `database_id` — it will **not** match the one recorded
   in `RESOURCE_INVENTORY.md` (`f347b59b-bf32-451c-ae81-2c87182ee364`), since
   IDs aren't preserved across recreation.
2. Update `wrangler.jsonc` in `llm-chat-app-template` with the new
   `database_id` under `d1_databases`.
3. Apply the schema (Scenario A, step 1).
4. Redeploy the Worker so it picks up the new binding: `npm run deploy`.
5. If prior data needs restoring (not just the empty schema), pull it from
   the most recent backup — see `RESOURCE_INVENTORY.md` §4 for backup status.
   Until Phase 3 ships automated backups, this step has no automated source;
   check for a manual `wrangler d1 export` dump if one was taken.

## Restoring from a manual export (if one exists)

```bash
# Taking a backup (do this periodically until Phase 3 automates it):
npx wrangler d1 export warnetech-server-data --remote --output=backup-$(date +%Y%m%d).sql

# Restoring from one:
npx wrangler d1 execute warnetech-server-data --remote --file=backup-YYYYMMDD.sql
```

## What's NOT covered here

- KV namespaces (`warnetech-server-sessions`, `-ratelimit`, `-vault`) have no
  export/restore tooling in D1 terms — they're key-value, not relational.
  `-vault` in particular can't be meaningfully "restored" if lost, since its
  contents are encrypted with a key that lives only in the `VAULT_ENCRYPTION_KEY`
  Worker secret — see `RUNBOOK.md` §7.
- R2 bucket (`warnetech-server-backup`) restoration depends on Phase 3's
  backup system, not yet built.
