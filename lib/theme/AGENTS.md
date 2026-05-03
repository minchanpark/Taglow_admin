# theme Agent Instructions

## Responsibility

`lib/theme` owns design tokens and app-wide styling.

## Rules

- Keep colors, typography, spacing, radius, elevation, and component styles centralized.
- Use semantic token names instead of one-off visual values.
- Keep compact admin UI density, legible contrast, and safe touch targets reflected in component styles.
- Support desktop web first while keeping tablet layouts stable.

## Warnings

- Do not put business logic, service calls, state transitions, or route decisions in theme files.
- Theme decoration must not overpower core operational workflows.
