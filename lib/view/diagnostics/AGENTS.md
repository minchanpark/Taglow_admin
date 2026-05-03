# diagnostics View Agent Instructions

## Responsibility

`lib/view/diagnostics` contains operational checks for API, S3, CORS, URL, QR, and player configuration.

## Rules

- Show non-secret configuration values such as API base URL, participant base URL, player base URL, S3 bucket name, and region.
- Route checks and quick checks must go through controller/service wrappers.
- Differentiate auth, CORS, S3 upload, public API, QR export, and player route failures.

## Warnings

- Do not display secrets, passwords, access keys, session IDs, or signed upload URLs.
- Do not add destructive admin actions to diagnostics without explicit product documentation.
