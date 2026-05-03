# Taglow Admin API Contract Checklist

## Backend Contract

- Confirm protected admin vote creation endpoint.
- Confirm `imageRatio` is `number/double` in DB, DTO, and OpenAPI.
- Confirm auth response and current-user endpoint shape.
- Confirm credential strategy: session/cookie with CSRF or token.
- Confirm CORS allowlist includes admin origin.
- Confirm public display/questions endpoints reflect saved vote/question data.

## Mapper Checks

- Accept `id`/`voteId` aliases where backend is inconsistent.
- Accept `name`/`voteName` aliases when needed.
- Accept `detail`/`description` aliases when needed.
- Parse `imageRatio` as `double`.
- Normalize status values to `VoteStatus`.
- Hide generated DTOs from controllers and views.

## Upload Checks

- S3 direct upload uses temporary credentials only.
- Presigned upload keeps signed URL out of persistent state and diagnostics.
- API save uses `imageUrl` and `imageRatio` only.
- Upload success + API failure keeps retry data available.
