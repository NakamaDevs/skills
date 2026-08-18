#!/usr/bin/env python3
"""Build and validate deterministic observation-to-output lineage for a topic."""

import argparse
import json
from pathlib import Path


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def build_lineage(topic: Path) -> dict:
    manifest = load(topic / "data" / "manifest.json")
    observations = load(topic / "data" / "raw" / "observations.json").get("observations", [])
    sources = load(topic / "data" / "curated" / "sources.json").get("sources", [])
    claims = load(topic / "data" / "curated" / "claims.json").get("claims", [])
    evidence = load(topic / "data" / "curated" / "evidence-map.json").get("evidence", [])
    artifacts = load(topic / "data" / "products" / "artifacts.json").get("artifacts", [])
    errors = []

    def indexed(items: list[dict], kind: str) -> dict[str, dict]:
        result = {}
        for item in items:
            item_id = item.get("id")
            if not item_id:
                errors.append(f"{kind}: missing id")
            elif item_id in result:
                errors.append(f"{kind}: duplicate id {item_id}")
            else:
                result[item_id] = item
        return result

    obs_by_id = indexed(observations, "observation")
    source_by_id = indexed(sources, "source")
    claim_by_id = indexed(claims, "claim")
    evidence_by_id = indexed(evidence, "evidence")
    artifact_by_id = indexed(artifacts, "artifact")
    edges = []

    required_fields = {
        "observation": (observations, {"id", "source_id", "captured_at", "channel", "signal"}),
        "source": (sources, {"id", "title", "url", "publisher", "retrieved_at", "source_type", "confidence", "supports"}),
        "claim": (claims, {"id", "kind", "statement", "status", "confidence", "evidence_ids", "counterevidence_ids"}),
        "evidence": (evidence, {"id", "source_id", "claim_id", "relationship", "strength", "rationale"}),
        "artifact": (artifacts, {"id", "path", "type", "claim_ids", "source_ids", "derived_from"}),
    }
    for kind, (items, required) in required_fields.items():
        for item in items:
            missing = required - item.keys()
            if missing:
                errors.append(f"{kind} {item.get('id', '<unknown>')}: missing {sorted(missing)}")

    observed_sources = set()
    for observation in observations:
        source_id = observation.get("source_id")
        if source_id not in source_by_id:
            errors.append(f"{observation.get('id')}: unknown source {source_id}")
        else:
            observed_sources.add(source_id)
            edges.append({"from": observation["id"], "to": source_id, "relationship": "normalizes-to"})
    for source_id in source_by_id.keys() - observed_sources:
        errors.append(f"source has no raw observation: {source_id}")

    mapped_evidence = set()
    for item in evidence:
        source_id, claim_id = item.get("source_id"), item.get("claim_id")
        if source_id not in source_by_id:
            errors.append(f"{item.get('id')}: unknown source {source_id}")
        if claim_id not in claim_by_id:
            errors.append(f"{item.get('id')}: unknown claim {claim_id}")
        if item.get("relationship") not in {"supports", "contradicts", "context"}:
            errors.append(f"{item.get('id')}: invalid relationship")
        mapped_evidence.add(item.get("id"))
        edges.append({"id": item.get("id"), "from": source_id, "to": claim_id, "relationship": item.get("relationship"), "strength": item.get("strength")})

    for claim in claims:
        declared = set(claim.get("evidence_ids", [])) | set(claim.get("counterevidence_ids", []))
        unknown = declared - evidence_by_id.keys()
        if unknown:
            errors.append(f"{claim['id']}: unknown evidence {sorted(unknown)}")
        actual = {item["id"] for item in evidence if item.get("claim_id") == claim["id"]}
        if declared != actual:
            errors.append(f"{claim['id']}: declared evidence does not match evidence map")
        contradictions = {item["id"] for item in evidence if item.get("claim_id") == claim["id"] and item.get("relationship") == "contradicts"}
        if contradictions != set(claim.get("counterevidence_ids", [])):
            errors.append(f"{claim['id']}: contradiction IDs do not match counterevidence_ids")

    used_claims = set()
    for artifact in artifacts:
        if not (topic / artifact.get("path", "")).is_file():
            errors.append(f"{artifact.get('id')}: missing artifact path {artifact.get('path')}")
        for claim_id in artifact.get("claim_ids", []):
            if claim_id not in claim_by_id:
                errors.append(f"{artifact['id']}: unknown claim {claim_id}")
            else:
                used_claims.add(claim_id)
                edges.append({"from": claim_id, "to": artifact["id"], "relationship": "materializes-in"})
        for source_id in artifact.get("source_ids", []):
            if source_id not in source_by_id:
                errors.append(f"{artifact['id']}: unknown source {source_id}")
            else:
                edges.append({"from": source_id, "to": artifact["id"], "relationship": "cited-directly-by"})
        for parent_id in artifact.get("derived_from", []):
            if parent_id not in artifact_by_id:
                errors.append(f"{artifact['id']}: unknown upstream artifact {parent_id}")
            else:
                edges.append({"from": parent_id, "to": artifact["id"], "relationship": "derived-into"})
    for claim_id in claim_by_id.keys() - used_claims:
        errors.append(f"claim is not used by an artifact: {claim_id}")

    visiting, visited = set(), set()
    def visit(artifact_id: str) -> None:
        if artifact_id in visiting:
            errors.append(f"artifact dependency cycle at {artifact_id}")
            return
        if artifact_id in visited or artifact_id not in artifact_by_id:
            return
        visiting.add(artifact_id)
        for parent_id in artifact_by_id[artifact_id].get("derived_from", []):
            visit(parent_id)
        visiting.remove(artifact_id)
        visited.add(artifact_id)
    for artifact_id in artifact_by_id:
        visit(artifact_id)

    if manifest.get("topic") != topic.name:
        errors.append("manifest topic does not match directory name")
    if errors:
        raise ValueError("\n".join(errors))

    nodes = []
    nodes.extend({"id": item["id"], "type": "observation", "label": item["signal"]} for item in observations)
    nodes.extend({"id": item["id"], "type": "source", "label": item["title"]} for item in sources)
    nodes.extend({"id": item["id"], "type": "claim", "label": item["statement"]} for item in claims)
    nodes.extend({"id": item["id"], "type": "artifact", "label": item["path"]} for item in artifacts)
    return {
        "schema_version": "1.0",
        "topic": topic.name,
        "generated_from_updated_at": manifest.get("updated_at"),
        "nodes": nodes,
        "edges": edges,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("topic", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    topic = args.topic.resolve()
    output = topic / "data" / "products" / "lineage.json"
    generated = build_lineage(topic)
    if args.check:
        if not output.is_file() or load(output) != generated:
            raise SystemExit("lineage is missing or stale; run build_lineage.py without --check")
        print(f"OK: {len(generated['nodes'])} nodes, {len(generated['edges'])} edges")
        return
    output.write_text(json.dumps(generated, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {output}: {len(generated['nodes'])} nodes, {len(generated['edges'])} edges")


if __name__ == "__main__":
    main()
