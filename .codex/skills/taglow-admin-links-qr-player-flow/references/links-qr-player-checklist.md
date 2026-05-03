# Taglow Admin Links QR Player Checklist

## URL Examples

- Participant: `https://taglow-acca6.web.app/e/venturous-2026`
- Player: `https://taglow-player.web.app/display/venturous-2026`
- Optional item player: `https://taglow-player.web.app/display/venturous-2026/items/question-1`

## Acceptance

- Base URL missing shows diagnostics and disables unsafe actions.
- Trailing slash base URL does not create double slashes.
- Vote IDs are path-encoded.
- QR preview renders from participant URL.
- PNG export works or falls back to SVG/copy.
- Player open failure leaves URL copy available.
- Public display quick check confirms player-readable data.

## Forbidden Payloads

- Admin URL.
- Admin token or session.
- Internal API URL.
- AWS bucket/private key/signed URL.
- Debug query containing secret values.
