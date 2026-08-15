#!/usr/bin/env python3
"""Create an immutable hash receipt for the live proxy gate evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path


RUN_ID = "ob-network-proxy-live-001"


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def roots(repo: Path) -> list[Path]:
    return [
        repo / "p0-env/artifacts/P2-NETWORK-DELAY-PROXY-LIVE-001",
        repo / "p0-env/artifacts/runs" / RUN_ID,
        repo / "p0-env/artifacts/derived" / RUN_ID,
        repo / "p0-env/artifacts/telemetry" / RUN_ID,
    ]


def build(repo: Path) -> dict:
    files = []
    for root in roots(repo):
        if not root.is_dir():
            raise ValueError(f"evidence_root_missing:{root}")
        for path in sorted(item for item in root.rglob("*") if item.is_file()):
            relative = path.relative_to(repo).as_posix()
            files.append({"path": relative, "size_bytes": path.stat().st_size, "sha256": digest(path)})
    if not files:
        raise ValueError("no_evidence_files")
    revision = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()
    return {"schema_version": 1, "receipt_kind": "network-delay-proxy-live-final", "gate_id": "P2-NETWORK-DELAY-PROXY-LIVE-001", "run_id": RUN_ID, "code_revision": revision, "created_utc": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"), "scientific_fault_started": False, "file_count": len(files), "files": files}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    repo, output = args.repo_root.resolve(), args.output.resolve()
    if output.exists():
        raise ValueError("receipt_already_exists")
    result = build(repo)
    output.parent.mkdir(parents=True, exist_ok=False)
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for root in roots(repo):
        for path in root.rglob("*"):
            if path.is_file():
                os.chmod(path, path.stat().st_mode & ~0o222)
    os.chmod(output, output.stat().st_mode & ~0o222)
    print(json.dumps({"receipt": str(output), "file_count": result["file_count"]}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
