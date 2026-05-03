# Taglow Admin Operations UX Checklist

## Operator Flow

- Can log in and see the next obvious action.
- Can create a vote without reading docs.
- Can add a question with image and understand upload status.
- Can copy participant URL and player URL.
- Can preview/download QR with fallback.
- Can run public/player checks before field use.

## UI Quality

- Dense desktop/tablet layout, not a landing page.
- Tables and forms are scan-friendly.
- Buttons have stable dimensions and clear disabled states.
- Long URLs do not break layout.
- Error messages identify likely owner: auth, CORS, S3, API, QR, player.

## Accessibility

- Keyboard access for forms and dialogs.
- Icon-only controls have labels/tooltips.
- Contrast is adequate.
- Critical actions are not hover-only.
