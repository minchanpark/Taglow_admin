# Dart Doc Comment Checklist

Use this checklist for broad Korean `lib/**` documentation work.

## Coverage

- Root files: `lib/main.dart`, `lib/app.dart`.
- Models: immutable fields, `copyWith`, enums, value objects, upload and QR result models.
- Controllers: providers, state classes, state fields, constructors, load/submit/retry helpers, private error helpers.
- Services: contracts, mock/real implementations, gateway calls, mapper methods, upload/QR/external-link wrappers.
- Utilities: URL building, validation, env config, clipboard/download/browser helpers, image ratio helpers.
- Views: pages, private widgets, callbacks, controllers watched through providers, layout state.
- Theme: token classes, theme factory methods, semantic constants.

## Relationship Prompts

- Who creates or injects this declaration?
- Which layer consumes it next?
- Does it shield another layer from generated clients, Dio, browser APIs, upload details, routes, or endpoint strings?
- Does it encode a PRD/TDD invariant such as participant/player URLs, QR payload scope, admin auth, image upload shape, or MVP exclusions?
- Which tests should break if this behavior changes?

## Verification

- Search for remaining undocumented declarations with focused `rg` patterns rather than a single broad regex.
- Re-read changed comments next to the code and remove any sentence that merely repeats the signature.
- Confirm every added comment uses Korean prose while preserving required section labels and code identifiers.
- Confirm Korean terminology is consistent for View, Controller, Service, Gateway, Mapper, provider, participant link, player link, QR, upload, and domain model.
- Confirm worker/subagent shards have disjoint file ownership before merging their changes.
- Confirm generated code remains untouched.
- Run `dart format` on changed Dart files, then `flutter analyze` and relevant tests when the edit scope is large enough.
