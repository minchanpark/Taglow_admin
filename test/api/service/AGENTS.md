# test service Agent Instructions

## Responsibility

`test/api/service` verifies service contracts, gateway paths, mapper conversions, upload behavior, QR export, and browser-link wrappers.

## Rules

- Use fake Dio/generated clients, fake storage, and fake browser adapters.
- Cover endpoint path construction and payload mapping at the gateway/mapper boundary.
- Cover S3 success, S3 failure, API save failure after upload, QR export fallback, and player open fallback.

## Warnings

- Do not hit live Spring APIs, S3, or Firebase player URLs in default service tests.
