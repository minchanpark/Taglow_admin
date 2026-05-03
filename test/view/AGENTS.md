# test view Agent Instructions

## Responsibility

`test/view` verifies screen and widget behavior.

## Rules

- Test visible states and callbacks, not private widget implementation details.
- Use fake controllers/providers and deterministic fixtures.
- Cover login, vote list, vote detail, operation links, QR preview/download affordance, player link actions, question editor, and diagnostics states.

## Warnings

- Do not let widget tests depend on network, storage, browser downloads, or new-tab launching.
