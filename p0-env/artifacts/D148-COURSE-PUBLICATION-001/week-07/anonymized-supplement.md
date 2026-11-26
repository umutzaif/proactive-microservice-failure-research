# Anonymized Artifact Supplement Candidate

> **Status.** Adviser-review candidate only. This supplement is not
> submission-ready, publicly archived, or associated with a DOI. The candidate
> text is anonymized, but repository history and the export package are not yet anonymized.

## 1. Scope and evidence boundary

This supplement supports the manuscript's bounded CPU-fault case study. The
tracked evidence contains 35 unique attempts: 21 valid runs (six normal and 15
fault) and 14 invalid attempts. None of the 15 valid fault runs crossed the
frozen manifestation rule. Receipt-level replay is unavailable because 0/21
expected receipt pairs are present. Accordingly, the package supports
tracked-evidence verification, descriptive recomputation, and manuscript
consistency checks; it does not support a claim of receipt-complete replay,
runtime reproduction, model evaluation, or external validity.

## 2. Artifact layers

The candidate artifact separates four layers so that one layer cannot silently
stand in for another:

1. **Tracked evidence:** repository records and evidence bytes used for the
   35-attempt accounting.
2. **Derived publication data:** the Week 3 tables and figures regenerated from
   the pinned source revision.
3. **Audits and claim boundaries:** Week 4 and Week 5 checks that bind numbers,
   captions, and admissible claims.
4. **Replay and manuscript checks:** Week 6 package verification and the Week 7
   draft verifier.

The Week 3 generator is pinned to source revision
`0ecb6011189c0a47b46019ec1d626ae7043e19e0`. Generated text uses LF line
endings and is compared with Git blob bytes, avoiding platform-dependent
working-tree normalization.

## 3. Requirements

- Git, for revision-pinned blob access;
- Python 3, using only the standard library for the Week 7 verifier;
- PowerShell, for the repository's existing audit scripts;
- a clean source checkout containing the candidate package.

No Kubernetes cluster, fault injector, workload generator, or external service
is required for tracked-evidence verification. Runtime execution is outside the
scope and is not authorized by this package.

## 4. Verification commands

From the repository root, run:

```powershell
python p0-env\scripts\verify-d148-week7-draft.py
python p0-env\scripts\verify-d148-week6-artifact-package.py --worktree --full-replay
```

The first command checks manuscript structure, exact evidence values,
contribution boundaries, citations, metadata, and obvious anonymity leaks. The
second command independently checks the layered artifact and regenerates the
Week 3 publication candidates from the pinned revision.

Expected success markers are:

```text
week7_draft_verification=passed
week6_full_replay=passed
week6_artifact_package_verification=passed
runtime_authorized=false
```

Receipt completeness is a deliberately failing boundary, not a missing success
criterion. Any check that requires receipt replay must stop with:

```text
d148_cpu_receipt_replay_not_ready
```

## 5. Anonymization checklist for a later export

Before creating a submission package, a separate export must be reviewed for:

- Git history, commit authors, names, and email addresses;
- institution, laboratory, course, mentor, or employer identifiers;
- absolute local paths, host names, user names, and machine-specific metadata;
- repository, issue, pull-request, or organization URLs that identify authors;
- document properties, PDF metadata, comments, and hidden revision data;
- acknowledgements, funding text, and self-citations that defeat double-blind
  review.

Run IDs and configuration IDs are scientific identifiers and should normally be
retained for traceability, but they must be reviewed for accidental
deanonymization before export. The current repository is an authoring source,
not the anonymous distribution artifact.

## 6. Reviewer-oriented interpretation

A successful verification establishes that the manuscript accurately reports
the tracked repository evidence and stays within the frozen claim boundary. It
does not establish that the original runtime can be recreated, that every
historical receipt exists, that CPU faults generally fail to manifest, or that
an early-warning model has been validated. Those stronger propositions remain
outside the available evidence.
