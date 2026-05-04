# Tagvote API Contract Analysis

분석 시점: 2026-05-03

## Sources

- Notion API 명세서: `https://www.notion.so/3536cd041f7f8005a1fefa1a2f633421`
- Swagger UI: `https://vote.newdawnsoi.site/swagger-ui/index.html#/`
- OpenAPI snapshot: `dev/tagvote-openapi.json`
- Server base URL: `https://vote.newdawnsoi.site`

## Confirmed Server Facts

- Swagger config points to `/v3/api-docs`.
- Base server root `/` returns `403` and sets `JSESSIONID`.
- Auth uses session/cookie style; login response schema is `AuthUserResponse`.
- Unauthenticated protected endpoints such as `/api/auth/me`, `/api/users/me`, `/api/votes`, and `/api/users` return `403`.
- `/api/public/votes` accepts admin origin preflight but does not include `Access-Control-Allow-Credentials: true`, so Flutter must not send browser credentials while this temporary public create path is used.
- Public display/questions endpoints work for known vote IDs `1` and `2`.
- Runtime public display shape:
  - `voteId`
  - `voteName`
  - `status`
  - `questions: [{ question, tags }]`
- Runtime tag payload includes `isMine` and `canDelete` in addition to the core tag fields.

## Notion vs Swagger Differences

| Area | Notion | Swagger/runtime | Admin impact |
|---|---|---|---|
| logout success | `204 No Content` | Swagger says `200` | Gateway must accept body-less 2xx responses. |
| vote create response | `201 Created` | Swagger says `200` | Client should not depend on status text. |
| vote create path | `POST /api/public/votes` documented as public | Protected `POST /api/votes` still needs confirmation | Admin app keeps path configurable and sends the temporary public request without browser credentials. |
| `createdByUserId` | documented required | Swagger requires only `name` | Service sends current user id when known. |
| question create response | implied created | Swagger says `200` | Client should parse response body only. |
| `imageRatio` | `number` | Swagger says `integer int64` | Mapper parses both; backend schema should become double. |
| player CORS | player should read public APIs | runtime preflight rejects `https://taglow-player.web.app` | Server allowlist must add player origin. |

## Flutter API Decisions

- Store IDs as `String` in domain models so numeric server IDs and future slug IDs can both work.
- Parse `id` and `userId` aliases for auth user payloads.
- Parse `id` and `voteId`, `name` and `voteName`, `detail` and `description` aliases in mapper.
- Keep `DioAdminApiGateway.voteCreatePath` configurable. Current default matches Swagger: `/api/public/votes`.
- Override browser `withCredentials` to `false` only for the temporary `/api/public/votes` create request because that CORS response is non-credentialed.
- Keep View/Controller isolated from raw JSON, generated DTOs, Dio, cookies, and S3/presigned upload details.

## Required Backend Follow-Up

1. Add protected logged-in-user vote creation endpoint, preferably `POST /api/votes`.
2. Change `QuestionCreateRequest`, `QuestionUpdateRequest`, and `QuestionResponse.imageRatio` to `number/double`.
3. Add `https://taglow-player.web.app` to CORS allowlist for public display/questions/events APIs.
4. Confirm admin deployment origin and add it to CORS allowlist.
5. Decide S3 direct upload vs Spring presigned URL for question images.
