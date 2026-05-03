# Taglow Admin Testing Matrix

## Unit

- `AdminUrlBuilder`: participant, player, trailing slash, encoded ids.
- `ImageRatioReader`: width/height and invalid images.
- `AdminPayloadMapper`: aliases, status, dates, `imageRatio`.
- Validators: vote name, question fields, URL config.

## Controller

- Auth: success, failure, non-admin, logout.
- Vote list/detail: load, create, update, delete, public preview.
- Question editor: draft, upload, save, upload failure, API failure after upload.
- Operation links: copy, QR export, player open fallback.

## Widget

- Login states.
- Vote list loading/empty/error/success.
- Vote detail operation links and QR panel.
- Question editor upload/save states.
- Diagnostics checks and failure messages.

## Integration-Oriented

- Login -> vote create -> question save -> public preview.
- Vote detail -> participant QR download fallback.
- Vote detail -> player link open and fallback copy.
