---
name: taglow-admin-lib-doc-comments
description: Add, audit, or revise Korean Dart documentation comments for Taglow admin `lib/**` code. Use when Codex is asked to document classes, methods, functions, providers, fields, variables, controllers, services, widgets, utilities, or theme code under `lib`, especially when comments must follow the required fields/Parameters/Returns templates, explain cross-file relationships in the Taglow admin architecture, and use subagents for broad parallel documentation passes when permitted.
---

# Taglow Admin Lib Doc Comments

## Quick Run

When this skill is invoked for broad `lib/**` work, immediately run:

```bash
python3 .codex/skills/taglow-admin-lib-doc-comments/scripts/plan_lib_doc_comments.py --root .
```

Use the generated inventory and shard summary as the first worklist, then inspect related source files before editing comments. The script is a coverage accelerator; Codex still writes the final Korean comments after understanding cross-file relationships.

## Start

1. Use only for `/Users/minchanpark/Documents/Taglow_admin`.
2. Run `scripts/plan_lib_doc_comments.py` from the repository root before a broad documentation pass.
3. Read root `AGENTS.md`, `lib/AGENTS.md`, and the nearest `lib/**/AGENTS.md` before editing each area.
4. Read relevant PRD/TDD sections only when a declaration represents product behavior, API scope, upload/link/QR behavior, auth, or security-sensitive flow.
5. Exclude `lib/api/generated/**` from manual comment edits unless the user explicitly overrides the project rule against editing generated code.
6. Preserve behavior. This skill adds explanatory documentation comments only.

## Parallel Subagent Workflow

Use subagents only when the current user request explicitly asks for subagents, parallel agents, or delegated execution. For broad `lib/**` documentation passes where subagents are permitted:

1. Run the inventory script first and use its "Suggested Parallel Shards" section.
2. Keep the main agent responsible for coordination, final review, formatting, analyzer/test runs, and any file that does not fit a shard cleanly.
3. Use explorer subagents for read-only audit/worklist partitions when file ownership is unclear. Use worker subagents for direct edits only when write scopes are disjoint.
4. Tell every worker they are not alone in the codebase, must not revert others' edits, and must adjust to existing concurrent changes.
5. Prefer these ownership groups:
   - Worker A: `lib/api/model/**` and model-adjacent tests for relationship checks.
   - Worker B: `lib/api/service/**`, excluding `lib/api/generated/**`.
   - Worker C: `lib/api/controller/**`.
   - Worker D: `lib/view/**`, split further by `auth`, `votes`, `questions`, and `diagnostics` if the pass is large.
   - Main agent: `lib/main.dart`, `lib/app.dart`, `lib/utils/**`, `lib/theme/**`, integration review, and conflict cleanup.
6. Give each worker this output contract: edit files directly only inside the assigned scope, add Korean `///` comments using this skill's templates, preserve behavior, run `dart format` on changed Dart files when practical, and report changed paths plus any unresolved uncertainty.
7. Review worker changes before finalizing. Ensure Korean terminology, required section labels, and relationship explanations are consistent across shards.

Use this handoff template for each subagent:

```text
Use $taglow-admin-lib-doc-comments in /Users/minchanpark/Documents/Taglow_admin.
You are not alone in the codebase; do not revert edits made by others.
Scope: <exact files or directory shard>.
Read: root AGENTS.md, lib/AGENTS.md, and every nearest AGENTS.md for the scope.
Do not edit lib/api/generated/**.
Task: add Korean Dart /// comments only in scope using fields:/Parameters:/Returns: templates.
Analyze imports, callers, providers, tests, adjacent layers, and PRD/TDD invariants before writing comments.
Return: changed file paths, skipped declarations, and unresolved uncertainties.
```

## Analysis Workflow

1. Build a declaration map with `rg --files lib -g '*.dart'` and focused `rg` searches for `class`, `enum`, `extension`, `typedef`, top-level `final/const`, providers, functions, methods, getters, setters, and fields.
2. For each declaration, inspect its imports, callers, providers, tests, model/service/controller/view usage, and adjacent files before writing the comment.
3. Explain the declaration's role and at least one meaningful connection point when it exists: upstream caller, downstream dependency, provider wiring, mapper/gateway boundary, model consumed by views, URL/upload/QR helper usage, or test surface.
4. Document stable declarations, not every implementation statement. Cover classes, enums, extensions, typedefs, constructors, public and private methods, top-level variables/providers/constants, and meaningful fields. Avoid doc comments for single-use local temporaries unless the user asks for absolutely every local variable.
5. If a declaration is already documented, revise it only when it misses the required format, has stale architecture information, or omits important cross-source relationships.

## Required Comment Format

Write the documentation comment prose in Korean by default. Keep code identifiers, section labels (`fields:`, `Parameters:`, `Returns:`), type names, route names, provider names, and API terms unchanged when translating them would reduce precision.

For classes, enums, extensions, and typedefs:

```dart
/// 선언의 책임을 한국어로 설명합니다.
/// 연결된 컨트롤러, 서비스, 모델, 뷰, 유틸 계층과의 접점을 설명합니다.
/// 생명주기, 경계, 제품 맥락이 중요하면 한 줄을 더 사용합니다.
/// fields:
/// - [fieldName]: 이 필드가 저장하는 값과 호출자/의존성이 사용하는 방식을 설명합니다.
/// - [otherField]: 관련 상태, 주입된 서비스, 도메인 모델과의 연결을 설명합니다.
class Example {}
```

- Include `fields:` for every class-like declaration. If there are no stored fields, use `/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.`.
- Mention injected dependencies, provider-created values, constructor fields, static constants, and state fields when they are part of the class contract.

For methods, functions, constructors, getters, and setters:

```dart
/// 수행하는 작업을 한국어로 설명합니다.
/// 호출자, 의존성, 부수 효과, 계층 흐름과의 연결을 설명합니다.
/// 검증, 비동기 동작, 오류 처리가 중요하면 한 줄을 더 사용합니다.
/// Parameters:
/// - [parameterName]: 입력값과 호출자 또는 하위 의존성과의 관계를 설명합니다.
/// Returns:
/// - [result]: 반환값 또는 상태 변경의 의미를 설명합니다.
Future<Result> doWork(String parameterName) async {}
```

- Use `/// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.` under `Parameters:` when there are no parameters.
- Use `/// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.` for `Future<void>`, `/// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.` for synchronous `void`, `/// - [instance]: 연결된 의존성을 보관하는 새 인스턴스입니다.` for constructors, and `/// - [result]: 호출자가 다음 계층에서 사용하는 결과입니다.` when the return value has no better semantic name.
- For getters, describe the computed value under `Returns:`. For setters, describe the consumed value under `Parameters:` and use `Returns: - [void]: ...`.

For variables, providers, constants, and fields:

```dart
/// 값의 의미를 한국어로 설명합니다.
/// 어디에서 읽히거나 주입되며 어떤 소스와 동기화되어야 하는지 설명합니다.
/// 설정, 제품 정책, 계층 경계가 중요하면 한 줄을 더 사용합니다.
final value = Example();
```

- Apply this to top-level variables, Riverpod providers, constants, class fields, and meaningful static fields.
- Keep descriptions specific; avoid restating the identifier in prose.

## Quality Rules

- Keep the summary to two or three useful lines before the required sections.
- Use Korean sentences that are concise and operational; avoid awkward literal translation from English.
- Prefer precise architecture language: View, Controller, Service, Gateway, Mapper, Generated Client, utility, theme token, or domain model.
- Do not expose server DTO field names, secrets, tokens, internal URLs, AWS details, or generated implementation details in user-facing explanations.
- Do not add comments that promise behavior the code does not implement.
- Run `dart format` on edited Dart files and the closest analyzer/test loop when practical.

## Reference

Read `references/doc-comment-checklist.md` before broad `lib/**` documentation passes or when verifying coverage.
