# test Agent Instructions

## Scope

These instructions apply to all `test/**` files.

## Responsibility

`test` mirrors the application layers with focused unit, controller, widget, and integration-oriented checks.

## Rules

- Prefer focused tests that protect layer boundaries and important behavior.
- Test mappers against payload aliases and type changes.
- Test URL builders for participant/player paths, trailing slashes, and path encoding.
- Test QR export success/fallback behavior through service interfaces.
- Test controllers with mock services rather than real network, S3, or browser APIs.
- Widget tests should cover loading, empty, error, retry, disabled, submitting, upload, QR, and player-link states.

## Warnings

- Do not call production APIs, S3, or player URLs from unit/widget tests.
- Do not assert generated code internals when a wrapper behavior assertion is enough.
