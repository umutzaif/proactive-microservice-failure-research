#!/usr/bin/env python3
"""Prove canonical JSON hashing is stable across checkout line endings."""

import importlib.util
import tempfile
from pathlib import Path


def load_module(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    module = importlib.util.module_from_spec(spec)
    assert spec.loader
    spec.loader.exec_module(module)
    return module


def main() -> int:
    finalizer = load_module("invalid_finalizer", "finalize-invalid-run-artifacts.py")
    verifier = load_module("invalid_verifier", "verify-invalid-run-receipt.py")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        lf = root / "lf.json"
        crlf = root / "crlf.json"
        changed = root / "changed.json"
        lf.write_bytes(b'{\n  "b": 2,\n  "a": 1\n}\n')
        crlf.write_bytes(b'{\r\n  "a": 1,\r\n  "b": 2\r\n}\r\n')
        changed.write_bytes(b'{"a":1,"b":3}')
        expected = finalizer.canonical_json_digest(lf)
        assert expected == finalizer.canonical_json_digest(crlf)
        assert expected == verifier.canonical_json_digest(lf)
        assert expected == verifier.canonical_json_digest(crlf)
        assert expected != finalizer.canonical_json_digest(changed)
    print("invalid_receipt_canonical_json_portability=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
