# Taglow Admin Performance Checklist

## Measure

- Initial route and login render.
- Vote list fetch/render time.
- Question image preview memory.
- Upload time and retry behavior.
- QR render/export time.
- Public preview and player route check latency.

## Inspect

- Riverpod rebuild scope.
- Image object lifecycle after editor close.
- Large list/table virtualization or pagination needs.
- Repeated QR exports and Blob/object URL cleanup.
- Browser console/network errors.

## Report

- Baseline evidence.
- Suspected bottleneck.
- Patch made.
- Before/after result.
- Remaining risk.
