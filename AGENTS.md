# Project Agent Instructions

## Purpose

Taglow admin is a Flutter Web operations console for creating and managing votes and questions, uploading question images, and preparing participant links, QR codes, and StandbyMe player links for live events.

## Source Of Truth

- Product requirements: `dev/Taglow_admin_PRD.md`
- Technical design: `dev/Taglow_admin_TDD.md`
- API contract snapshot: `dev/tagvote-openapi.json` when present
- S3/upload setup notes: `dev/aws_s3_question_image_upload_setup.md` when present

## Instruction Policy

- Read `AGENTS.md` files from the repository root down to the directory containing the file being edited.
- More specific lower-level instructions override broader parent instructions.
- When adding a new top-level or layer directory, add an `AGENTS.md` that states its responsibility and forbidden dependencies.
- Keep tool-specific workflows out of general `AGENTS.md` files.
- If implementation ideas conflict with the PRD/TDD, follow the documented scope conservatively and update the docs before widening scope.

## Product Invariants

- ADMIN users can create, inspect, update, end, and delete votes and questions.
- Question images are uploaded outside the Spring payload; the server receives only `imageUrl` and `imageRatio`.
- Participant links use `TAGLOW_PARTICIPANT_BASE_URL/e/{voteId}`.
- Player links use `TAGLOW_PLAYER_BASE_URL/display/{voteId}` with `https://taglow-player.web.app` as the current player base URL.
- Participant QR codes contain only the public participant URL.
- MVP excludes moderation, analytics dashboards, reward user management, exports, AI analysis, organizations, billing, and remote player control.

## Architecture Invariants

- API flows follow `View -> Controller -> Service -> Gateway/Mapper -> Generated Client/Dio -> Server`.
- Browser, storage, QR export, and external-link operations stay behind service or utility wrappers.
- `lib/api/model` defines stable app domain models shared by controllers and services.
- Views and controllers must not import generated API clients, generated DTOs, Dio clients, S3 SDKs, or endpoint strings.
- Server payload and generated DTO churn is absorbed in `AdminApiGateway` and `AdminPayloadMapper`.
- Mock and real implementations must remain interchangeable through `AdminService`.

## Data / Privacy / Security Invariants

- Do not store admin passwords, long-lived AWS keys, tokens, or server secrets in frontend code or docs examples.
- Do not put admin URLs, tokens, sessions, internal API URLs, or AWS details into QR payloads.
- Do not expose generated server DTO field names in user-facing copy.
- Show configuration values only when they are non-secret operational settings.
- If player access control becomes required, treat it as post-MVP and document it before implementation.

## Development Rules

- Keep edits scoped to the layer that owns the behavior.
- Prefer immutable models and explicit loading, empty, error, retry, submitting, and success states.
- Add focused tests for mappers, URL builders, QR export behavior, controllers, and high-risk validation.
- When Flutter project files exist, run formatter, analyzer, and relevant tests after code edits.
- Do not edit generated code by hand.

## Directory Guide

- `dev/`: product, technical, API, and setup documents.
- `lib/`: Flutter application source.
- `lib/view/`: screens and widgets only.
- `lib/api/controller/`: Riverpod state and user-event orchestration.
- `lib/api/model/`: stable admin domain models and value objects.
- `lib/api/service/`: service contracts, mock/openapi implementations, gateway, mapper, upload, QR, and link launch wrappers.
- `lib/api/generated/`: generated OpenAPI code only.
- `lib/utils/`: deterministic helpers such as URL building, validation, env config, clipboard, and download support.
- `lib/theme/`: design tokens and app-wide styling.
- `test/`: focused tests that mirror the source layering.
