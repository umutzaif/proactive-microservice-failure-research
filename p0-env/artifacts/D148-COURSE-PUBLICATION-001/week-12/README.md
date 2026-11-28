# D148 Week 12 Venue Neutral Academic Output

Week 12 consolidates the verified Week 7 manuscript and Week 9 technical method detail into one venue-neutral academic paper. The package is intended for adviser, jury, course, or later venue-adaptation review without binding the scientific narrative to a conference template.

## Files

- `academic-manuscript.md` is the human-readable manuscript source.
- `academic-readiness-matrix.md` records the academic acceptance tests and remaining falsifiers.
- `references.bib` contains the scholarly references used by the manuscript.
- `hizli-rehber-tr.md` explains the result and remaining boundaries for the user in Turkish.
- `candidate-metadata.json` records scope and authority.
- `output/docx/d148-venue-neutral-academic-paper.docx` is the editable paper.
- `output/pdf/d148-venue-neutral-academic-paper.pdf` is the rendered review paper.
- `visual-qa.json` binds the inspected PDF and eight rendered-page hashes without retaining QA PNG intermediates.
- `sha256-manifest.json` binds the release payloads after generation.

The package preserves 35 attempts, 21 valid runs, 14 invalid attempts, 15 valid fault runs, 0/15 frozen-SLO manifestations, and 0/21 receipt pairs. It changes no experiment, run identity, threshold, label, Dataset entry, or runtime authority.

## Build and verify

Use the bundled Codex Python runtime resolved by the desktop workspace dependency loader.

```text
python p0-env/scripts/build-d148-week12-academic-output.py --renderer <absolute-render_docx.py>
python p0-env/scripts/verify-d148-week12-academic-output.py
```

On a Windows host without LibreOffice, `--docx-only` may be followed by a native Microsoft Word PDF export and bundled Poppler page rendering. After the PDF and every `tmp/rendered-pages/page-*.png` file has been visually inspected, `--finalize-existing-pdf --visual-inspection-passed` binds the output and page hashes. The temporary PNGs are then removed. This host-specific presentation fallback does not change scientific values or replace the source manuscript.

The DOCX must additionally be rendered to page PNG files and every page visually inspected before delivery. Academic-review readiness does not imply external-submission readiness.
