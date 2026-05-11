---
name: taglow-admin-debug-harness
description: Diagnose and repair Taglow admin Flutter runtime, route, layout, state, API, upload, QR export, player-link, CORS, auth, or browser-specific bugs using an evidence-first debug loop. Use when debugging needs logs, focused tests, screenshots, Chrome/Flutter DevTools, network inspection, diagnostic artifacts, or repeated verification.
---

# Taglow Admin Debug Harness

## Principle

Do not guess from code alone. Reproduce, collect evidence, identify the owning layer, patch narrowly, and verify the same reproduction.

## Parallel Subagent Workflow

Use subagents only when the current user request explicitly asks for subagents, parallel agents, or delegated execution. For broad bugs that span multiple independent failure types or evidence sources:

1. Keep the main agent responsible for the canonical reproduction, root-cause decision, patch ownership, and final verification.
2. Use explorer subagents for read-only evidence collection such as logs, screenshots, network summaries, provider state traces, or focused failing-test summaries.
3. Use worker subagents for fixes only after the owning layer is clear and write scopes are disjoint.
4. Tell every worker they are not alone in the codebase, must not revert edits made by others, and must preserve the original reproduction.
5. Require each subagent to report evidence captured, suspected owner layer, changed paths if any, and verification performed.

## Debug Loop

1. Classify the failure: UI/layout, controller state, route, API/auth, upload, QR/export, player launch, diagnostics, performance, or web-only.
2. Reproduce with the smallest command or manual flow.
3. Capture concise evidence in `.ai_debug/reports/` when the scaffold exists.
4. Read the nearest `AGENTS.md` files before editing.
5. Patch one narrow cause in the owning layer.
6. Re-run the same reproduction plus relevant tests/analyze.
7. If still failing, record what changed and what evidence ruled out.

## Evidence By Failure Type

- UI/layout: widget tree, viewport, overflow logs, screenshots.
- Controller state: provider state transitions, route params, validation, retries.
- API/auth: gateway call, mapper input/output, Dio status, cookies, CORS, CSRF.
- Upload: file type/size, ratio calculation, S3/presigned response, public URL reachability.
- QR/export: payload, canvas/render result, filename, download fallback.
- Player: built URL, browser launch result, `/display/{voteId}` route response.

## Stop Condition

Finish only after the original reproduction is verified or a clear blocker and next diagnostic step are documented.

## Reference

Read `references/debug-harness.md` for artifact names and deeper checks.
