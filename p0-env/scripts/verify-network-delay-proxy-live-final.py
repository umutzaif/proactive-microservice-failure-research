#!/usr/bin/env python3
"""Offline verifier for the live proxy gate final hash receipt."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def verify(repo: Path, receipt_path: Path) -> dict:
    receipt = json.loads(receipt_path.read_text(encoding="utf-8-sig"))
    failures = []
    if receipt.get("run_id") != "ob-network-proxy-live-001": failures.append("run_id_mismatch")
    if receipt.get("scientific_fault_started") is not False: failures.append("scientific_fault_flag_invalid")
    if receipt.get("file_count") != len(receipt.get("files", [])): failures.append("file_count_mismatch")
    for item in receipt.get("files", []):
        path = repo / item["path"]
        if not path.is_file():
            failures.append(f"missing:{item['path']}")
            continue
        if path.stat().st_size != item["size_bytes"]: failures.append(f"size:{item['path']}")
        if digest(path) != item["sha256"]: failures.append(f"sha256:{item['path']}")
    return {"verification_passed": not failures, "verified_file_count": len(receipt.get("files", [])) - len([x for x in failures if x.startswith("missing:")]), "failures": failures}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--receipt", type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.repo_root.resolve(), args.receipt.resolve())
    print(json.dumps(result, sort_keys=True))
    return 0 if result["verification_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
