# auth View Agent Instructions

## Responsibility

`lib/view/auth` contains login and access-control screens.

## Rules

- Collect credentials only long enough to submit them through the auth controller.
- Do not persist passwords or expose auth payload details in UI copy.
- Show failed login, unauthorized role, loading, and retry states distinctly.
- After authentication, rely on controller state to decide navigation.

## Warnings

- Do not call auth endpoints directly from the login page.
- Do not duplicate ADMIN role logic in widgets when the controller/model already exposes it.
