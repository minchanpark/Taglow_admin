# test api Agent Instructions

## Responsibility

`test/api` contains tests for controllers, models, services, gateways, and mappers.

## Rules

- Mirror `lib/api` responsibilities in test names and fixtures.
- Keep fixtures small and explicit.
- Prefer testing public contracts over private implementation details.

## Warnings

- Do not require live backend credentials or AWS configuration for default tests.
