# test controller Agent Instructions

## Responsibility

`test/api/controller` verifies Riverpod state transitions and user-event orchestration.

## Rules

- Use mock service implementations and fake URL/QR/link launch wrappers.
- Cover success, loading, empty, validation, failure, retry, and fallback states.
- Verify controllers do not require generated client types.

## Warnings

- Do not use live network or storage in controller tests.
