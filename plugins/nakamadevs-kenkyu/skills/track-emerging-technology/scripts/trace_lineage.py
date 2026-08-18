#!/usr/bin/env python3
"""Trace upstream or downstream dependencies in a generated topic lineage graph."""

import argparse
import json
from collections import defaultdict, deque
from pathlib import Path


def walk(start: str, adjacency: dict[str, list[tuple[str, str]]]) -> list[dict]:
    queue = deque([(start, 0)])
    visited = {start}
    result = []
    while queue:
        current, distance = queue.popleft()
        for neighbor, relationship in adjacency.get(current, []):
            if neighbor in visited:
                continue
            visited.add(neighbor)
            result.append({"id": neighbor, "distance": distance + 1, "relationship": relationship})
            queue.append((neighbor, distance + 1))
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("topic", type=Path)
    parser.add_argument("--id", required=True, dest="node_id")
    parser.add_argument("--direction", choices=("upstream", "downstream", "both"), default="both")
    args = parser.parse_args()

    lineage_path = args.topic.resolve() / "data" / "products" / "lineage.json"
    lineage = json.loads(lineage_path.read_text(encoding="utf-8"))
    nodes = {node["id"]: node for node in lineage["nodes"]}
    if args.node_id not in nodes:
        raise SystemExit(f"unknown node id: {args.node_id}")
    forward, reverse = defaultdict(list), defaultdict(list)
    for edge in lineage["edges"]:
        forward[edge["from"]].append((edge["to"], edge["relationship"]))
        reverse[edge["to"]].append((edge["from"], edge["relationship"]))

    output = {"start": nodes[args.node_id]}
    if args.direction in {"upstream", "both"}:
        output["upstream"] = [{**item, "type":nodes[item["id"]]["type"], "label":nodes[item["id"]]["label"]} for item in walk(args.node_id, reverse)]
    if args.direction in {"downstream", "both"}:
        output["downstream"] = [{**item, "type":nodes[item["id"]]["type"], "label":nodes[item["id"]]["label"]} for item in walk(args.node_id, forward)]
    print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
