#!/usr/bin/env python3
"""Validate restricted Symphony WORKFLOW.md front matter."""

from __future__ import annotations

import argparse
import re
import sys
import textwrap
from pathlib import Path


ENV_REFERENCE = re.compile(r"^\$[A-Z][A-Z0-9_]*$")
KEY_VALUE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(?:\s*(.*))?$")
PLACEHOLDER = re.compile(r"<[^>]+>|REPLACE_[A-Z0-9_]+|CHANGEME|TODO", re.IGNORECASE)
SECRET_KEY = re.compile(r"(?:api[_-]?key|token|secret|password)$", re.IGNORECASE)
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


class WorkflowError(ValueError):
    """Report an invalid or unsupported workflow structure."""


def scalar(value: str) -> object:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        value = value[1:-1]
    lowered = value.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if re.fullmatch(r"-?[0-9]+", value):
        return int(value)
    return value


def front_matter(text: str) -> tuple[dict[str, object], str]:
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
        while stack and indent <= stack[-1][0]:
            stack.pop()

        if stripped.startswith("- "):
            if not stack:
                raise WorkflowError("a YAML list item has no parent key")
            path = stack[-1][1]
            lists.setdefault(path, []).append(scalar(stripped[2:]))
            index += 1
            continue

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

        if raw_value in {"|", ">"}:
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
    return values, prompt


def integer_in_range(
    values: dict[str, object], path: str, minimum: int, maximum: int, errors: list[str]
) -> None:
    value = values.get(path)
    if not isinstance(value, int) or isinstance(value, bool) or not minimum <= value <= maximum:
        errors.append(f"{path} must be an integer from {minimum} through {maximum}")


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
        values, prompt = front_matter(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, WorkflowError) as error:
        return [str(error)]

    errors: list[str] = []
    for key in values:
        if key not in ALLOWED_PATHS:
            errors.append(f"{key} is not permitted in the restricted pilot workflow")
    if values.get("tracker.kind") != "linear":
        errors.append("tracker.kind must be linear for this supervised pilot")

    project_slug = values.get("tracker.provider.project_slug")
    if not isinstance(project_slug, str) or not project_slug.strip():
        errors.append("tracker.provider.project_slug is required")

    labels = values.get("tracker.required_labels")
    if not isinstance(labels, list) or not labels or any(not str(item).strip() for item in labels):
        errors.append("tracker.required_labels must contain at least one pilot label")

    active = values.get("tracker.active_states")
    terminal = values.get("tracker.terminal_states")
    if not isinstance(active, list) or not active:
        errors.append("tracker.active_states must contain at least one state")
        active = []
    if not isinstance(terminal, list) or not terminal:
        errors.append("tracker.terminal_states must contain at least one state")
        terminal = []
    active_names = {str(item).strip().casefold() for item in active}
    terminal_names = {str(item).strip().casefold() for item in terminal}
    if active_names & terminal_names:
        errors.append("active and terminal tracker states must not overlap")
    if handoff_state.casefold() in active_names | terminal_names:
        errors.append("the human-review handoff state must stay outside active and terminal states")

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
