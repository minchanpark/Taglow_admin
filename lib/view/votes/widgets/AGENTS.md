# vote Widgets Agent Instructions

## Responsibility

`lib/view/votes/widgets` contains reusable, mostly presentational vote widgets.

## Rules

- Widgets receive already-shaped values and callbacks from parent pages/controllers.
- Keep widgets small: form dialog, status control, operation links, QR panel, player URL panel, and preview panel.
- Use stable dimensions for QR previews, buttons, status chips, and link rows to avoid layout shifts.
- Represent copy/download/open actions with callbacks, not direct service calls.

## Warnings

- Do not duplicate URL-building logic here.
- Do not nest card-like panels inside other cards unless the design system explicitly requires it.
