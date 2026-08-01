# Connector Reference

What each connector in `llm-chat-app-template/src/connectors/` can do, for
the agent (or a human) deciding which connector/action to call. Source of
truth is the code itself — this file is a lookup aid, not a spec; if it
drifts from `src/connectors/*.ts`, the code wins.

All calls go through `POST /api/connectors/:name/execute` with body
`{ "action": "...", "params": { ... } }`. Rate limit: 10 calls/min per
connector. Every call is written to `connector_audit_log`.

## github

| Action | Required params | Notes |
|---|---|---|
| `listRepos` | `org` | Returns name/full_name/private for up to 50 repos |
| `getFileContent` | `owner, repo, path` | Optional `ref`. Fails if path isn't a file |
| `updateFile` | `owner, repo, path, content, message` | Optional `branch`, `sha` (auto-looked-up if omitted) |
| `createPR` | `owner, repo, title, head, base` | Optional `body` |
| `triggerWorkflow` | `owner, repo, workflowId, ref` | Optional `inputs` (object). Fire-and-forget `workflow_dispatch` |

Auth: PAT with repo scope, stored via `/api/connectors/auth`.

## google-drive

| Action | Required params | Notes |
|---|---|---|
| `createFolder` | `name` | Optional `parentId` |
| `uploadFile` | `name, content, mimeType` | Optional `parentId`. Multipart upload |
| `listFiles` | — | Optional `query` (Drive search syntax) |
| `downloadFile` | `fileId` | Returns text content |
| `deleteFile` | `fileId` | **Destructive** — requires `params.confirmed = true` |
| `getFileMetadata` | `fileId` | |

Auth: OAuth `clientId` + `clientSecret` + `refreshToken`. Access tokens are
refreshed automatically and cached in the vault until near expiry.

## aws

| Action | Required params | Notes |
|---|---|---|
| `s3.uploadObject` | `bucket, key, content` | |
| `s3.getObject` | `bucket, key` | |
| `s3.listObjects` | `bucket` | Optional `prefix`. Returns raw XML |
| `s3.deleteObject` | `bucket, key` | **Destructive** — requires `params.confirmed = true` |
| `s3.copyObject` | `sourceBucket, sourceKey, destBucket, destKey` | |
| `lambda.invoke` | `functionName` | Optional `payload`, `async` (bool → Event vs RequestResponse) |
| `logs.getLogEvents` | `logGroup, logStream` | Optional `limit` (default 50) |
| `logs.createLogStream` | `logGroup, logStream` | |

Auth: IAM `accessKeyId` + `secretAccessKey` + `region`. Signed with SigV4 via
`aws4fetch` (no AWS SDK — Workers-native).

## shell

| Action | Required params | Notes |
|---|---|---|
| `run` | `owner, repo, workflowId, ref, command` | **Not a real shell** — see below |

Cloudflare Workers have no filesystem or subprocess access. This connector
validates `command` against an allow-list (must start with `ls`, `curl`,
`git status`, `git log`, `git diff`, `cat`, `find`, or `grep`; rejects
chaining characters `; & | \`` and `$(`), then dispatches it to a GitHub
Actions workflow via the `github` connector's `triggerWorkflow`. The target
repo's workflow must itself accept a `command` input and actually run it —
this connector only gatekeeps what gets *dispatched*, not what the runner
does once it's there. The call returns once dispatch succeeds, not once the
command finishes; check the Actions run for output.

Auth: piggybacks on the `github` connector's token — no separate credential.

## d1

| Action | Required params | Notes |
|---|---|---|
| `query` | `sql` | Optional `params` (array of bind values). Read-only intent, but not enforced at the SQL level |
| `execute` | `sql` | Optional `params`. **Destructive statements** (`DROP`/`DELETE`/`TRUNCATE`/`ALTER`) require `params.confirmed = true` |

Auth: none — uses the Worker's native `DB` binding, granted by Cloudflare at
deploy time.

---

## Guardrail note

The `confirmed: true` checks in `d1`, `google-drive`, and `aws.s3.deleteObject`
are a first line of defense, not the primary enforcement point. Phase 2's
`agent/guardrails.ts` is where "never delete without confirmation" gets
enforced at the agent-decision layer, before a connector call is even
attempted — see `RUNBOOK.md` §9 for why that matters.
