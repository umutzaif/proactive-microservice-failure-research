#!/usr/bin/env python3
"""Deterministic positive and negative fixtures for agent handoff safety."""

from __future__ import annotations

import copy
import importlib.util
import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERIFIER = ROOT / "tools/verify-agent-handoff.py"
spec = importlib.util.spec_from_file_location("handoff_verifier", VERIFIER)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


def expect_error(contract: dict, repo: Path, expected: str) -> None:
    errors = module.verify(contract, repo, check_git=False)
    if not any(error.startswith(expected) for error in errors):
        raise AssertionError(f"negative_fixture_not_rejected:{expected}:{errors}")


with tempfile.TemporaryDirectory(prefix="makale-agent-handoff-") as temp:
    fixture = Path(temp)
    for relative in module.REQUIRED_SOURCES:
        target = fixture / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes((ROOT / relative).read_bytes())

    output = fixture / "agent-handoffs/current.json"
    subprocess.run(
        [
            sys.executable, str(ROOT / "tools/create-agent-handoff.py"),
            "--repo-root", str(ROOT), "--output", str(output),
            "--task-id", "AGENT-EVAL-001", "--title", "Agent eval fixture",
            "--state", "verification", "--scope", "Static fixture only",
        ],
        check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    contract = json.loads(output.read_text(encoding="utf-8"))
    # Repoint hashes at the byte-identical fixture sources; Git checks are intentionally off.
    errors = module.verify(contract, fixture, check_git=False)
    if errors:
        raise AssertionError(f"positive_fixture_failed:{errors}")
    print("agent_handoff_positive_fixture=passed")

    mutated = copy.deepcopy(contract)
    mutated["authorization"]["runtime_authorized"] = True
    expect_error(mutated, fixture, "handoff_cannot_authorize_runtime")
    print("agent_handoff_runtime_authorization_negative_fixture=passed")

    mutated = copy.deepcopy(contract)
    mutated["authorization"]["forbidden_actions"].remove("reuse_run_id")
    expect_error(mutated, fixture, "missing_forbidden_actions")
    print("agent_handoff_missing_guard_negative_fixture=passed")

    source = fixture / "research_decisions.md"
    source.write_bytes(source.read_bytes() + b"\nfixture drift\n")
    expect_error(contract, fixture, "canonical_source_drift:research_decisions.md")
    print("agent_handoff_source_drift_negative_fixture=passed")
