# D-148 Week 6 artifact inventory and replay guide

This directory describes how to inspect and replay the repository-only D-148
publication evidence without starting the application, a workload, or a fault.
It is an operational index, not a replacement for canonical project sources.

Contents:

- `artifact-inventory.json`: required, derived, optional, and unavailable layers.
- `dependency-lock.json`: minimum tools and the validated local versions.
- `replay-guide.md`: commands, expected outputs, failure meanings, and boundaries.
- `candidate-metadata.json`: evidence and authorization state.
- `sha256-manifest.json`: integrity record for the five document payloads.

Quick verification from the repository root:

```powershell
python p0-env\scripts\verify-d148-week6-artifact-package.py --worktree --full-replay
```

After these files are committed, omit `--worktree` to verify canonical Git blob
bytes. Add `--source-root C:\path\to\papers` only when replaying the five
optional Week 5 PDF hashes.

Receipt-level replay is intentionally unavailable: zero of 21 expected
receipt/SHA-manifest pairs are present. The verifier must report this boundary;
it must not locate, synthesize, or restore missing bundles.
