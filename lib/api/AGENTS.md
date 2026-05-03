# api Agent Instructions

## Scope

These instructions apply to `lib/api/**` files.

## Responsibility

`lib/api` owns admin domain models, controllers, service contracts, service implementations, gateway/mapper boundaries, and generated API code.

## Rules

- Preserve the boundary between `controller`, `model`, `service`, and `generated`.
- Controllers depend on service contracts and domain models.
- Services expose domain models or stable app DTOs.
- Generated clients stay isolated behind gateway/mapper/service code.
- Public API verification payloads must be normalized before reaching controllers.

## Warnings

- Do not let UI import from `api/generated`.
- Do not let controllers import generated clients, Dio clients, S3 SDKs, or raw endpoint paths.
- Do not place widget code inside `lib/api`.
