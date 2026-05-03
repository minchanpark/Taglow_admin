# Taglow Admin Security Checklist

## Auth

- ADMIN role checked after login/current-user fetch.
- Route guard blocks unauthenticated users.
- Logout clears local auth state.
- Cookie/token strategy does not expose secrets in UI.

## Upload

- No long-lived AWS keys in frontend code.
- Presigned URLs are short-lived and not persisted.
- S3 prefix policy is scoped to question images.
- Client file checks are UX only; backend/storage policy enforces real limits.

## QR And Links

- QR contains participant URL only.
- Player URL contains no secret.
- Diagnostics hide signed URLs, cookies, tokens, stack traces, and AWS keys.

## Code Boundaries

- No generated client imports in View/Controller.
- No endpoint strings outside service/gateway.
- No browser storage of admin password, token, session ID, or signed URL.
