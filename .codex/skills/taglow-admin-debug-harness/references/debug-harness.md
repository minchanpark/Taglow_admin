# Taglow Admin Debug Harness Reference

## Suggested Artifacts

- `.ai_debug/reports/runtime_errors.md`
- `.ai_debug/reports/test_failure.md`
- `.ai_debug/reports/widget_tree_summary.md`
- `.ai_debug/reports/network_summary.md`
- `.ai_debug/reports/upload_summary.md`
- `.ai_debug/reports/qr_export_summary.md`
- `.ai_debug/reports/player_route_summary.md`
- `.ai_debug/reports/verification_report.md`
- `.ai_debug/reports/retry_plan.md`

## Artifact Template

- Command or manual flow:
- Timestamp:
- Failure type:
- Expected behavior:
- Actual behavior:
- Evidence:
- Suspected owner layer:
- Patch attempted:
- Verification:
- Remaining blocker:

## Boundary Search Ideas

- Generated imports outside generated/service: `rg "api/generated|tagvote_api_client" lib`
- Endpoint strings outside service: `rg "/api/" lib`
- S3/browser calls outside wrappers: `rg "S3|Presigned|window\\.open|download|clipboard" lib`
