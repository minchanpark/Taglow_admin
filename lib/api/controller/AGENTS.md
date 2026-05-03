# controller Agent Instructions

## Responsibility

`lib/api/controller` owns Riverpod state, user-event handling, validation, flow orchestration, and UI-facing actions.

## Rules

- Depend on `AdminService` and other service interfaces/providers, not concrete external clients.
- Expose clear methods for UI actions: login, load votes, create vote, update status, upload image, save question, copy/export/open links.
- Keep loading, empty, error, retry, submitting, upload, and success states explicit.
- Use `lib/api/model` types for state and service results.
- Route URL building, QR export, clipboard, download, and browser launch through utilities/services.

## Warnings

- Do not import generated clients, Dio, S3 SDKs, or endpoint strings.
- Do not combine unrelated flows into one broad state object when separate controllers are clearer.
- Do not store passwords, tokens, or signed upload URLs in controller state longer than necessary.
