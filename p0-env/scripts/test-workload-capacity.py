#!/usr/bin/env python3
"""Regression tests for D-030 selection without live infrastructure."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SELECTOR = ROOT / "p0-env/scripts/select-workload-capacity.py"


def write(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value), encoding="utf-8")


def invoke(root: Path, cpu20: float, ratio20: float) -> subprocess.CompletedProcess[str]:
    analyses, assessments = [], []
    for users, rate, cpu in ((10, 1.0, 12.0), (15, 1.45, 19.0), (20, ratio20, cpu20)):
        analysis = root / f"a-{users}.json"
        assessment = root / f"s-{users}.json"
        write(analysis, {"users": users, "workload_profile_id": f"profile-{users}", "frontend_user_server_span_rate_per_second": rate, "recommendationservice_cpu_mean_millicores": cpu, "failure_manifestation": None, "latency_violation_max_streak": 0, "error_violation_max_streak": 0})
        write(assessment, {"users": users, "status": "valid_capacity_evidence"})
        analyses.append(str(analysis)); assessments.append(str(assessment))
    return subprocess.run([sys.executable, str(SELECTOR), "--analysis", *analyses, "--assessment", *assessments, "--output", str(root / "result.json")], text=True, capture_output=True)


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    positive = invoke(root, 24.0, 1.7)
    assert positive.returncode == 0, positive.stderr
    assert json.loads((root / "result.json").read_text())["selected_users"] == 20
    print("workload_capacity_highest_candidate_fixture=passed")

with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    fallback = invoke(root, 26.0, 1.7)
    assert fallback.returncode == 0, fallback.stderr
    assert json.loads((root / "result.json").read_text())["selected_users"] == 15
    print("workload_capacity_fallback_fixture=passed")

with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    rejected = invoke(root, 26.0, 1.1)
    # 15 remains eligible in this fixture; force its CPU above the gate directly.
    analysis15 = root / "a-15.json"
    value = json.loads(analysis15.read_text())
    value["recommendationservice_cpu_mean_millicores"] = 26.0
    write(analysis15, value)
    rerun = subprocess.run([sys.executable, str(SELECTOR), "--analysis", str(root / "a-10.json"), str(root / "a-15.json"), str(root / "a-20.json"), "--assessment", str(root / "s-10.json"), str(root / "s-15.json"), str(root / "s-20.json"), "--output", str(root / "result-none.json")], text=True, capture_output=True)
    assert rerun.returncode == 2
    assert json.loads((root / "result-none.json").read_text())["selected_users"] is None
    print("workload_capacity_no_selection_fixture=passed")
