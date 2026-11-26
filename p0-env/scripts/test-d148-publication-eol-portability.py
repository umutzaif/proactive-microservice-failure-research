#!/usr/bin/env python3
"""Exercise D-148 text-payload EOL normalization without runtime services."""

from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def load(name: str, relative: str):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"module_load_failed:{relative}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    week7 = load("verify_week7", "p0-env/scripts/verify-d148-week7-draft.py")
    week8 = load("verify_week8", "p0-env/scripts/verify-d148-week8-deliverables.py")
    week9 = load("verify_week9", "p0-env/scripts/verify-d148-week9-audience-package.py")
    week10 = load("verify_week10", "p0-env/scripts/verify-d148-week10-release.py")
    build8 = load("build_week8", "p0-env/scripts/build-d148-week8-artifact-archive.py")
    build9 = load("build_week9", "p0-env/scripts/build-d148-week9-review-package.py")

    with tempfile.TemporaryDirectory(prefix="d148-eol-") as temporary:
        sample = Path(temporary) / "sample.md"
        sample.write_bytes(b"alpha\r\nbeta\r\n")
        expected_lf = b"alpha\nbeta\n"
        for module in (week7, week8, week9, week10):
            if module.portable_payload_bytes(sample) != expected_lf:
                raise RuntimeError(f"verifier_eol_normalization_failed:{module.__name__}")
        if build9.portable_source_bytes(sample) != expected_lf:
            raise RuntimeError("week9_builder_eol_normalization_failed")
        if build8.portable_source_bytes("README.md", sample) != expected_lf:
            raise RuntimeError("week8_builder_lf_normalization_failed")
        legacy_name = "verification/verify-d148-week4-manuscript.py"
        if build8.portable_source_bytes(legacy_name, sample) != b"alpha\r\nbeta\r\n":
            raise RuntimeError("week8_legacy_crlf_compatibility_failed")

    print("d148_publication_eol_portability=passed")
    print("text_manifest_boundary=lf_normalized")
    print("week8_legacy_crlf_members=2_preserved")
    print("runtime=none")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
