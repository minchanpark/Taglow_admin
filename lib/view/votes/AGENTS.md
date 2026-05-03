# votes View Agent Instructions

## Responsibility

`lib/view/votes` contains vote list/detail pages and vote operation panels.

## Rules

- Vote pages render controller state for votes, questions, public previews, operation links, QR export, and player checks.
- Use controller actions for creating, updating, deleting, ending, copying, exporting QR, and opening player links.
- Do not build participant or player URLs manually in widgets.
- Keep vote tables/lists compact and operational, not marketing-style.

## Warnings

- Do not place generated API models or raw public-preview payload parsing in vote pages.
- Do not let operation-link widgets directly touch clipboard, download, or browser launch APIs.
