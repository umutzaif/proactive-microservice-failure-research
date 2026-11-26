# D-148 Week 11 EASE Adaptation Preparation

This directory is a decision-support package for venue adaptation. It is not a
submission package and it is not evidence that any message, upload,
registration, payment, or publication action occurred.

Contents:

- `ease-2027-gap-analysis.md`: requirement-to-evidence and action matrix for
  the EASE 2027 Reproducibility and Negative Results track;
- `ease-2027-organizer-query-draft.md`: an unsent, identity-free draft asking
  the organizers to clarify remote author presentation;
- `candidate-metadata.json`: machine-readable status and authority boundary;
- `sha256-manifest.json`: portable hashes for these four text payloads.

The package is derived from the canonical D-148, D-150, and D-151 records,
the sealed Week-9 review candidates, and the official EASE 2027 RENE call as
inspected on 2026-11-26. Official venue terms are time-sensitive and must be
rechecked before adaptation, submission, registration, or payment.

Verification from the repository root:

```powershell
python p0-env\scripts\verify-d148-week11-ease-preparation.py
```

Expected terminal markers include:

```text
week11_ease_preparation_verification=passed
remote_author_presentation=unconfirmed
communication_sent=false
submission_ready=false
runtime_authorized=false
```
