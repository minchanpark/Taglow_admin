# Taglow Admin Implementation Checklist

## Screens

- Login: credentials, loading, invalid credentials, non-admin role, logout recovery.
- Vote list: fetch, empty, error/retry, create dialog, status chips, detail entry.
- Vote detail: base info, status update, question list, public preview, operation links.
- Question editor: title/detail, image picker, ratio preview, upload status, save retry.
- Diagnostics: API, auth, CORS, S3/upload, participant URL, QR, player URL checks.

## Boundaries

- View calls controller only.
- Controller calls service contracts and utilities through providers.
- Service owns API, upload, QR, and external link wrappers.
- Gateway/mapper owns endpoint and payload churn.
- Generated client stays under `lib/api/generated`.

## Done Criteria

- Mock flow works without backend.
- Real API path is isolated behind service provider.
- Focused tests cover changed model/controller/service/widget behavior.
- Flutter analyze and relevant tests pass when scaffold exists.
