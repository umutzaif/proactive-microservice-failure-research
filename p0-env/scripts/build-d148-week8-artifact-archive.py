#!/usr/bin/env python3
"""Create a deterministic, history-free D-148 Week 8 artifact archive candidate."""

from __future__ import annotations

import argparse
import hashlib
import io
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "p0-env" / "artifacts" / "D148-COURSE-PUBLICATION-001"
WEEK8 = BASE / "week-08"
FORBIDDEN = (b"asus-pc", b"c:\\users\\", b"github.com/umutzaif", b"@gmail.com", b"@outlook.com")

FILES = {
    "README.md": WEEK8 / "README.md",
    "turkish-summary.md": WEEK8 / "turkish-summary.md",
    "candidate-metadata.json": WEEK8 / "candidate-metadata.json",
    "publication/manuscript.pdf": WEEK8 / "output/pdf/d148-manuscript-adviser-review-candidate.pdf",
    "presentation/defense-presentation.pptx": WEEK8 / "output/pptx/d148-defense-presentation-candidate.pptx",
    "manuscript/manuscript-draft.md": BASE / "week-07/manuscript-draft.md",
    "manuscript/anonymized-supplement.md": BASE / "week-07/anonymized-supplement.md",
    "manuscript/references.bib": BASE / "week-07/references.bib",
    "manuscript/candidate-metadata.json": BASE / "week-07/candidate-metadata.json",
    "manuscript/sha256-manifest.json": BASE / "week-07/sha256-manifest.json",
    "replay/artifact-inventory.json": BASE / "week-06/artifact-inventory.json",
    "replay/dependency-lock.json": BASE / "week-06/dependency-lock.json",
    "replay/replay-guide.md": BASE / "week-06/replay-guide.md",
    "data/figure-01-physical-effect.svg": BASE / "week-03/figure-01-physical-effect.svg",
    "data/table-01-run-accounting.csv": BASE / "week-03/table-01-run-accounting.csv",
    "data/table-01-run-accounting.md": BASE / "week-03/table-01-run-accounting.md",
    "data/table-02-physical-effect.csv": BASE / "week-03/table-02-physical-effect.csv",
    "data/table-02-physical-effect.md": BASE / "week-03/table-02-physical-effect.md",
    "data/table-03-valid-fault-runs.csv": BASE / "week-03/table-03-valid-fault-runs.csv",
    "verification/verify-d148-week4-manuscript.py": ROOT / "p0-env/scripts/verify-d148-week4-manuscript.py",
    "verification/verify-d148-week5-related-work.py": ROOT / "p0-env/scripts/verify-d148-week5-related-work.py",
    "verification/verify-d148-week6-artifact-package.py": ROOT / "p0-env/scripts/verify-d148-week6-artifact-package.py",
}

NOTICE = """D-148 anonymized artifact candidate

Status: adviser-review candidate; not submission-ready.
Evidence: 35 attempts, 21 valid, 14 invalid, 15 valid fault, 0 manifestations.
Receipt replay: 0/21 expected pairs; unavailable and fail-closed.

This archive contains the bounded publication layer and selected verification
tools. It excludes Git history, canonical governance files, raw tracked run
evidence and absent receipt bundles. Use it to review presentation consistency,
not to claim complete runtime reconstruction or external validity.
""".encode("utf-8")


def scan(name: str, data: bytes) -> None:
    candidates = [(name, data)]
    if name.endswith((".pptx", ".zip")):
        with zipfile.ZipFile(io.BytesIO(data)) as nested:
            candidates.extend((f"{name}!{item}", nested.read(item)) for item in nested.namelist())
    for candidate_name, candidate_data in candidates:
        lowered = candidate_data.lower()
        hits = [token.decode("ascii", errors="replace") for token in FORBIDDEN if token in lowered]
        if hits:
            raise SystemExit(f"direct_identifier_leak:{candidate_name}:{hits}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        raise SystemExit(f"output_exists:{output}")

    payloads: dict[str, bytes] = {"NOTICE.txt": NOTICE}
    for archive_name, source in FILES.items():
        if not source.is_file():
            raise SystemExit(f"missing_source:{source}")
        payloads[archive_name] = source.read_bytes()
    for name, data in payloads.items():
        scan(name, data)

    checksums = "".join(
        f"{hashlib.sha256(data).hexdigest()}  {name}\n"
        for name, data in sorted(payloads.items())
    ).encode("utf-8")
    payloads["CHECKSUMS.sha256"] = checksums

    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(payloads.items()):
            info = zipfile.ZipInfo(name, date_time=(2000, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            info.create_system = 3
            archive.writestr(info, data)

    print(f"week8_artifact_archive_created={output}")
    print(f"payloads={len(payloads)}")
    print(f"sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
