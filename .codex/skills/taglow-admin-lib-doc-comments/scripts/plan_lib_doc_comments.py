#!/usr/bin/env python3
"""Create a first-pass inventory for Taglow admin Dart doc comment work."""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable


CLASS_LIKE_RE = re.compile(
    r"^\s*(?:(?:abstract|base|final|interface|sealed)\s+)?"
    r"(class|mixin|enum|extension|typedef)\s+([A-Za-z_]\w*)?"
)
TOP_LEVEL_VALUE_RE = re.compile(
    r"^\s*(?:final|const|var)\s+([A-Za-z_]\w*)\s*(?:=|;)"
)
FIELD_RE = re.compile(
    r"^\s*(?:static\s+)?(?:late\s+)?"
    r"(?:(?:final|const|var)\s+)?"
    r"(?:[A-Za-z_]\w*(?:<[^;{}()]*>)?\??\s+)?"
    r"([A-Za-z_]\w*)\s*(?:=|;)"
)
CALLABLE_RE = re.compile(
    r"^\s*(?:(?:static|external|factory)\s+)?"
    r"(?:(?:Future|Stream|Iterable|List|Map|Set)<[^;{}]*>\s+|"
    r"(?:void|bool|int|double|num|String|Object|Widget|Color|ThemeData)\??\s+|"
    r"[A-Za-z_]\w*(?:<[^;{}]*>)?\??\s+)?"
    r"([A-Za-z_]\w*)\s*\("
)
CONTROL_WORDS = {
    "assert",
    "catch",
    "for",
    "if",
    "return",
    "switch",
    "while",
}
NON_DECLARATION_PREFIXES = (
    "await ",
    "case ",
    "else",
    "return ",
    "state =",
    "super(",
    "this.",
    "throw ",
    "try ",
    "} ",
    "}",
)


@dataclass(frozen=True)
class Declaration:
    file: str
    line: int
    kind: str
    name: str
    scope: str
    documented: bool
    signature: str


def iter_dart_files(root: Path) -> Iterable[Path]:
    lib_dir = root / "lib"
    for path in sorted(lib_dir.rglob("*.dart")):
        relative = path.relative_to(root)
        if str(relative).startswith("lib/api/generated/"):
            continue
        yield path


def has_doc_comment(lines: list[str], index: int) -> bool:
    cursor = index - 1
    while cursor >= 0:
        stripped = lines[cursor].strip()
        if not stripped:
            cursor -= 1
            continue
        if stripped.startswith("@"):
            cursor -= 1
            continue
        return stripped.startswith("///")
    return False


def strip_inline_comment(line: str) -> str:
    if "://" in line:
        return line
    return line.split("//", 1)[0]


def classify_scope(depth: int) -> str:
    if depth <= 0:
        return "top-level"
    if depth == 1:
        return "class-or-extension"
    return "nested"


def is_possible_declaration_line(stripped: str) -> bool:
    if stripped.startswith(NON_DECLARATION_PREFIXES):
        return False
    if stripped.endswith(","):
        return False
    return True


def find_declarations(root: Path, path: Path) -> list[Declaration]:
    relative = str(path.relative_to(root))
    lines = path.read_text(encoding="utf-8").splitlines()
    declarations: list[Declaration] = []
    brace_depth = 0

    for index, line in enumerate(lines):
        stripped = line.strip()
        code = strip_inline_comment(line)
        scope = classify_scope(brace_depth)

        if not stripped or stripped.startswith(("import ", "export ", "part ")):
            brace_depth += code.count("{") - code.count("}")
            continue
        if not is_possible_declaration_line(stripped):
            brace_depth += code.count("{") - code.count("}")
            continue

        class_match = CLASS_LIKE_RE.match(code)
        if class_match:
            kind, name = class_match.groups()
            declarations.append(
                Declaration(
                    file=relative,
                    line=index + 1,
                    kind=kind,
                    name=name or "anonymous-extension",
                    scope=scope,
                    documented=has_doc_comment(lines, index),
                    signature=stripped,
                )
            )
        elif brace_depth == 0:
            value_match = TOP_LEVEL_VALUE_RE.match(code)
            callable_match = CALLABLE_RE.match(code)
            if value_match:
                declarations.append(
                    Declaration(
                        file=relative,
                        line=index + 1,
                        kind="top-level-value",
                        name=value_match.group(1),
                        scope=scope,
                        documented=has_doc_comment(lines, index),
                        signature=stripped,
                    )
                )
            elif callable_match and ("{" in code or "=>" in code):
                name = callable_match.group(1)
                if name not in CONTROL_WORDS:
                    declarations.append(
                        Declaration(
                            file=relative,
                            line=index + 1,
                            kind="function",
                            name=name,
                            scope=scope,
                            documented=has_doc_comment(lines, index),
                            signature=stripped,
                        )
                    )
        elif brace_depth == 1:
            callable_match = CALLABLE_RE.match(code)
            field_match = FIELD_RE.match(code)
            if callable_match and ("{" in code or "=>" in code or stripped.endswith(";")):
                name = callable_match.group(1)
                if name not in CONTROL_WORDS:
                    declarations.append(
                        Declaration(
                            file=relative,
                            line=index + 1,
                            kind="method-or-constructor",
                            name=name,
                            scope=scope,
                            documented=has_doc_comment(lines, index),
                            signature=stripped,
                        )
                    )
            elif field_match and "(" not in code:
                declarations.append(
                    Declaration(
                        file=relative,
                        line=index + 1,
                        kind="field",
                        name=field_match.group(1),
                        scope=scope,
                        documented=has_doc_comment(lines, index),
                        signature=stripped,
                    )
                )

        brace_depth += code.count("{") - code.count("}")

    return declarations


def render_markdown(declarations: list[Declaration]) -> str:
    missing = [item for item in declarations if not item.documented]
    documented = len(declarations) - len(missing)
    lines = [
        "# Taglow Admin Lib Doc Comment Inventory",
        "",
        f"- Declarations scanned: {len(declarations)}",
        f"- Already documented: {documented}",
        f"- Missing doc comments: {len(missing)}",
        "- Generated code excluded: `lib/api/generated/**`",
        "",
        "## Suggested Parallel Shards",
        "",
    ]
    shard_counts: dict[str, int] = {}
    for item in missing:
        shard_counts[shard_for_file(item.file)] = shard_counts.get(shard_for_file(item.file), 0) + 1

    for shard, count in sorted(shard_counts.items()):
        lines.append(f"- `{shard}`: {count} missing declarations")

    if not shard_counts:
        lines.append("- No subagent shards needed.")

    lines.extend(
        [
            "",
        "## Missing Worklist",
        "",
        ]
    )

    current_file = ""
    for item in missing:
        if item.file != current_file:
            current_file = item.file
            lines.extend(["", f"### `{current_file}`", ""])
        lines.append(
            f"- line {item.line}: `{item.kind}` `{item.name}` "
            f"({item.scope}) - `{item.signature}`"
        )

    if not missing:
        lines.append("- No missing declaration comments found by the first-pass scanner.")

    lines.extend(
        [
            "",
            "## Next Step",
            "",
            "For each item, inspect imports, callers, providers, tests, and adjacent layer files before writing comments.",
            "Use the SKILL.md class/method/variable templates and keep behavior unchanged.",
        ]
    )
    return "\n".join(lines)


def shard_for_file(file_path: str) -> str:
    if file_path in {"lib/main.dart", "lib/app.dart"}:
        return "main-bootstrap-routing"
    if file_path.startswith("lib/api/model/"):
        return "api-model"
    if file_path.startswith("lib/api/service/"):
        return "api-service"
    if file_path.startswith("lib/api/controller/"):
        return "api-controller"
    if file_path.startswith("lib/view/auth/"):
        return "view-auth"
    if file_path.startswith("lib/view/votes/"):
        return "view-votes"
    if file_path.startswith("lib/view/questions/"):
        return "view-questions"
    if file_path.startswith("lib/view/diagnostics/"):
        return "view-diagnostics"
    if file_path.startswith("lib/view/"):
        return "view-shared"
    if file_path.startswith("lib/utils/"):
        return "utils"
    if file_path.startswith("lib/theme/"):
        return "theme"
    return "misc-lib"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Inventory Dart declarations for Taglow admin doc comment work."
    )
    parser.add_argument("--root", default=".", help="Repository root path.")
    parser.add_argument(
        "--format",
        choices=("markdown", "json"),
        default="markdown",
        help="Output format.",
    )
    parser.add_argument(
        "--exit-code-missing",
        action="store_true",
        help="Exit with code 1 when undocumented declarations are found.",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    declarations: list[Declaration] = []
    for dart_file in iter_dart_files(root):
        declarations.extend(find_declarations(root, dart_file))

    if args.format == "json":
        print(json.dumps([asdict(item) for item in declarations], indent=2))
    else:
        print(render_markdown(declarations))

    if args.exit_code_missing and any(not item.documented for item in declarations):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
