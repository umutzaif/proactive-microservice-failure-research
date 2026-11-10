# D-148 Week 8 adviser-review deliverables

Week 8 converts the verified Week 7 content into reviewable delivery formats:

- `output/pdf/d148-manuscript-adviser-review-candidate.pdf`: anonymous,
  four-page, two-column manuscript layout candidate;
- `output/pptx/d148-defense-presentation-candidate.pptx`: editable Turkish
  eight-slide defense presentation candidate;
- `turkish-summary.md`: Turkish technical and beginner-facing summary;
- `output/archive/d148-anonymized-artifact-candidate.zip`: deterministic,
  history-free artifact archive candidate.

These files are adviser-review candidates, not submission-ready releases.
Receipt replay remains unavailable at 0/21. The archive intentionally excludes
Git history, canonical repository governance files, raw tracked evidence and
absent receipt bundles. It therefore demonstrates the bounded publication
layer, not complete reconstruction of the original runtime.

Verify from the repository root:

```powershell
python p0-env\scripts\verify-d148-week8-deliverables.py
```

No file in this directory authorizes runtime execution, receipt recovery,
model training, upload, submission or publication.
