# web Agent Instructions

## Responsibility

`web` contains Flutter Web bootstrap files, web manifest metadata, icons, and static host configuration.

## Rules

- Keep this directory limited to web platform bootstrap and static assets.
- Do not put Flutter app logic, API calls, endpoint strings, credentials, or environment-specific secrets here.
- Runtime configuration must come from Flutter `--dart-define` values or service/provider layers.
- Keep app title, description, theme color, and manifest metadata aligned with Taglow Admin.

## Warnings

- Do not edit generated Flutter build output in `build/web`.
- Do not add admin tokens, cookies, AWS keys, or private server URLs to HTML, manifest, or JavaScript files.
