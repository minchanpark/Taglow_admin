# Taglow Admin Guideline Sync Checklist

## Root AGENTS

- Purpose and source-of-truth docs are current.
- Product and architecture invariants match PRD/TDD.
- Directory guide matches real directories.
- No tool-specific `$skill` instructions.

## Child AGENTS

- Each meaningful `lib` directory has responsibility and forbidden dependencies.
- Each meaningful `test` directory has test ownership and live-service warnings.
- Generated code directories clearly forbid manual edits.
- View/controller/service/model/utils/theme boundaries do not conflict.

## Skills

- Skill names use `taglow-admin-` prefix.
- Frontmatter has only `name` and `description`.
- Description includes trigger scenarios.
- Long checklists live in `references/`.
- `agents/openai.yaml` default prompt includes `$skill-name`.
- `quick_validate.py` passes.
