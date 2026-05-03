---
name: taglow-admin-agent-guidelines-sync
description: Maintain Taglow admin AGENTS.md files and project-local Codex skills. Use when PRD/TDD changes, lib or test directory responsibilities change, new directories are added, generated/API/upload/link boundaries move, skill instructions need updates, or general agent instructions must stay tool-agnostic and aligned with the admin architecture.
---

# Taglow Admin Agent Guidelines Sync

## Start

1. Read root `AGENTS.md`, affected child `AGENTS.md`, `dev/Taglow_admin_PRD.md`, and `dev/Taglow_admin_TDD.md`.
2. Keep general `AGENTS.md` files tool-agnostic.
3. Put detailed responsibility and forbidden-dependency rules in the closest child `AGENTS.md`.
4. Put Codex-specific repeatable workflows in `.codex/skills/taglow-admin-*`.

## Update Workflow

1. Identify what changed: product scope, architecture, directory structure, API contract, auth/security, upload, QR/player, testing, debugging, or tooling.
2. Update the smallest instruction surface future agents need.
3. Add an `AGENTS.md` for each new meaningful `lib` or `test` directory.
4. If a repeatable Codex workflow emerges, create or update a project-local skill instead of bloating root instructions.
5. Validate root, child instructions, PRD, TDD, and skills do not contradict each other.

## Skill Rules

- Use lowercase hyphenated names with `taglow-admin-` prefix.
- Keep project-local skills under `.codex/skills` because this repository uses that convention.
- Put trigger conditions in frontmatter `description`.
- Keep `SKILL.md` concise and move long checklists to `references/`.
- Add scripts only for deterministic repeated commands.
- Run `quick_validate.py` after skill edits.

## AGENTS Rules

- Do not add `$skill` syntax to AGENTS files.
- Do not require non-Codex agents to read `.codex/skills`.
- Keep AGENTS files in English.
- Root AGENTS should contain only durable invariants and the directory guide.

## Reference

Read `references/guideline-sync-checklist.md` for sync surfaces and validation.
