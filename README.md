# warnetech-server

Infrastructure knowledge base for the **warnetech-server** AI system — the
autonomous, connector-integrated Cloudflare Worker built out of
[`tewartech-node/llm-chat-app-template`](https://github.com/tewartech-node/llm-chat-app-template).

This repo doesn't contain application code. It exists so the agent (and any
human operator) has a stable place to pull infrastructure facts from,
independent of the app repo's history — schema, restore steps, account
inventory, and a runbook for when things break.

## Contents

- **`RESOURCE_INVENTORY.md`** — every Cloudflare/GitHub/third-party resource
  behind this system: current names, IDs, what changed in the 2026-08-01
  account reset, and what's authenticated vs. not.
- **`RUNBOOK.md`** — failure and recovery procedures, split into predictable
  (D1 wiped, deploy regression, credential expiry, rate limits) and
  unpredictable (account suspension, vault key loss, prompt injection via
  connector data) scenarios.
- **`schema/001_initial_schema.sql`** — the full D1 schema for
  `warnetech-server-data`. Idempotent, safe to re-run.
- **`schema/RESTORE.md`** — step-by-step database restore procedure for both
  "schema missing" and "database itself is gone" cases.
- **`connectors/CONNECTOR_REFERENCE.md`** — every connector action, its
  required params, and auth method, for whoever (or whatever) is deciding
  what call to make next.

## Related repos

- `llm-chat-app-template` — the actual Worker source code
- `AI-Defense` — source of the adaptive firewall Phase 3 ports in
- `AI-Firewall-Pentest-Trial`, `FIREWALL_SUMMERY`, `sql-anomaly-detection-repo` — adjacent security material

See `RESOURCE_INVENTORY.md` §2 for the full repo list and what each is for.
