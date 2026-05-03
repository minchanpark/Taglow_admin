# dev Agent Instructions

## Scope

These instructions apply to `dev/**` documentation and setup files.

## Responsibility

`dev` is the source-of-truth area for product scope, technical design, API snapshots, and operational setup notes.

## Rules

- Keep PRD and TDD aligned when product scope or architecture changes.
- Record environment constants as non-secret values only.
- Use `https://taglow-player.web.app` as the current StandbyMe player base URL unless the user explicitly changes it.
- Keep API endpoint assumptions clearly marked when backend support is not confirmed.
- Do not place tool-specific workflow instructions here unless the document is explicitly a setup guide for that tool.

## Warnings

- Do not treat example Dart snippets in docs as generated source.
- Do not document admin passwords, AWS access keys, session cookies, or private tokens.
- Do not widen MVP scope without updating both PRD and TDD.
