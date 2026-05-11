---
name: taglow-admin-performance-audit
description: Audit or debug Taglow admin Flutter Web performance. Use for slow vote lists, large question images, QR rendering/export delay, upload memory growth, Riverpod rebuild storms, diagnostics slowness, player preview checks, Chrome/Flutter DevTools profiling, web bundle size, or performance regression reviews.
---

# Taglow Admin Performance Audit

## Start

1. Read `AGENTS.md`, `lib/AGENTS.md`, relevant View/Controller/Service AGENTS files, and the debugging skill if this is a live bug.
2. Measure before optimizing when possible.
3. Keep correctness, security, and operator feedback intact.

## Parallel Subagent Workflow

Use subagents only when the current user request explicitly asks for subagents, parallel agents, or delegated execution. For broad performance audits that span several independent surfaces:

1. Keep the main agent responsible for the measurement plan, baseline summary, optimization decisions, final integration, and before/after comparison.
2. Use explorer subagents for read-only evidence slices such as initial load, vote list/detail rendering, image upload memory, QR export cost, Riverpod rebuilds, and bundle/web diagnostics.
3. Use worker subagents for performance patches only after evidence identifies independent owner areas and write scopes are disjoint.
4. Tell every worker they are not alone in the codebase, must not revert edits made by others, and must not remove loading/error/retry or weaken URL, QR, auth, or upload correctness.
5. Require each subagent to report measurements, changed paths if any, commands/tools used, and remaining performance risks.

## Audit Areas

- Initial load: login page, route guard, vote list fetch.
- Vote list/detail: table rendering, filters, public preview checks, state granularity.
- Image upload: file read, ratio calculation, preview lifecycle, memory release.
- QR: render cost, PNG/SVG export, repeated downloads, payload stability.
- Player: URL generation and route check timing.
- Web: bundle size, source maps, service worker/cache assumptions, console errors.
- State: Riverpod provider granularity and avoidable full-screen rebuilds.

## Optimization Rules

- Do not remove loading/error/retry states for speed.
- Do not weaken URL, QR, auth, or upload correctness.
- Prefer smaller rebuild surfaces over global state shortcuts.
- Prefer image sizing and preview lifecycle fixes over decorative loading tricks.
- Record before/after evidence when possible.

## Reference

Read `references/performance-checklist.md` for measurement and review steps.
