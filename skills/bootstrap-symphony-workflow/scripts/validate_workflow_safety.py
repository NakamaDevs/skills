#!/usr/bin/env python3
"""Validate restricted Symphony WORKFLOW.md front matter."""

from __future__ import annotations

import argparse
import json
import re
import sys
import textwrap
from pathlib import Path


ENV_REFERENCE = re.compile(r"^\$[A-Z][A-Z0-9_]*$")
KEY_VALUE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(?:\s*(.*))?$")
PLACEHOLDER = re.compile(r"<[^>]+>|REPLACE_[A-Z0-9_]+|CHANGEME|TODO", re.IGNORECASE)
SECRET_KEY = re.compile(r"(?:api[_-]?key|token|secret|password)$", re.IGNORECASE)
FLOAT_VALUE = re.compile(r"-?(?:[0-9]+\.[0-9]*|[0-9]*\.[0-9]+)(?:[eE][+-]?[0-9]+)?")
AMBIGUOUS_BOOLEAN = {"yes", "no", "on", "off"}
PROMPT_CONTRACT_START = "```symphony-supervision"
PROMPT_CONTRACT_END = "```"
REQUIRED_PROMPT_DENIALS = {
    "merge",
    "deploy",
    "release",
    "production-effects",
    "credential-changes",
    "public-ingress",
}
UNSAFE_PROMPT_PATTERNS = {
    "merge": re.compile(
        r"\b(?:merg(?:e|ed|es|ing)|land(?:ed|ing|s)?)\b", re.IGNORECASE
    ),
    "deploy": re.compile(r"\bdeploy(?:ed|ing|ment|ments|s)?\b", re.IGNORECASE),
    "release": re.compile(r"\breleas(?:e|ed|es|ing)\b", re.IGNORECASE),
    "production-effects": re.compile(r"\b(?:production|prod)\b", re.IGNORECASE),
    "credential-changes": re.compile(
        r"\b(?:credential|credentials|secret|secrets|token|tokens|api[ -]?key|api[ -]?keys)\b",
        re.IGNORECASE,
    ),
    "public-ingress": re.compile(
        r"\bpublic\s+ingress\b|\bpublic\s+port\b|\bnon-loopback\b|0\.0\.0\.0",
        re.IGNORECASE,
    ),
}
UNSAFE_PROMPT_OVERRIDE = re.compile(
    r"\b(?:bypass|disregard|ignore|override)\b.{0,60}"
    r"\b(?:contract|restriction|safety|supervision)\b",
    re.IGNORECASE | re.DOTALL,
)
ALLOWED_PATHS = {
    "tracker.kind",
    "tracker.provider.api_key",
    "tracker.provider.project_slug",
    "tracker.required_labels",
    "tracker.active_states",
    "tracker.terminal_states",
    "polling.interval_ms",
    "workspace.root",
    "hooks.after_create",
    "hooks.before_run",
    "hooks.before_remove",
    "hooks.timeout_ms",
    "agent.max_concurrent_agents",
    "agent.max_turns",
    "agent.max_retry_backoff_ms",
    "codex.command",
    "codex.approval_policy.reject.sandbox_approval",
    "codex.approval_policy.reject.rules",
    "codex.approval_policy.reject.mcp_elicitations",
    "codex.thread_sandbox",
    "codex.turn_sandbox_policy.type",
    "codex.turn_sandbox_policy.networkAccess",
    "codex.turn_timeout_ms",
    "codex.read_timeout_ms",
    "codex.stall_timeout_ms",
}
ALLOWED_CONTAINERS = {
    ".".join(parts[:index])
    for path in ALLOWED_PATHS
    for parts in [path.split(".")]
    for index in range(1, len(parts))
}


class WorkflowError(ValueError):
    """Report an invalid or unsupported workflow structure."""


def scalar(value: str) -> object:
    value = value.strip()
    if not value:
        raise WorkflowError("a YAML scalar is empty")
    if value[0] in {'"', "'"} or value[-1] in {'"', "'"}:
        if value[0] != value[-1] or value[0] not in {'"', "'"}:
            raise WorkflowError("a quoted YAML scalar is malformed")
        if value[0] == '"':
            try:
                decoded = json.loads(value)
            except json.JSONDecodeError as error:
                raise WorkflowError("a double-quoted YAML scalar is malformed") from error
            if not isinstance(decoded, str):
                raise WorkflowError("a quoted YAML scalar must be a string")
            return decoded
        inner = value[1:-1]
        decoded_parts: list[str] = []
        index = 0
        while index < len(inner):
            if inner[index] != "'":
                decoded_parts.append(inner[index])
                index += 1
                continue
            if index + 1 >= len(inner) or inner[index + 1] != "'":
                raise WorkflowError("a single-quoted YAML scalar is malformed")
            decoded_parts.append("'")
            index += 2
        return "".join(decoded_parts)

    if value[0] in "[{&*!" or value.startswith(("|", ">")):
        raise WorkflowError("the YAML scalar uses an unsupported structure")
    if " #" in value or ": " in value:
        raise WorkflowError("the YAML scalar uses unsupported inline syntax")
    lowered = value.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if lowered in {"null", "~"}:
        return None
    if lowered in AMBIGUOUS_BOOLEAN:
        raise WorkflowError("an ambiguous YAML boolean must use true or false")
    if re.fullmatch(r"-?[0-9]+", value):
        return int(value)
    if FLOAT_VALUE.fullmatch(value):
        return float(value)
    return value


def front_matter(text: str) -> tuple[dict[str, object], str, set[str]]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        raise WorkflowError("the file must start with YAML front matter")
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise WorkflowError("the YAML front matter has no closing delimiter") from error

    values: dict[str, object] = {}
    lists: dict[str, list[object]] = {}
    stack: list[tuple[int, str]] = []
    seen: set[str] = set()
    index = 1
    while index < end:
        raw = lines[index]
        if "\t" in raw[: len(raw) - len(raw.lstrip())]:
            raise WorkflowError("the YAML indentation must not contain tabs")
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            index += 1
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        if indent % 2:
            raise WorkflowError("the YAML indentation must use two-space levels")
        while stack and indent <= stack[-1][0]:
            stack.pop()

        if stripped.startswith("- "):
            if not stack:
                raise WorkflowError("a YAML list item has no parent key")
            if indent != stack[-1][0] + 2:
                raise WorkflowError("a YAML list item has invalid indentation")
            path = stack[-1][1]
            lists.setdefault(path, []).append(scalar(stripped[2:]))
            index += 1
            continue

        if stack and indent != stack[-1][0] + 2:
            raise WorkflowError("a YAML key has invalid indentation")
        if not stack and indent:
            raise WorkflowError("a top-level YAML key must not be indented")

        match = KEY_VALUE.fullmatch(stripped)
        if not match:
            raise WorkflowError("the YAML front matter uses unsupported syntax")
        key, raw_value = match.groups()
        prefix = stack[-1][1] if stack else ""
        path = f"{prefix}.{key}" if prefix else key
        if path in seen:
            raise WorkflowError(f"the YAML front matter repeats {path}")
        seen.add(path)
        raw_value = raw_value or ""

        if raw_value == ">":
            raise WorkflowError("folded YAML block scalars are not supported")
        if raw_value == "|":
            block: list[str] = []
            index += 1
            while index < end:
                block_raw = lines[index]
                block_indent = len(block_raw) - len(block_raw.lstrip(" "))
                if block_raw.strip() and block_indent <= indent:
                    break
                block.append(block_raw)
                index += 1
            values[path] = textwrap.dedent("\n".join(block)).strip()
            continue

        if raw_value:
            values[path] = scalar(raw_value)
        else:
            stack.append((indent, path))
        index += 1

    values.update(lists)
    prompt = "\n".join(lines[end + 1 :]).strip()
    return values, prompt, seen


def prompt_contract_errors(prompt: str, handoff_state: str) -> list[str]:
    errors: list[str] = []
    lines = prompt.splitlines()
    starts = [index for index, line in enumerate(lines) if line.strip() == PROMPT_CONTRACT_START]
    if len(starts) != 1:
        return ["the prompt must contain one symphony-supervision contract"]
    start = starts[0]
    try:
        end = next(
            index
            for index in range(start + 1, len(lines))
            if lines[index].strip() == PROMPT_CONTRACT_END
        )
    except StopIteration:
        return ["the symphony-supervision contract has no closing fence"]

    stop_at: str | None = None
    denials: set[str] = set()
    for raw in lines[start + 1 : end]:
        line = raw.strip()
        if not line:
            continue
        if line.startswith("stop-at:"):
            if stop_at is not None:
                errors.append("the symphony-supervision contract repeats stop-at")
            stop_at = line.removeprefix("stop-at:").strip()
            continue
        if line.startswith("deny:"):
            denial = line.removeprefix("deny:").strip()
            if not re.fullmatch(r"[a-z]+(?:-[a-z]+)*", denial):
                errors.append("the symphony-supervision contract has an invalid denial")
            elif denial in denials:
                errors.append(f"the symphony-supervision contract repeats deny: {denial}")
            else:
                denials.add(denial)
            continue
        errors.append("the symphony-supervision contract has an unsupported control")

    if stop_at != handoff_state:
        errors.append(f"the symphony-supervision contract must stop at {handoff_state}")
    for denial in sorted(REQUIRED_PROMPT_DENIALS - denials):
        errors.append(f"the symphony-supervision contract must deny {denial}")

    remainder = "\n".join(lines[:start] + lines[end + 1 :]).strip()
    if not remainder:
        errors.append("the workflow prompt must include instructions after the contract")
        return errors
    if UNSAFE_PROMPT_OVERRIDE.search(remainder):
        errors.append("the prompt body attempts to override the supervision contract")
    for name, pattern in UNSAFE_PROMPT_PATTERNS.items():
        if pattern.search(remainder):
            errors.append(
                f"the prompt body mentions prohibited {name} behavior outside the contract"
            )
    return errors


def integer_in_range(
    values: dict[str, object], path: str, minimum: int, maximum: int, errors: list[str]
) -> None:
    value = values.get(path)
    if not isinstance(value, int) or isinstance(value, bool) or not minimum <= value <= maximum:
        errors.append(f"{path} must be an integer from {minimum} through {maximum}")


def is_nonempty_string_list(value: object) -> bool:
    return (
        isinstance(value, list)
        and bool(value)
        and all(isinstance(item, str) and bool(item.strip()) for item in value)
    )


def validate(
    path: Path,
    *,
    broker_env: str = "SYMPHONY_GIT_BROKER",
    workspace_env: str = "SYMPHONY_WORKSPACE_ROOT",
    handoff_state: str = "Human Review",
) -> list[str]:
    if not path.is_file():
        return [f"the workflow file does not exist: {path}"]
    try:
        values, prompt, structures = front_matter(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, WorkflowError) as error:
        return [str(error)]

    errors: list[str] = []
    for key in structures:
        if key not in ALLOWED_PATHS and key not in ALLOWED_CONTAINERS:
            errors.append(f"{key} is not permitted in the restricted pilot workflow")
    if values.get("tracker.kind") != "linear":
        errors.append("tracker.kind must be linear for this supervised pilot")

    project_slug = values.get("tracker.provider.project_slug")
    if not isinstance(project_slug, str) or not project_slug.strip():
        errors.append("tracker.provider.project_slug is required")

    labels = values.get("tracker.required_labels")
    if not is_nonempty_string_list(labels):
        errors.append("tracker.required_labels must contain at least one pilot label")

    active = values.get("tracker.active_states")
    terminal = values.get("tracker.terminal_states")
    if not is_nonempty_string_list(active):
        errors.append("tracker.active_states must contain at least one state")
        active = []
    if not is_nonempty_string_list(terminal):
        errors.append("tracker.terminal_states must contain at least one state")
        terminal = []
    active_names = {str(item).strip().casefold() for item in active}
    terminal_names = {str(item).strip().casefold() for item in terminal}
    if active_names & terminal_names:
        errors.append("active and terminal tracker states must not overlap")
    if handoff_state.casefold() in active_names | terminal_names:
        errors.append(
            "the configured handoff state must stay outside active and terminal states"
        )

    if values.get("workspace.root") != f"${workspace_env}":
        errors.append(f"workspace.root must use ${workspace_env}")

    broker = f'"${broker_env}"'
    required_hooks = {
        "hooks.after_create": f"{broker} prepare-workspace",
        "hooks.before_run": f"{broker} verify-workspace",
        "hooks.before_remove": f"{broker} release-workspace",
    }
    for hook, expected in required_hooks.items():
        if values.get(hook) != expected:
            errors.append(f"{hook} must call only the fixed repository broker operation")

    if values.get("agent.max_concurrent_agents") != 1:
        errors.append("agent.max_concurrent_agents must be 1 for the pilot")
    integer_in_range(values, "polling.interval_ms", 5000, 60000, errors)
    integer_in_range(values, "hooks.timeout_ms", 1000, 60000, errors)
    integer_in_range(values, "agent.max_turns", 1, 20, errors)
    integer_in_range(values, "agent.max_retry_backoff_ms", 1000, 300000, errors)

    if values.get("codex.command") != "codex app-server":
        errors.append("codex.command must be codex app-server")
    for path_name in (
        "codex.approval_policy.reject.sandbox_approval",
        "codex.approval_policy.reject.rules",
        "codex.approval_policy.reject.mcp_elicitations",
    ):
        if values.get(path_name) is not True:
            errors.append(f"{path_name} must be true")
    if values.get("codex.thread_sandbox") != "workspace-write":
        errors.append("codex.thread_sandbox must be workspace-write")
    if values.get("codex.turn_sandbox_policy.type") != "workspaceWrite":
        errors.append("codex.turn_sandbox_policy.type must be workspaceWrite")
    if values.get("codex.turn_sandbox_policy.networkAccess") is not False:
        errors.append("codex.turn_sandbox_policy.networkAccess must be false")
    integer_in_range(values, "codex.turn_timeout_ms", 1000, 3600000, errors)
    integer_in_range(values, "codex.read_timeout_ms", 1000, 10000, errors)
    integer_in_range(values, "codex.stall_timeout_ms", 1000, 300000, errors)

    for key, value in values.items():
        if SECRET_KEY.search(key.rsplit(".", 1)[-1]):
            if not isinstance(value, str) or not ENV_REFERENCE.fullmatch(value):
                errors.append(f"{key} must use an environment reference")
        if isinstance(value, str) and PLACEHOLDER.search(value):
            errors.append(f"{key} contains an unfinished placeholder")
        if isinstance(value, list) and any(PLACEHOLDER.search(str(item)) for item in value):
            errors.append(f"{key} contains an unfinished placeholder")

    if not prompt:
        errors.append("the workflow prompt must not be empty")
    else:
        errors.extend(prompt_contract_errors(prompt, handoff_state))
    return errors


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workflow", type=Path)
    parser.add_argument("--broker-env", default="SYMPHONY_GIT_BROKER")
    parser.add_argument("--workspace-env", default="SYMPHONY_WORKSPACE_ROOT")
    parser.add_argument("--handoff-state", default="Human Review")
    args = parser.parse_args()
    errors = validate(
        args.workflow,
        broker_env=args.broker_env,
        workspace_env=args.workspace_env,
        handoff_state=args.handoff_state,
    )
    if errors:
        for error in errors:
            print(f"WORKFLOW safety: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(
        f"WORKFLOW safety: restricted configuration valid ({args.workflow}); "
        "runtime controls remain required"
    )


if __name__ == "__main__":
    main()
