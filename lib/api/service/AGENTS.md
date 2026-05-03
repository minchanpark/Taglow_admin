# service Agent Instructions

## Responsibility

`lib/api/service` wraps external integrations and complex technical behavior behind app-internal contracts.

## Rules

- `AdminService` is the controller-facing contract for auth, votes, questions, and public verification.
- `MockAdminService` and `OpenApiAdminService` must remain interchangeable.
- `AdminApiGateway` owns endpoint paths, headers, cookies, credentials policy, generated client calls, and raw payload retrieval.
- `AdminPayloadMapper` owns all raw payload and generated DTO to domain model conversion.
- `QuestionImageUploadService` owns image upload strategy details, including S3 direct upload or presigned URL PUT.
- `QrExportService` owns QR rendering/export details.
- `ExternalLinkLauncher` owns browser new-tab behavior and fallback reporting.
- Services expose domain models or stable app DTOs, not generated server models.

## Warnings

- Do not leak endpoint, SDK, browser, or generated-client churn into UI/controller layers.
- Do not store secrets in frontend code.
- Do not put widget layout, screen state, or user-facing decoration logic in services.
