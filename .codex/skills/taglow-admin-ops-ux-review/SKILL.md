---
name: taglow-admin-ops-ux-review
description: Review Taglow admin operations UX against the PRD. Use for admin screen reviews, Flutter widget reviews, desktop/tablet workflow checks, vote/question creation ergonomics, image upload feedback, participant QR readiness, player link verification, diagnostics clarity, accessibility, text overflow, or operator error-state reviews.
---

# Taglow Admin Ops UX Review

## Start

1. Read the relevant PRD screen section and nearest `lib/view/**/AGENTS.md`.
2. Review the real operator path: login, vote list, vote detail, question editor, upload, operation links, QR download, player open, diagnostics.
3. Treat field-operation readiness as a product constraint.

## Parallel Subagent Workflow

Use subagents only when the current user request explicitly asks for subagents, parallel agents, or delegated execution. For broad multi-screen operator UX reviews:

1. Keep the main agent responsible for severity ranking, PRD alignment, final findings, and any coordinated fix plan.
2. Use explorer subagents for read-only screen slices such as auth, vote list/detail, question editor/upload, operation links/QR/player, and diagnostics.
3. Use worker subagents for UX fixes only when the user asks for implementation and write scopes are disjoint by view subtree.
4. Tell every worker they are not alone in the codebase, must not revert edits made by others, and must preserve operator-critical loading, error, fallback, and accessibility states.
5. Require each subagent to report files reviewed or changed, screenshots or commands used when available, severity calls, and unresolved UX risks.

## Review Checklist

- Operator can create a vote and question without developer help.
- Required inputs and validation are visible before save.
- Upload progress, upload failure, API save failure, and retry are distinct.
- Participant URL, QR preview/download, and player URL are easy to find after save.
- QR preview is large enough for field confidence and has copy/export fallback.
- Player link opens `/display/{voteId}` and fallback copy is available.
- Vote status `PROGRESS` and `END` are clear and hard to misclick.
- Diagnostics distinguish API, auth, CORS, S3, URL, QR, and player route issues.
- Text fits in buttons, panels, tables, dialogs, and link rows.

## Output

Lead with findings by severity. Cite files and lines when code exists. Distinguish product violations from polish suggestions.

## Reference

Read `references/ops-ux-checklist.md` for screen-by-screen criteria.
