#!/usr/bin/env python3
"""Build the deterministic D-148 Week 9 audience-review package."""

from __future__ import annotations

import argparse
import hashlib
import io
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "p0-env/artifacts/D148-COURSE-PUBLICATION-001"
WEEK9 = BASE / "week-09"
FORBIDDEN = (b"asus-pc", b"c:\\users\\", b"github.com/umutzaif", b"@gmail.com", b"@outlook.com")

FILES = {
    "README.md": WEEK9 / "README.md",
    "candidate-metadata.json": WEEK9 / "candidate-metadata.json",
    "review/adversarial-review.md": WEEK9 / "adversarial-review.md",
    "review/technical-method-addendum.md": WEEK9 / "technical-method-addendum.md",
    "publication/manuscript.pdf": WEEK9 / "output/pdf/d148-manuscript-audience-revised-candidate.pdf",
    "presentation/defense-presentation.pptx": WEEK9 / "output/pptx/d148-defense-presentation-audience-revised-candidate.pptx",
    "summary/turkish-summary.md": BASE / "week-08/turkish-summary.md",
    "artifact/d148-anonymized-artifact-candidate.zip": BASE / "week-08/output/archive/d148-anonymized-artifact-candidate.zip",
    "manuscript/references.bib": BASE / "week-07/references.bib",
}

NOTICE = """D-148 Week 9 audience review package

Status: adviser and technical review candidate; not submission-ready.
Evidence boundary: 35 attempts, 21 valid, 14 invalid, 15 valid fault,
0 manifestations. Receipt replay remains unavailable at 0/21.

The revised manuscript adds method detail from existing versioned contracts.
It changes no experiment, threshold, label, denominator or conclusion.
""".encode("utf-8")


def scan(name: str, data: bytes) -> None:
    candidates = [(name, data)]
    if name.endswith((".pptx", ".zip")):
        with zipfile.ZipFile(io.BytesIO(data)) as nested:
            candidates.extend((f"{name}!{item}", nested.read(item)) for item in nested.namelist())
    for candidate_name, candidate_data in candidates:
        hits = [token.decode("ascii", errors="replace") for token in FORBIDDEN if token in candidate_data.lower()]
        if hits:
            raise SystemExit(f"direct_identifier_leak:{candidate_name}:{hits}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        raise SystemExit(f"output_exists:{output}")

    payloads = {"NOTICE.txt": NOTICE}
    for name, source in FILES.items():
        if not source.is_file():
            raise SystemExit(f"missing_source:{source}")
        payloads[name] = source.read_bytes()
    for name, data in payloads.items():
        scan(name, data)

    payloads["CHECKSUMS.sha256"] = "".join(
        f"{hashlib.sha256(data).hexdigest()}  {name}\n"
        for name, data in sorted(payloads.items())
    ).encode("utf-8")

    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(payloads.items()):
            info = zipfile.ZipInfo(name, date_time=(2000, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            info.create_system = 3
            archive.writestr(info, data)

    print(f"week9_review_package_created={output}")
    print(f"payloads={len(payloads)}")
    print(f"sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
