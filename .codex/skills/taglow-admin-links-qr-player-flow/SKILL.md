---
name: taglow-admin-links-qr-player-flow
description: Implement, test, or review Taglow admin operation links, participant QR, and StandbyMe player flows. Use when working on AdminVoteLinks, AdminUrlBuilder, participant URL copy, QR rendering/export/fallback, player URL generation, player new-tab launch, diagnostics route checks, or voteId-to-player event mapping.
---

# Taglow Admin Links QR Player Flow

## Start

1. Read `AGENTS.md`, `lib/utils/AGENTS.md`, `lib/api/model/AGENTS.md`, `lib/api/controller/AGENTS.md`, `lib/api/service/AGENTS.md`, and affected vote view AGENTS files.
2. Read PRD/TDD URL, QR, player, vote detail, and diagnostics sections.
3. Keep link/QR/player behavior separate from server CRUD implementation.

## URL Rules

- Participant URL: `{TAGLOW_PARTICIPANT_BASE_URL}/e/{voteId}`.
- Player URL: `{TAGLOW_PLAYER_BASE_URL}/display/{voteId}`.
- Current player base URL: `https://taglow-player.web.app`.
- Optional item player URL: `{TAGLOW_PLAYER_BASE_URL}/display/{voteId}/items/{questionId}` only if PRD/TDD keeps it in scope.
- Trim duplicate slashes and encode path segments.
- In MVP, use `voteId` as the player display event id.

## QR Rules

- QR payload is the participant URL only.
- Default export is PNG when supported.
- Provide SVG or URL-copy fallback when PNG export fails.
- Use safe file names such as `taglow-{voteId}-participant-qr.png`.
- Do not include admin URL, token, session, internal API, AWS, or signed upload values.

## Implementation Workflow

1. Model stable results in `AdminVoteLinks` and `QrExportResult`.
2. Build URLs in `AdminUrlBuilder`, not widgets.
3. Expose copy/export/open actions through controller methods.
4. Implement QR rendering/export behind `QrExportService`.
5. Implement player new-tab behavior behind `ExternalLinkLauncher`.
6. Add diagnostics for missing base URLs and player route failures.
7. Test trailing slash bases, encoded ids, QR fallback, and player open fallback.

## Reference

Read `references/links-qr-player-checklist.md` for scenarios and acceptance checks.
