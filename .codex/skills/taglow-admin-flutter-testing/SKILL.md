---
name: taglow-admin-flutter-testing
description: Design, add, run, or triage Taglow admin Flutter tests. Use for unit tests, widget tests, integration checks, Riverpod controller tests, mock service tests, API gateway/mapper tests, URL builder tests, QR export tests, image upload tests, diagnostics tests, or deciding test strategy for admin vote/question/link/player flows.
---

# Taglow Admin Flutter Testing

## Start

1. Read `AGENTS.md`, nearest `lib/**/AGENTS.md`, nearest `test/**/AGENTS.md`, and the TDD testing section.
2. Choose the narrowest test that protects the behavior being changed.
3. Prefer fake services and adapters over real backend, S3, clipboard, downloads, or browser launch.

## Parallel Subagent Workflow

Use subagents only when the current user request explicitly asks for subagents, parallel agents, or delegated execution. For broad test work that covers multiple layers or a full MVP flow:

1. Keep the main agent responsible for test strategy, shared fixtures/fakes, final suite runs, and failure triage.
2. Use explorer subagents for read-only inventory of current coverage, skipped scenarios, and existing failing tests.
3. Use worker subagents only with disjoint write scopes, such as unit/service tests, controller tests, widget tests, and integration-oriented checks.
4. Tell every worker they are not alone in the codebase, must not revert edits made by others, and must not weaken auth, upload, QR, player, generated-code boundary, or security coverage.
5. Require each worker to report changed paths, scenarios covered, commands run, and remaining failures.

## Test Strategy

- Unit tests: domain models, validators, `AdminUrlBuilder`, `ImageRatioReader`, mapper aliases, upload result values.
- Service tests: `AdminApiGateway`, `AdminPayloadMapper`, `MockAdminService`, `OpenApiAdminService`, QR export, external link fallback.
- Controller tests: auth, vote list/detail, question editor, operation links, upload/save failure separation.
- Widget tests: login, vote list/detail states, operation link panel, QR preview/download affordance, question editor, diagnostics.
- Integration checks: login to vote detail to question save to public preview to participant/player link generation.

## Required Coverage

- Non-admin users cannot enter admin routes.
- `imageUrl` and `imageRatio` are required before saving a question.
- S3 success + API failure leaves upload result available for retry.
- Participant URL and player URL handle trailing slash base URLs.
- QR payload never includes admin, token, session, internal API, or AWS values.
- Player open failure falls back to copyable URL.
- Generated code is not imported from View or Controller.

## Triage Rules

- Preserve the first failing assertion and shortest reproduction.
- Fix behavior first; update tests only if documented behavior changed.
- Do not reduce coverage around auth, upload, QR, player, generated-code boundaries, or security to make tests pass.

## Reference

Read `references/testing-matrix.md` for test placement and scenario details.
