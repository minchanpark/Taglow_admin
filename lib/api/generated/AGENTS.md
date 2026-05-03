# generated Agent Instructions

## Responsibility

`lib/api/generated` contains generated OpenAPI client code only.

## Rules

- Do not edit generated files by hand.
- Regenerate from `dev/tagvote-openapi.json` or the configured source spec when contracts change.
- Do not add wrappers, mappers, business logic, or manual patches here.
- Do not expose generated models directly to views or controllers.

## Warnings

- If generated code appears wrong, fix the source schema, generator config, or wrapper layer rather than manually editing this directory.
- Generated code may change broadly; keep local logic outside this directory.
