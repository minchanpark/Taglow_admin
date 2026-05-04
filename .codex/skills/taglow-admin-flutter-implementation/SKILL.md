---
name: taglow-admin-flutter-implementation
description: Build, refactor, or review Taglow admin Flutter Web features. Use when Codex works on admin login, vote CRUD, question CRUD, S3/presigned image upload, operation links, participant QR export, StandbyMe player links, Riverpod controllers, go_router routes, or layered View/Controller/Service/Gateway/Mapper architecture in this repository.
---

# Taglow Admin Flutter Implementation

## Start

1. Use only for `/Users/minchanpark/Documents/Taglow_admin`.
2. Read `AGENTS.md`, `lib/AGENTS.md`, and the nearest `lib/**/AGENTS.md` before editing code.
3. Read only the relevant PRD/TDD sections in `dev/Taglow_admin_PRD.md` and `dev/Taglow_admin_TDD.md`.
4. Preserve the MVP scope: admin operations console, vote/question management, question image upload, participant link/QR, and player link checks.

## Architecture Rules

- Follow `View -> Controller -> Service -> Gateway/Mapper -> Generated Client/Dio -> Server`.
- Keep browser, storage, QR export, and new-tab operations behind service or utility wrappers.
- Keep stable domain models in `lib/api/model`.
- Keep View limited to rendering and user input forwarding.
- Keep Riverpod state, validation, retries, upload status, and navigation decisions in controllers.
- Keep backend endpoints, generated DTOs, Dio, S3, and presigned upload details behind `lib/api/service`.
- Do not import generated API code, Dio, S3 SDKs, or browser APIs from View or Controller.

## Implementation Workflow

1. Identify the owner layer and read its local `AGENTS.md`.
2. Add/update domain models before controller/service code when data shape changes.
3. Build against `MockAdminService` first when the backend is not confirmed.
4. Wire real API through `AdminServiceProvider`, `OpenApiAdminService`, `AdminApiGateway`, and `AdminPayloadMapper`.
5. Add loading, empty, error, retry, submitting, uploading, and fallback states where data crosses a boundary.
6. Keep operation links local: `AdminUrlBuilder`, `QrExportService`, `ExternalLinkLauncher`.
7. Run the closest formatter/analyzer/test loop when Flutter scaffold exists.

## Feature Checklist

- USER and ADMIN login can enter the operations console; ADMIN is only the highest-privilege role distinction.
- Vote list/detail supports create, update, end, delete, loading, empty, error, and retry.
- Question editor distinguishes image upload failure from API save failure.
- Server receives `imageUrl` and `imageRatio`, not bytes.
- Participant URL is `{TAGLOW_PARTICIPANT_BASE_URL}/e/{voteId}`.
- Player URL is `{TAGLOW_PLAYER_BASE_URL}/display/{voteId}` with `https://taglow-player.web.app` as the current base.
- QR payload contains only the participant URL.
- Generated code stays untouched.

## Reference

Read `references/implementation-checklist.md` for screen-by-screen implementation checks.
