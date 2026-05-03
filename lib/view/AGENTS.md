# view Agent Instructions

## Scope

These instructions apply to all `lib/view/**` files.

## Responsibility

`lib/view` renders screens and components, subscribes to controller state, and forwards user actions.

## Rules

- Views read state from controllers or small view models.
- Views must not call external API clients, Dio, generated clients, S3 SDKs, browser downloads, or storage APIs directly.
- Views must not assemble server payloads or endpoint paths.
- Show loading, empty, error, retry, submitting, disabled, and success states clearly.
- Keep desktop/tablet layouts dense, scannable, and safe for text overflow.
- Use theme tokens and shared widgets instead of scattering visual constants.

## Warnings

- Do not put business state transitions in widgets.
- Do not mix persistence, networking, upload, QR export, or player launch logic into UI files.
