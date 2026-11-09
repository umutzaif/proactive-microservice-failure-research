#!/usr/bin/env python3
"""Verify D-148 Week 5 source identities and contribution boundaries."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WEEK5 = ROOT / "p0-env" / "artifacts" / "D148-COURSE-PUBLICATION-001" / "week-05"
RELATED = WEEK5 / "related-work.md"
COMPARISON = WEEK5 / "contribution-comparison.md"
LEDGER = WEEK5 / "source-ledger.json"
METADATA = WEEK5 / "candidate-metadata.json"

EXPECTED_SOURCES = {
    "zheng2024mulan": ("10.1145/3589334.3645442", "mulan.pdf"),
    "zhang2026galr": ("10.3390/electronics15010243", "electronics-15-00243-v2.pdf"),
    "cornacchia2025promise": ("10.1145/3725783.3764388", "a2.pdf"),
    "yu2026proactive": ("10.3389/fcomp.2026.1783945", "fcomp-8-1783945.pdf"),
    "zhang2025aiops": ("10.1145/3746635", "3746635.pdf"),
}


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def normalized(text: str) -> str:
    return " ".join(text.lower().split())


def require(text: str, label: str, phrases: list[str]) -> None:
    compact = normalized(text)
    for phrase in phrases:
        if normalized(phrase) not in compact:
            fail(f"{label} is missing required boundary: {phrase!r}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source-root",
        type=Path,
        help="optional directory containing the five inspected PDF files",
    )
    args = parser.parse_args()

    for path in (RELATED, COMPARISON, LEDGER, METADATA):
        if not path.is_file():
            fail(f"missing Week 5 file: {path.relative_to(ROOT)}")

    related = RELATED.read_text(encoding="utf-8")
    comparison = COMPARISON.read_text(encoding="utf-8")
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    metadata = json.loads(METADATA.read_text(encoding="utf-8"))

    sources = ledger.get("sources", [])
    if len(sources) != 5:
        fail(f"expected five source records, found {len(sources)}")
    by_key = {source.get("key"): source for source in sources}
    if set(by_key) != set(EXPECTED_SOURCES):
        fail(f"unexpected source keys: {sorted(by_key)}")
    for key, (doi, filename) in EXPECTED_SOURCES.items():
        source = by_key[key]
        if source.get("doi") != doi or source.get("file") != filename:
            fail(f"source identity mismatch for {key}")
        if len(source.get("sha256", "")) != 64:
            fail(f"invalid SHA-256 field for {key}")
        if doi not in related:
            fail(f"related work is missing DOI {doi}")

    require(
        related,
        "related work",
        [
            "not a systematic review",
            "root-cause localization rather than prospective SLO warning",
            "cannot claim novelty merely from combining metrics, logs, or graph structure",
            "directly rules out an originality claim based only on",
            "D-148 contains no LLM evaluation",
            "zero eligible positive lead-time examples",
            "60 independent positive incidents plus 60 independent normal controls",
            "receipt layer remains incomplete at zero of 21 expected pairs",
            "does not compete on model accuracy",
        ],
    )
    require(
        comparison,
        "contribution comparison",
        [
            "W5-C01 — Fault actuation is not outcome manifestation",
            "W5-C02 — Fail-closed run accounting changes the evidential denominator",
            "W5-C03 — Reproducibility has separable layers",
            "35 total, 21 valid, and 14 invalid",
            "0/21",
            "D-147 is an incomplete 3/6",
            "New model, causal, or external-validity contributions require new prospective decisions",
        ],
    )

    if metadata.get("artifact_id") != "D148-WEEK5-RELATED-WORK-001":
        fail("unexpected artifact_id")
    if metadata.get("status") != "not_submission_ready":
        fail("Week 5 must remain not_submission_ready")
    if metadata.get("runtime_authorized") is not False:
        fail("runtime_authorized must be false")
    if metadata.get("source_count") != 5:
        fail("metadata source_count must equal five")
    if metadata.get("receipt_replay") != {"available_pairs": 0, "expected_pairs": 21}:
        fail("receipt replay boundary changed")
    if metadata.get("source_week4_manifest_sha256") != (
        "a4b66055da53a3213be2a538c7b1c332209dc41384b5ee6db3b532ea0341cde2"
    ):
        fail("Week 4 source-manifest hash mismatch")

    prohibited_affirmations = [
        "we outperform mulan",
        "we outperform galr",
        "our trained model",
        "our statistically significant",
        "we demonstrate external generalization",
        "complete receipt-level replay was achieved",
    ]
    related_compact = normalized(related)
    for phrase in prohibited_affirmations:
        if phrase in related_compact:
            fail(f"prohibited affirmative claim found: {phrase!r}")

    if args.source_root is not None:
        source_root = args.source_root.resolve()
        if not source_root.is_dir():
            fail(f"source root is not a directory: {source_root}")
        for source in sources:
            path = source_root / source["file"]
            if not path.is_file():
                fail(f"missing PDF source: {path}")
            actual = sha256(path)
            if actual != source["sha256"]:
                fail(f"PDF hash mismatch: {source['file']}")
        print("pdf_source_hashes=passed;count=5")
    else:
        print("pdf_source_hashes=not_requested;use_--source-root_for_replay")

    print("week5_related_work_verification=passed")
    print("source_count=5;doi_identity=passed")
    print("contributions=W5-C01,W5-C02,W5-C03")
    print("receipt_pairs=0_of_21;runtime_authorized=false")


if __name__ == "__main__":
    main()
