# model Agent Instructions

## Responsibility

`lib/api/model` defines internal admin domain models, value objects, enums, and operation result types.

## Rules

- Prefer immutable models with explicit required fields.
- Keep IDs, display labels, URLs, and external DTO field names clearly separated.
- Model participant links, player links, QR payloads, and upload results as stable app concepts.
- Do not put UI framework types in domain models.
- Do not expose generated API models directly to UI or controllers.
- Keep JSON and DTO mapping in services or mappers.

## Warnings

- Do not import widgets, generated clients, Dio, S3 SDKs, or browser APIs.
- Do not encode secrets, session identifiers, or private upload credentials in model fields intended for display.
