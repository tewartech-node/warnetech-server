# Deployment Status — Prisma Postgres + AI Gateway

**Last updated:** 2026-08-03
**Repo/branch:** `warnetech-server` @ `claude/cloudflare-warp-connector-8n9jl6`

This consolidates everything set up across the Prisma + AI Gateway work into one
checklist. Three things are done and verified end-to-end; three things need a
manual action in the Vercel/GitHub dashboards that no available tool can do
from here (payment info, repo secrets, and one project setting all require a
human in the loop by design).

---

## ✅ Done and verified

- **App code**: Next.js 16 + Prisma 7 (`User`/`Post` schema, `PrismaPg`
  adapter, seed script, `scripts/verify-prisma.ts`), plus `src/app/api/ai-gateway/route.ts`
  using `streamText` with `model: "openai/gpt-5.5"`.
- **Build correctness**: `prisma.config.ts` no longer hard-crashes when
  `DATABASE_URL` is unset (`postinstall: prisma generate` + `next build` both
  verified locally with the var completely absent — matches a fresh Vercel
  build with no env vars configured).
- **AI Gateway wiring**: confirmed correct on **two** live Vercel deployments
  (`warnetech-my-app` and `warnetech-server-vercel`) — requests reach Vercel's
  AI Gateway and authenticate automatically via OIDC (no API key, no
  `.env.local`, no local CLI). The only failure is a billing gate (see below),
  not a code or auth problem.
- **Two live deployments**:
  - `https://warnetech-my-app.vercel.app` — ad-hoc test project, READY
  - `https://warnetech-server-vercel.vercel.app` — the git-linked project,
    manually forced to a working build, READY
- **CI workflow**: `.github/workflows/prisma-migrate.yml` — manual-dispatch,
  runs `prisma generate` → `migrate deploy` → `db seed` → `verify-prisma.ts`
  on GitHub's unrestricted runners (this sandbox blocks Postgres port 5432
  and all Prisma platform domains outright, so migrations can't run from
  here — see commit history on this branch for the full diagnosis).

---

## ⏳ Needs a manual step (nothing further I can automate)

### 1. Add a credit card to unlock AI Gateway
**Blocks:** the `/api/ai-gateway` route actually returning text (currently
200 with empty body — confirmed via runtime logs as
`GatewayInternalServerError: AI Gateway requires a valid credit card on file`).
**Fix:** Vercel dashboard → `tewartech-node` team → Settings → Billing → add
a card. Unlocks free credits, not an immediate charge. Applies to both
projects since they share the same team.

### 2. Fix `warnetech-server-vercel` project settings
**Blocks:** every *future* `git push` from deploying correctly. The project's
stored Framework Preset is `"container"` with no Root Directory, so
git-triggered builds clone the repo and no-op in ~20ms. Today's working
deployment only succeeded because I passed explicit overrides through a
direct file-upload deploy — those overrides don't persist to the project.
**Fix:** Vercel dashboard → `warnetech-server-vercel` → Settings → General:
- Root Directory → `app`
- Build & Development Settings → Framework Preset → `Next.js`

### 3. Add the `DATABASE_URL` GitHub Actions secret
**Blocks:** running the actual migration/seed against your real database.
**Fix:** GitHub → `warnetech-server` repo → Settings → Secrets and variables
→ Actions → New repository secret → name `DATABASE_URL`, value the
`postgres://...pooled.db.prisma.io...` connection string. Then Actions tab →
"Prisma Postgres — migrate & seed" → Run workflow.

---

## Optional cleanup

`warnetech-my-app` (the first, ad-hoc test project) is now redundant —
`warnetech-server-vercel` is the real, git-linked one. No delete-project tool
is available to me; remove it manually from the Vercel dashboard if you want
it gone, or leave it as a working reference deployment.

---

## Why these three specifically can't be automated further

| Step | Why no tool can do it |
|---|---|
| Add credit card | Payment info entry — never automatable, by design |
| Fix Framework Preset / Root Directory | No project-settings-update tool exposed beyond deployment protection (password/SSO/trusted IPs) |
| Add repo secret | GitHub secrets are write-only even to admins — no tool can set or read them back |

Once all three are done, the full path — push → build → (manual) migrate/seed
→ live AI Gateway responses — is complete and needs no further one-off fixes.
