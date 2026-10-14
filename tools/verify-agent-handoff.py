#!/usr/bin/env python3
"""Verify an agent handoff against the live repository; fail closed on drift."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path


REQUIRED_SOURCES = {
    "AGENTS.md",
    "research_decisions.md",
    "experiment_protocol.md",
    "dataset_card.md",
    "results_registry.md",
    "pilot_experiment_plan.md",
    "docs/researcher-datasheets/01-project-architecture.md",
}
REQUIRED_FORBIDDEN = {
    "start_live_experiment",
    "reuse_run_id",
    "delete_or_relabel_evidence",
    "change_frozen_thresholds",
    "make_undocumented_research_decision",
}
STATES = {"planning", "implementation", "verification", "blocked", "complete"}


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=repo, check=True, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    return result.stdout.rstrip("\n")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify(contract: dict, repo: Path, check_git: bool = True) -> list[str]:
    errors: list[str] = []
    required_top = {
        "schema_version", "task_id", "title", "state", "generated_utc",
        "repository", "canonical_sources", "authorization", "scope",
        "completed", "next_actions", "open_questions", "verification",
    }
    missing = required_top - set(contract)
    if missing:
        errors.append("missing_top_level:" + ",".join(sorted(missing)))
        return errors
    if contract["schema_version"] != 1:
        errors.append("unsupported_schema_version")
    if not re.fullmatch(r"[A-Z0-9][A-Z0-9._-]{2,79}", str(contract["task_id"])):
        errors.append("invalid_task_id")
    if contract["state"] not in STATES:
        errors.append("invalid_state")
    if not isinstance(contract["scope"], list) or not contract["scope"]:
        errors.append("empty_scope")

    authorization = contract.get("authorization", {})
    if authorization.get("runtime_authorized") is not False:
        errors.append("handoff_cannot_authorize_runtime")
    if authorization.get("fresh_user_approval_required") is not True:
        errors.append("fresh_user_approval_must_be_required")
    forbidden = set(authorization.get("forbidden_actions", []))
    absent_forbidden = REQUIRED_FORBIDDEN - forbidden
    if absent_forbidden:
        errors.append("missing_forbidden_actions:" + ",".join(sorted(absent_forbidden)))

    entries = contract.get("canonical_sources", [])
    paths = [entry.get("path") for entry in entries if isinstance(entry, dict)]
    if len(paths) != len(set(paths)):
        errors.append("duplicate_canonical_source")
    absent_sources = REQUIRED_SOURCES - set(paths)
    if absent_sources:
        errors.append("missing_canonical_sources:" + ",".join(sorted(absent_sources)))
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != {"path", "sha256"}:
            errors.append("invalid_canonical_source_entry")
            continue
        relative = entry["path"]
        path = (repo / relative).resolve()
        try:
            path.relative_to(repo)
        except ValueError:
            errors.append(f"source_outside_repository:{relative}")
            continue
        if not path.is_file():
            errors.append(f"missing_canonical_source:{relative}")
        elif sha256(path) != entry["sha256"]:
            errors.append(f"canonical_source_drift:{relative}")

    verification = contract.get("verification", {})
    if verification != {"command": ".\\tools\\invoke-agent-handoff.ps1 verify", "passed": True}:
        errors.append("invalid_verification_contract")

    if check_git:
        repository = contract.get("repository", {})
        if repository.get("head") != git(repo, "rev-parse", "HEAD"):
            errors.append("git_head_drift")
        current_status = git(repo, "status", "--porcelain=v1").splitlines()
        if repository.get("status_porcelain") != current_status:
            errors.append("git_status_drift")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--handoff", type=Path, default=Path("agent-handoffs/current.json"))
    parser.add_argument("--no-git-check", action="store_true", help="Fixture testing only")
    args = parser.parse_args()
    repo = args.repo_root.resolve()
    handoff = args.handoff if args.handoff.is_absolute() else repo / args.handoff
    try:
        contract = json.loads(handoff.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"handoff_read_failed:{exc}")
        return 1
    errors = verify(contract, repo, check_git=not args.no_git_check)
    if errors:
        for error in errors:
            print(f"FAIL:{error}")
        return 1
    print("agent_handoff_verification=passed")
    print(f"task_id={contract['task_id']}")
    print("runtime_authorized=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
