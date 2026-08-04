# Deployment Status — Prisma Postgres + AI Chat (Gemini)

**Last updated:** 2026-08-04
**Repo/branch:** `warnetech-server` @ `claude/cloudflare-warp-connector-8n9jl6`

This consolidates everything set up across the Prisma + AI chat work into one
checklist.

---

## ✅ Done and verified

- **App code**: Next.js 16 + Prisma 7 (`User`/`Post` schema, `PrismaPg`
  adapter, seed script, `scripts/verify-prisma.ts`), plus
  `src/app/api/chat/route.ts` using `streamText` from the `ai` package.
- **Build correctness**: `prisma.config.ts` no longer hard-crashes when
  `DATABASE_URL` is unset (`postinstall: prisma generate` + `next build` both
  verified locally with the var completely absent — matches a fresh Vercel
  build with no env vars configured).
- **AI provider: Google Gemini, not Vercel AI Gateway.** Vercel AI Gateway
  requires a funded credit card on the team (confirmed via
  `GatewayInternalServerError: AI Gateway requires a valid credit card on
  file` in runtime logs on both projects) — not available, so we switched
  providers instead of waiting on that. `@ai-sdk/google` + a free, no-card
  Google AI Studio API key work end-to-end.
  - Model: `gemini-flash-latest` — a Google-maintained alias for their
    current recommended flash model. Deliberately not pinned to a dated
    version: `gemini-2.5-flash` is still listed in the models API but
    returns `404 no longer available to new users` for freshly created
    keys, which is exactly the kind of breakage the `-latest` alias avoids.
  - **Verified locally, twice**: the standalone `index.mjs` script and the
    actual `src/app/api/chat/route.ts` handler (via local `next dev`) both
    returned real streamed Gemini text.
    `generativelanguage.googleapis.com` is reachable from this sandbox,
    unlike every Prisma/Vercel/Cloudflare domain touched earlier in this
    project — this is the one integration that could be fully verified
    without deploying anywhere first.
- **CI workflow**: `.github/workflows/prisma-migrate.yml` — manual-dispatch,
  runs `prisma generate` → `migrate deploy` → `db seed` → `verify-prisma.ts`
  on GitHub's unrestricted runners (this sandbox blocks Postgres port 5432
  and all Prisma platform domains outright, so migrations can't run from
  here — see commit history on this branch for the full diagnosis).
- **Two live deployments** (built successfully, but predate the Gemini
  switch — see below):
  - `https://warnetech-my-app.vercel.app` — ad-hoc test project
  - `https://warnetech-server-vercel.vercel.app` — the git-linked project

---

## ⏳ Needs a manual step (nothing further I can automate)

### 1. Add `GOOGLE_GENERATIVE_AI_API_KEY` to both Vercel projects
**Blocks:** the live deployments actually returning chat responses — they're
still running the pre-Gemini build and, even after redeploying with the new
code, have no API key available at runtime. No tool exists to set Vercel
project env vars (same gap noted for `DATABASE_URL` earlier).
**Fix:** for each project (`warnetech-my-app` and `warnetech-server-vercel`)
→ Settings → Environment Variables → add `GOOGLE_GENERATIVE_AI_API_KEY` with
your AI Studio key → redeploy (push a commit, or Redeploy from the dashboard).

### 2. Fix `warnetech-server-vercel` project settings
**Blocks:** every *future* `git push` from deploying correctly. The project's
stored Framework Preset is `"container"` with no Root Directory, so
git-triggered builds clone the repo and no-op in ~20ms. The one working
deployment on this project so far only succeeded because explicit overrides
were passed through a direct file-upload deploy — those overrides don't
persist to the project.
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

## No longer applicable

**Adding a Vercel team credit card** — was step 1 in the previous version of
this doc, now moot. The Gemini swap avoids AI Gateway's billing requirement
entirely; nothing here depends on the team having a card on file.

## Optional cleanup

`warnetech-my-app` (the first, ad-hoc test project) is redundant —
`warnetech-server-vercel` is the real, git-linked one. No delete-project tool
is available to me; remove it manually from the Vercel dashboard if you want
it gone, or leave it as a working reference deployment.

---

## Why these three specifically can't be automated further

| Step | Why no tool can do it |
|---|---|
| Set project env var | No env-var-management tool exposed (only deployment protection: password/SSO/trusted IPs) |
| Fix Framework Preset / Root Directory | Same — no general project-settings-update tool |
| Add repo secret | GitHub secrets are write-only even to admins — no tool can set or read them back |

Once all three are done, the full path — push → build → live Gemini chat
responses, plus one manual migration run — is complete and needs no further
one-off fixes.
