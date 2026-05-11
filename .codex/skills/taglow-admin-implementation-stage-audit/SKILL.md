---
name: taglow-admin-implementation-stage-audit
description: Analyze Taglow admin implementation stage against PRD, TDD, AGENTS.md, project-local skills, code, and tests, then update docs or instructions when requested. Use when estimating MVP progress, phase completion, readiness, implementation gaps, risks, next work, or syncing admin documentation and directory-level agent guidance.
---

# Taglow Admin Implementation Stage Audit

## Start

1. Read root `AGENTS.md`, `dev/Taglow_admin_PRD.md`, and `dev/Taglow_admin_TDD.md`.
2. Before judging a code area, read every applicable `AGENTS.md` from root to that subtree.
3. Inventory the repo with `rg --files` for `lib`, `test`, `web`, `pubspec.yaml`, `dev`, `.codex/skills`, and generated API locations.
4. Treat PRD/TDD/AGENTS/skills as source of truth and code/tests as evidence.
5. Default to read-only analysis unless the user asks to update docs or instructions.

## Parallel Subagent Workflow

Use subagents only when the current user request explicitly asks for subagents, parallel agents, or delegated execution. For repo-wide stage audits or MVP readiness reviews:

1. Keep the main agent responsible for the requirement matrix, final verdict, confidence level, risk ranking, and any documentation-sync edits.
2. Use explorer subagents for read-only slices such as product-flow evidence, architecture-boundary evidence, test/analyze evidence, and docs/skills drift.
3. Use worker subagents only in audit + documentation sync mode and only with disjoint write scopes such as PRD/TDD, child `AGENTS.md`, or project-local skills.
4. Tell every worker they are not alone in the codebase, must not revert edits made by others, and must keep claims evidence-backed.
5. Require each subagent to report checked files, evidence found, missing requirements, commands run, and unresolved blockers.

## Modes

- **Audit only**: analyze implementation stage, risks, and next work without edits.
- **Audit + documentation sync**: analyze first, then update PRD/TDD/AGENTS/skills to remove drift.
- **Instruction sync only**: update the smallest instruction surfaces needed when the user already supplied the audit result.

## Audit Workflow

1. Build a requirement matrix from `references/implementation-stage-matrix.md`.
2. Map TDD structure to actual files and flag missing or renamed layers.
3. Check dependency boundaries: View -> Controller -> Service -> Gateway/Mapper -> Generated/Dio/Storage/Browser.
4. Assess product flows: login, vote list, vote detail, question editor, image upload, participant QR, player link, diagnostics.
5. Assess technical phases from scaffold through mock, links/QR/player, OpenAPI, upload, and operations verification.
6. Run read-only verification when feasible: `flutter analyze`, relevant `flutter test`, and boundary searches.
7. Keep only evidence-backed claims in the final synthesis.

## Documentation Sync

1. Update PRD/TDD source-of-truth sections first.
2. Update root `AGENTS.md` only for durable invariants and directory guide changes.
3. Update child `AGENTS.md` files for local ownership and forbidden dependencies.
4. Update project-local skills when a repeatable Codex workflow changes.
5. Keep unresolved questions as open issues, not hidden assumptions.

## Output

Lead with an implementation-stage verdict and confidence level. Include phase map, requirement matrix, boundary/security risks, verification, next work, and files changed.

## Reference

Read `references/implementation-stage-matrix.md` for rubric and checklist.
