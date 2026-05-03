# tagvote API Client Agent Instructions

## Responsibility

`lib/api/generated/tagvote_api_client` is reserved for generated Dart Dio client files created from the Taglow OpenAPI contract.

## Rules

- Do not edit files in this directory by hand.
- Regenerate the client from the approved OpenAPI spec when API contracts change.
- Keep wrappers, adapters, mapper fixes, and business logic in `lib/api/service`.

## Warnings

- Do not import generated models from UI or controller code.
- Do not add handwritten convenience methods here.
