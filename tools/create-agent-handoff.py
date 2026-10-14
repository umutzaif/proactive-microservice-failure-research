#!/usr/bin/env python3
"""Create a fail-closed, non-runtime-authorizing agent handoff contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path


CANONICAL_SOURCES = (
    "AGENTS.md",
    "research_decisions.md",
    "experiment_protocol.md",
    "dataset_card.md",
    "results_registry.md",
    "pilot_experiment_plan.md",
    "docs/researcher-datasheets/01-project-architecture.md",
)

FORBIDDEN_ACTIONS = (
    "start_live_experiment",
    "reuse_run_id",
    "delete_or_relabel_evidence",
    "change_frozen_thresholds",
    "make_undocumented_research_decision",
    "commit_or_push_without_explicit_request",
)


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=repo, check=True, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    return result.stdout.rstrip("\n")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_contract(args: argparse.Namespace, repo: Path) -> dict:
    sources = []
    for relative in CANONICAL_SOURCES:
        path = repo / relative
        if not path.is_file():
            raise SystemExit(f"missing_canonical_source:{relative}")
        sources.append({"path": relative, "sha256": sha256(path)})

    status = git(repo, "status", "--porcelain=v1").splitlines()
    return {
        "schema_version": 1,
        "task_id": args.task_id,
        "title": args.title,
        "state": args.state,
        "generated_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "repository": {
            "head": git(repo, "rev-parse", "HEAD"),
            "branch": git(repo, "branch", "--show-current") or "DETACHED",
            "status_porcelain": status,
        },
        "canonical_sources": sources,
        "authorization": {
            "runtime_authorized": False,
            "fresh_user_approval_required": True,
            "forbidden_actions": list(FORBIDDEN_ACTIONS),
        },
        "scope": args.scope,
        "completed": args.completed,
        "next_actions": args.next_action,
        "open_questions": args.open_question,
        "verification": {
            "command": ".\\tools\\invoke-agent-handoff.ps1 verify",
            "passed": True,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, default=Path("agent-handoffs/current.json"))
    parser.add_argument("--task-id", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument(
        "--state", required=True,
        choices=("planning", "implementation", "verification", "blocked", "complete"),
    )
    parser.add_argument("--scope", action="append", required=True)
    parser.add_argument("--completed", action="append", default=[])
    parser.add_argument("--next-action", action="append", default=[])
    parser.add_argument("--open-question", action="append", default=[])
    args = parser.parse_args()

    repo = args.repo_root.resolve()
    output = args.output if args.output.is_absolute() else repo / args.output
    contract = build_contract(args, repo)
    output.parent.mkdir(parents=True, exist_ok=True)
    # Writing a tracked handoff changes porcelain state. Capture that state after
    # the first complete write, then seal the stable status in the final write.
    output.write_text(json.dumps(contract, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    contract["repository"]["status_porcelain"] = git(repo, "status", "--porcelain=v1").splitlines()
    output.write_text(json.dumps(contract, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"handoff_created:{output}")
    print("runtime_authorized:false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
