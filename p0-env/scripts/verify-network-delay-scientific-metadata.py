#!/usr/bin/env python3
"""Fail-closed verifier for P2 network-delay scientific metadata."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any


def load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def seconds(start: str, end: str) -> float:
    a = datetime.fromisoformat(start.replace("Z", "+00:00"))
    b = datetime.fromisoformat(end.replace("Z", "+00:00"))
    return (b - a).total_seconds()


def verify(repo: Path, metadata_path: Path) -> dict[str, Any]:
    metadata = load(metadata_path)
    checks = []
    def check(name: str, passed: bool, observed: Any) -> None:
        checks.append({"name": name, "passed": bool(passed), "observed": observed})
    check("identity", metadata.get("run_id") == "ob-netdelay-15u-001" and metadata.get("experiment_id") == "P2-NETWORK-DELAY-001" and metadata.get("fault_class") == "network_delay", {key: metadata.get(key) for key in ("run_id", "experiment_id", "fault_class")})
    check("target", metadata.get("target_service") == "recommendationservice" and metadata.get("target_edge") == "recommendationservice->productcatalogservice", {"service": metadata.get("target_service"), "edge": metadata.get("target_edge")})
    check("workload", metadata.get("workload_profile_id") == "ob-second-15u-1r-v1" and metadata.get("random_seed") == 1, {"profile": metadata.get("workload_profile_id"), "seed": metadata.get("random_seed")})
    resolved = {}
    for name, path_key, hash_key in (("fault_profile", "fault_profile_path", "fault_profile_sha256"), ("slo", "slo_path", "slo_sha256"), ("workload", "workload_profile_path", "workload_profile_sha256"), ("effect", "injector_evidence_path", "injector_evidence_sha256"), ("manifestation", "manifestation_evidence_path", "manifestation_evidence_sha256")):
        raw = metadata.get(path_key, "")
        path = (repo / raw).resolve()
        inside = str(path).lower().startswith(str(repo.resolve()).lower() + "\\")
        passed = bool(raw) and not Path(raw).is_absolute() and inside and path.is_file() and digest(path) == metadata.get(hash_key)
        check(f"{name}_path_and_hash", passed, raw)
        if passed:
            resolved[name] = path
    if "fault_profile" in resolved:
        profile = load(resolved["fault_profile"])
        check("profile_contract", profile["profile_id"] == metadata["fault_profile"] and profile["scientific_run_id"] == metadata["run_id"] and profile["workload_profile_id"] == metadata["workload_profile_id"] and profile["injector"]["steady_latency_ms"] == 750 and profile["physical_effect"]["minimum_steady_minus_baseline_median_ms"] == 500, profile["profile_id"])
    if "effect" in resolved:
        effect = load(resolved["effect"])
        check("effect_identity", effect["run_id"] == metadata["run_id"], effect["run_id"])
        check("effect_claim", bool(effect["physical_effect_verified"]) == bool(metadata["valid_run"]) or not metadata["valid_run"], {"effect": effect["physical_effect_verified"], "valid": metadata["valid_run"]})
        check("cleanup_and_ramp", effect["cleanup_verified"] is True and effect["ramp_contract_verified"] is True, {"cleanup": effect["cleanup_verified"], "ramp": effect["ramp_contract_verified"]})
        check("first_symptom", effect.get("first_symptom_utc") == metadata.get("first_symptom_utc"), {"effect": effect.get("first_symptom_utc"), "metadata": metadata.get("first_symptom_utc")})
    if "manifestation" in resolved:
        manifestation = load(resolved["manifestation"])
        check("manifestation_identity", manifestation["run_id"] == metadata["run_id"] and manifestation["slo_id"] == metadata["slo_id"], {"run": manifestation["run_id"], "slo": manifestation["slo_id"]})
        check("manifestation_claim", manifestation.get("failure_manifestation") == metadata.get("failure_manifestation"), {"evidence": manifestation.get("failure_manifestation"), "metadata": metadata.get("failure_manifestation")})
    phases = metadata.get("phases", {})
    try:
        durations = {"warmup": seconds(phases["warmup_start_utc"], phases["warmup_end_utc"]), "baseline": seconds(phases["normal_baseline_start_utc"], phases["normal_baseline_end_utc"]), "ramp": seconds(phases["injection_start_utc"], phases["ramp_end_utc"]), "steady": seconds(phases["ramp_end_utc"], phases["injection_end_utc"]), "cooldown": seconds(phases["cooldown_start_utc"], phases["cooldown_end_utc"])}
        check("phase_durations", durations["warmup"] >= 300 and durations["baseline"] >= 300 and durations["ramp"] >= 120 and durations["steady"] >= 300 and durations["cooldown"] >= 300, durations)
    except (KeyError, ValueError) as error:
        check("phase_durations", False, str(error))
    valid_run = metadata.get("valid_run") is True
    host = metadata.get("host_health", {})
    host_names = ("whea_event_17_delta", "kernel_power_41_delta", "bugcheck_delta")
    host_complete = all(type(host.get(name)) is int and host.get(name) >= 0 for name in host_names)
    host_pass = host_complete and all(host.get(name) == 0 for name in host_names)
    check("host_evidence_complete", host_complete, host)
    check("host_claim_consistency", host_pass if valid_run else True, {"valid_run": valid_run, "all_zero": host_pass})
    runtime = metadata.get("runtime_evidence", {})
    runtime_names = ("baseline_stable", "steady_stable", "cooldown_stable", "cleanup_verified", "rollback_verified")
    runtime_complete = type(runtime.get("tracked_deployment_count")) is int and all(type(runtime.get(name)) is bool for name in runtime_names) and runtime.get("target_stability") in ("passed", "failed")
    runtime_pass = runtime_complete and runtime.get("tracked_deployment_count") == 15 and all(runtime.get(name) is True for name in runtime_names) and runtime.get("target_stability") == "passed"
    check("runtime_evidence_complete", runtime_complete, runtime)
    check("runtime_claim_consistency", runtime_pass if valid_run else True, {"valid_run": valid_run, "all_passed": runtime_pass})
    actual_revision = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()
    check("code_revision", metadata.get("code_revision") == actual_revision, {"metadata": metadata.get("code_revision"), "actual": actual_revision})
    return {"schema_version": 1, "verification_kind": "network-delay-scientific-metadata", "verification_passed": all(item["passed"] for item in checks), "scientific_valid": bool(metadata.get("valid_run")), "checks": checks}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--metadata", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = verify(args.repo_root.resolve(), args.metadata.resolve())
    if args.output:
        args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"verification_passed": result["verification_passed"], "scientific_valid": result["scientific_valid"], "checks": len(result["checks"])}, sort_keys=True))
    return 0 if result["verification_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
