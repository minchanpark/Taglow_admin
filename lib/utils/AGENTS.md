# utils Agent Instructions

## Responsibility

`lib/utils` contains shared helper functions and technical support logic.

## Rules

- Utilities should be small, deterministic, and reusable.
- `AdminUrlBuilder` builds participant URLs, player URLs, and optional item-level player URLs.
- URL builders must trim duplicate slashes and encode dynamic path segments safely.
- `EnvConfig` may expose non-secret configuration such as API, participant, player, S3 bucket, and region values.
- Clipboard and browser download helpers must not know product flow state.
- Validation helpers must stay consistent with controller/service policy.

## Warnings

- Do not put screen logic, service implementations, generated client calls, or controller state here.
- Do not store sensitive data in helper-level caches.
- If a utility needs to import UI or service implementations, reconsider the boundary.
