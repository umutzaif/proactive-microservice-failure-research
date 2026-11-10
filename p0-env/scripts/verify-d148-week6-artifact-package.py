#!/usr/bin/env python3
"""Verify the D-148 repository-only artifact inventory and replay chain."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


WEEK3_SOURCE = "0ecb6011189c0a47b46019ec1d626ae7043e19e0"
ARTIFACT_ROOT = Path("p0-env/artifacts/D148-COURSE-PUBLICATION-001")


def fail(message: str) -> None:
    print(f"FAIL:{message}", file=sys.stderr)
    raise SystemExit(1)


def run(command: list[str], *, cwd: Path, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        check=check,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def git_bytes(repo: Path, revision: str, path: str) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo), "show", f"{revision}:{path}"],
        check=True,
        capture_output=True,
    )
    return result.stdout


def artifact_bytes(repo: Path, revision: str, path: str, worktree: bool) -> bytes:
    changed = False
    if worktree:
        status = subprocess.run(
            ["git", "-C", str(repo), "status", "--porcelain=v1", "--untracked-files=all", "--", path],
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        ).stdout
        changed = bool(status.strip())
    if changed:
        candidate = repo / path
        if not candidate.is_file():
            fail(f"missing_worktree_file:{path}")
        return candidate.read_bytes()
    try:
        return git_bytes(repo, revision, path)
    except subprocess.CalledProcessError as error:
        fail(f"missing_git_blob:{revision}:{path}:{error.returncode}")


def sha256(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def load_json(repo: Path, revision: str, path: str, worktree: bool) -> dict:
    return json.loads(artifact_bytes(repo, revision, path, worktree).decode("utf-8"))


def verify_manifest(repo: Path, revision: str, week: str, worktree: bool) -> int:
    base = (ARTIFACT_ROOT / week).as_posix()
    manifest_path = f"{base}/sha256-manifest.json"
    manifest = load_json(repo, revision, manifest_path, worktree)
    rows = manifest.get("files", manifest.get("payloads"))
    if not isinstance(rows, list):
        fail(f"invalid_manifest_rows:{week}")
    expected_count = manifest.get("payload_count", len(rows))
    if expected_count != len(rows):
        fail(f"manifest_count_mismatch:{week}:{expected_count}:{len(rows)}")
    for row in rows:
        path = f"{base}/{row['path']}"
        payload = artifact_bytes(repo, revision, path, worktree)
        if len(payload) != row["bytes"] or sha256(payload) != row["sha256"]:
            fail(f"manifest_payload_mismatch:{week}:{row['path']}")
    return len(rows)


def validate_inventory(repo: Path, revision: str, worktree: bool) -> dict:
    path = (ARTIFACT_ROOT / "week-06/artifact-inventory.json").as_posix()
    inventory = load_json(repo, revision, path, worktree)
    if inventory.get("artifact_id") != "D148-WEEK6-ARTIFACT-REPLAY-001":
        fail("unexpected_inventory_artifact_id")
    if inventory.get("week3_source_revision") != WEEK3_SOURCE:
        fail("week3_source_revision_mismatch")
    groups = {group["id"]: group for group in inventory.get("groups", [])}
    expected_ids = {
        "canonical-governance",
        "frozen-experiment-contract",
        "tracked-cpu-run-reports",
        "valid-fault-contracts",
        "week3-derived-package",
        "week4-derived-package",
        "week5-derived-package",
        "verification-tools",
        "week5-pdf-sources",
        "cpu-final-receipts",
    }
    if set(groups) != expected_ids:
        fail(f"inventory_group_mismatch:{sorted(groups)}")
    for group in groups.values():
        paths = group.get("paths", [])
        if paths and len(paths) != group.get("expected_count"):
            fail(f"inventory_path_count_mismatch:{group['id']}")
        for item in paths:
            artifact_bytes(repo, revision, item, worktree)
    receipt = groups["cpu-final-receipts"]
    if receipt.get("availability") != "unavailable_fail_closed":
        fail("receipt_layer_not_fail_closed")
    if receipt.get("available_pair_count") != 0 or receipt.get("expected_pair_count") != 21:
        fail("receipt_pair_boundary_changed")
    return inventory


def powershell_command() -> str:
    for candidate in ("pwsh", "powershell"):
        resolved = shutil.which(candidate)
        if resolved:
            return resolved
    fail("powershell_not_found")


def verify_audit(repo: Path) -> None:
    shell = powershell_command()
    script = repo / "p0-env/scripts/audit-d148-cpu-publication-evidence.ps1"
    positive = run([shell, "-NoProfile", "-File", str(script)], cwd=repo)
    required = [
        "d148_cpu_tracked_evidence_audit=passed attempts=35 valid=21 invalid=14",
        "manifestations=0/15",
        "d148_cpu_receipt_replay_ready=false ready=0 missing=21",
    ]
    combined = positive.stdout + positive.stderr
    for text in required:
        if text not in combined:
            fail(f"audit_output_missing:{text}")
    strict = run(
        [shell, "-NoProfile", "-File", str(script), "-RequireReceiptReplay"],
        cwd=repo,
        check=False,
    )
    if strict.returncode == 0:
        fail("receipt_strict_mode_unexpected_success")
    if "d148_cpu_receipt_replay_not_ready" not in strict.stdout + strict.stderr:
        fail("receipt_strict_mode_wrong_failure")


def verify_week3_replay(repo: Path, revision: str, worktree: bool) -> None:
    generator = repo / "p0-env/scripts/generate-d148-week3-publication-candidates.py"
    base = (ARTIFACT_ROOT / "week-03").as_posix()
    with tempfile.TemporaryDirectory(prefix="d148-week6-replay-") as directory:
        run(
            [
                sys.executable,
                str(generator),
                "--repo-root",
                str(repo),
                "--source-revision",
                WEEK3_SOURCE,
                "--output-root",
                directory,
            ],
            cwd=repo,
        )
        generated = sorted(path.name for path in Path(directory).iterdir() if path.is_file())
        if worktree:
            expected = sorted(path.name for path in (repo / base).iterdir() if path.is_file())
        else:
            tree = run(
                ["git", "-C", str(repo), "ls-tree", "-r", "--name-only", revision, base],
                cwd=repo,
            ).stdout.splitlines()
            expected = sorted(Path(path).name for path in tree)
        if generated != expected:
            fail(f"week3_replay_file_set_mismatch:{generated}:{expected}")
        for name in generated:
            actual = (Path(directory) / name).read_bytes()
            expected_bytes = artifact_bytes(repo, revision, f"{base}/{name}", worktree)
            if actual != expected_bytes:
                fail(f"week3_replay_byte_mismatch:{name}")


def verify_text_layers(repo: Path, source_root: Path | None) -> None:
    week4 = run(
        [sys.executable, str(repo / "p0-env/scripts/verify-d148-week4-manuscript.py")],
        cwd=repo,
    )
    if "week4_manuscript_verification=passed" not in week4.stdout:
        fail("week4_verifier_missing_pass")
    command = [sys.executable, str(repo / "p0-env/scripts/verify-d148-week5-related-work.py")]
    if source_root is not None:
        command.extend(["--source-root", str(source_root)])
    week5 = run(command, cwd=repo)
    if "week5_related_work_verification=passed" not in week5.stdout:
        fail("week5_verifier_missing_pass")
    if source_root is not None and "pdf_source_hashes=passed;count=5" not in week5.stdout:
        fail("week5_pdf_hash_replay_missing_pass")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--revision", default="HEAD")
    parser.add_argument(
        "--worktree",
        action="store_true",
        help="verify uncommitted worktree bytes; reviewed releases should use Git blob mode",
    )
    parser.add_argument("--full-replay", action="store_true")
    parser.add_argument("--source-root", type=Path)
    args = parser.parse_args()
    repo = args.repo_root.resolve()

    validate_inventory(repo, args.revision, args.worktree)
    counts = {
        week: verify_manifest(repo, args.revision, week, args.worktree)
        for week in ("week-03", "week-04", "week-05", "week-06")
    }
    metadata = load_json(
        repo,
        args.revision,
        (ARTIFACT_ROOT / "week-06/candidate-metadata.json").as_posix(),
        args.worktree,
    )
    if metadata.get("runtime_authorized") is not False:
        fail("runtime_authorized_must_be_false")
    if metadata.get("receipt_replay", {}).get("status") != "unavailable_fail_closed":
        fail("metadata_receipt_boundary_changed")

    if args.full_replay:
        verify_audit(repo)
        verify_week3_replay(repo, args.revision, args.worktree)
        verify_text_layers(repo, args.source_root.resolve() if args.source_root else None)
        print("week6_full_replay=passed")

    print("week6_artifact_package_verification=passed")
    print(
        "payloads="
        + ",".join(f"{week}:{count}" for week, count in sorted(counts.items()))
    )
    print("tracked_evidence=35_attempts,21_valid,14_invalid,0_of_15_manifestations")
    print("receipt_pairs=0_of_21;receipt_replay=unavailable_fail_closed")
    print("runtime_authorized=false")


if __name__ == "__main__":
    main()
