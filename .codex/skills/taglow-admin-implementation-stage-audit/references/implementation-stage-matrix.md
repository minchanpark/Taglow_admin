# Taglow Admin Implementation Stage Matrix

## Phase Bands

- Phase 0: docs, AGENTS, skills, Flutter scaffold.
- Phase 1: domain models, routes, theme, mock service provider.
- Phase 2: mock admin flow for login, votes, questions.
- Phase 3: participant link, QR export, player link, diagnostics.
- Phase 4: OpenAPI/gateway/mapper real backend integration.
- Phase 5: S3 or presigned upload and operation verification.

## Status Rubric

- Complete: implemented and verified by tests/analyze or clear runnable evidence.
- Substantially implemented: main path works; secondary states/tests incomplete.
- Partial: meaningful pieces exist but no end-to-end flow.
- Scaffolded: files/routes/classes exist with placeholders.
- Missing: no evidence.
- Blocked/Unknown: cannot verify from docs, code, or commands.

## MVP Ready Gate

- ADMIN auth enforced.
- Vote/question CRUD works.
- Question image upload persists URL/ratio.
- Public display/questions verification works.
- Participant link and QR are usable.
- Player link opens `/display/{voteId}`.
- Generated/API/storage/browser boundaries are intact.
- Core tests and analyze pass.
