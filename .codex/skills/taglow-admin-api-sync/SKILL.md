---
name: taglow-admin-api-sync
description: Synchronize Taglow admin Flutter services with the Spring backend API. Use when fetching or reviewing OpenAPI contracts, updating admin auth/vote/question/public-preview endpoints, generated clients, Dio gateways, payload mappers, mock service parity, imageRatio schema, S3/presigned upload contracts, CORS/CSRF assumptions, or API boundary tests.
---

# Taglow Admin API Sync

## Start

1. Use only for `/Users/minchanpark/Documents/Taglow_admin`.
2. Read `AGENTS.md`, `lib/api/AGENTS.md`, `lib/api/service/AGENTS.md`, and `lib/api/generated/AGENTS.md`.
3. Read the API, auth, upload, URL, and OpenAPI sections in `dev/Taglow_admin_TDD.md`.
4. Preserve existing user changes before refreshing or regenerating anything.

## Contract Direction

- Keep `AdminService` as the stable controller-facing contract.
- Keep generated OpenAPI clients under `lib/api/generated/`.
- Keep endpoint paths and transport policy in `AdminApiGateway`.
- Keep payload aliases, type coercion, and generated DTO normalization in `AdminPayloadMapper`.
- Keep mock behavior aligned with real service behavior.
- Do not hand-edit generated client files.

## API Areas

- Auth: `POST /api/auth/login`, `GET /api/auth/me` or `GET /api/users/me`, `POST /api/auth/logout`.
- Vote admin: `GET /api/votes`, `POST /api/votes` or equivalent ADMIN endpoint, `GET/PATCH/DELETE /api/votes/{voteId}`.
- Question admin: `GET /api/votes/{voteId}/questions`, `POST /api/questions`, `GET/PATCH/DELETE /api/questions/{questionId}`.
- Public verification: `GET /api/public/votes/{voteId}/display`, `GET /api/public/votes/{voteId}/questions`.
- Upload: S3 direct upload or Spring-issued presigned URL/upload policy.

## Update Workflow

1. Refresh or inspect `dev/tagvote-openapi.json` only when the user asks or backend contract changed.
2. Compare backend schema and runtime sample shape against gateway/mapper expectations.
3. Patch service-owned files first; avoid View changes unless state shape truly changes.
4. Add mapper/gateway/mock tests for new aliases, endpoints, and error states.
5. Verify generated DTOs do not reach controllers or views.

## Reference

Read `references/api-contract-checklist.md` for endpoint, mapper, and upload contract checks.
