# lib Agent Instructions

## Scope

These instructions apply to all `lib/**` application files.

## App Structure

- Keep app bootstrap code minimal.
- Feature behavior must live in the appropriate view, controller, model, service, utility, or theme layer.
- Imports must follow the approved dependency direction:
  `view -> controller -> service -> gateway/mapper/generated`.
- `api/model` may be shared by controllers, services, utilities, and views when needed for display.
- Avoid reverse imports and circular dependencies.

## Platform Baseline

- Build for desktop web first, with tablet-safe responsive behavior.
- Access browser, storage, download, QR export, and external-link capabilities through wrappers.
- Keep text overflow, loading states, and error states explicit.

## Implementation Warnings

- Verify external package APIs at implementation time.
- Keep external SDK and generated client details behind service or generated layers.
- Do not scatter endpoint paths, player route strings, or environment parsing through widgets.

## Validation

- Run formatter, analyzer, and relevant tests after code edits once the Flutter project is present.
- Add focused tests for high-risk controller, service, mapper, URL, and QR behavior.
