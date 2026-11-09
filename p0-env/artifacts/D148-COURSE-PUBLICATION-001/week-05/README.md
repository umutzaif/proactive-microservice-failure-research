# D-148 Week 5 related-work and contribution comparison

This directory contains repository-only candidate text for a future course
paper. It is derived from the binding literature assessment, five locally
inspected publications, and the frozen D-148 claim boundaries. It is not a new
systematic review, a model result, or a submission-ready package.

Files:

- `related-work.md`: task-aware comparison with the nearest literature.
- `contribution-comparison.md`: admissible and prohibited contribution claims.
- `source-ledger.json`: bibliographic identifiers and inspected-PDF hashes.
- `candidate-metadata.json`: scope and authorization state.
- `sha256-manifest.json`: integrity record for the four document payloads.

Verify the text from the repository root:

```powershell
python p0-env\scripts\verify-d148-week5-related-work.py
```

When the five local PDFs are available, also verify their identities:

```powershell
python p0-env\scripts\verify-d148-week5-related-work.py --source-root C:\path\to\papers
```

The verifier checks source identities, task distinctions, required D-148
limitations, and selected prohibited overclaims. It does not replace a formal
systematic-review protocol or peer review.
