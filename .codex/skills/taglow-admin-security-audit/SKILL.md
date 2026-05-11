---
name: taglow-admin-security-audit
description: Audit Taglow admin Flutter Web security and privacy risks. Use when reviewing admin auth, ADMIN role checks, session/cookie/token handling, CSRF/CORS, browser storage, S3 direct upload, presigned URLs, QR payloads, player links, generated clients, diagnostics output, deployment headers, or security-sensitive admin changes.
---

# Taglow Admin Security Audit

## Start

1. Read `AGENTS.md`, `lib/api/service/AGENTS.md`, `lib/utils/AGENTS.md`, and affected view/controller AGENTS files.
2. Classify the touched data: credential, admin session, vote/question content, image upload, public URL, QR payload, player URL, generated DTO, or diagnostic output.
3. Treat frontend checks as UX and defense-in-depth; require backend support for real authorization and upload policy.

## Parallel Subagent Workflow

Use subagents only when the current user request explicitly asks for subagents, parallel agents, or delegated execution. For broad security audits across auth, upload, links, diagnostics, and generated-code boundaries:

1. Keep the main agent responsible for threat classification, severity ranking, final remediation choices, and secret-safe reporting.
2. Use explorer subagents for read-only slices such as auth/session/CSRF/CORS, upload/presigned URL handling, QR/player payloads, diagnostics output, and View/Controller generated-code boundaries.
3. Use worker subagents for fixes only when write scopes are disjoint and the security owner layer is clear.
4. Tell every worker they are not alone in the codebase, must not revert edits made by others, and must never print, persist, or add secrets, tokens, cookies, AWS keys, or signed URLs.
5. Require each subagent to report evidence, affected data class, changed paths if any, tests or searches run, and unresolved backend dependencies.

## Audit Areas

- Auth: ADMIN role enforcement, route guard, logout, session/cookie/token handling.
- CSRF/CORS: credentialed requests, allowed origins, state-changing methods.
- Upload: no long-lived AWS keys, safe prefix policy, presigned URL exposure, content type and size UX.
- QR: participant URL only; no admin URL, token, session, internal API, AWS, or signed URL.
- Player: public display URL only; no secret query params.
- Diagnostics: show non-secret config only; hide signed URLs, cookies, tokens, stack traces.
- Generated clients: no imports in View/Controller; no manual edits.

## Red Lines

- No admin password, token, AWS key, session ID, or signed upload URL in local storage.
- No privileged server secret in Flutter Web.
- No generated DTO exposure in UI copy or controller state.
- No public vote creation endpoint for admin creation unless explicitly protected by backend.

## Reference

Read `references/security-checklist.md` for the detailed audit checklist.
