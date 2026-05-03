# questions View Agent Instructions

## Responsibility

`lib/view/questions` contains question creation and editing screens.

## Rules

- Question views render drafts, validation, image preview, upload progress, and save states from the controller.
- Image selection is a UI event; decoding, ratio calculation, upload, and persistence are controller/service responsibilities.
- Block save when required title, detail, image URL, or image ratio state is missing.
- Distinguish upload failure from API save failure in the UI.

## Warnings

- Do not call S3, presigned URL PUT, Dio, or generated clients directly from question widgets.
- Do not store selected image bytes in long-lived UI-only globals.
