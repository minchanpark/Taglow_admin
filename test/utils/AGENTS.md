# test utils Agent Instructions

## Responsibility

`test/utils` verifies deterministic helper behavior.

## Rules

- Cover URL construction, slash trimming, path encoding, validation, filename generation, env parsing, clipboard/download adapter behavior, and image ratio helpers.
- Keep tests pure unless a helper explicitly wraps a platform adapter.

## Warnings

- Do not use real browser clipboard or download APIs in default tests.
