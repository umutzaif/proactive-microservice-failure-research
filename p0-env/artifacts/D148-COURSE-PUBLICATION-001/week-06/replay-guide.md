# D-148 repository-only replay guide

## 1. What this replay can and cannot establish

This replay can independently recompute the tracked-evidence accounting,
regenerate the Week 3 candidate tables and figure from a pinned Git revision,
check the Week 4 manuscript numbers and claim boundaries, and check the Week 5
source identities and contribution boundaries. It uses no live service,
Kubernetes cluster, workload generator, fault injector, network access, model,
or LLM API.

It cannot establish receipt-level replay because the current repository has
zero of the 21 expected final-receipt/SHA-manifest pairs. It also cannot establish
feature-window completeness, model performance, causal effects, external
validity, or publication readiness.

## 2. Prerequisites

Use a clean checkout containing this package. Required tools are Git 2.30 or
newer, Python 3.10 or newer with only the standard library, and PowerShell 5.1
or newer. Run commands from the repository root. No environment service should
be started.

For exact artifact comparisons, compare generated files with Git blob bytes,
not platform-converted checkout bytes. On Windows, `core.autocrlf` can convert
CSV or Markdown line endings even when scientific content is identical.

## 3. Quick tracked-evidence replay

Run:

```powershell
.\p0-env\scripts\audit-d148-cpu-publication-evidence.ps1
python p0-env\scripts\verify-d148-week4-manuscript.py
python p0-env\scripts\verify-d148-week5-related-work.py
```

Expected boundaries include:

```text
attempts=35 valid=21 invalid=14
manifestations=0/15
receipt_replay_ready=false ready=0 missing=21
week4_manuscript_verification=passed
week5_related_work_verification=passed
runtime_authorized=false
```

The Week 5 command without `--source-root` verifies the source ledger and DOI
identities but does not claim that local PDF bytes were rechecked.

## 4. Exact pinned Week 3 replay

The original Week 3 scientific inputs are pinned to:

```text
0ecb6011189c0a47b46019ec1d626ae7043e19e0
```

Generate into an empty temporary directory:

```powershell
$replayRoot = Join-Path $env:TEMP "d148-week3-replay"
New-Item -ItemType Directory -Path $replayRoot
python p0-env\scripts\generate-d148-week3-publication-candidates.py `
  --source-revision 0ecb6011189c0a47b46019ec1d626ae7043e19e0 `
  --output-root $replayRoot
```

The generator must produce ten files: nine payloads plus one manifest. It must
refuse a non-empty output directory. Use the Week 6 verifier for portable
Git-blob comparison and safe temporary cleanup:

```powershell
python p0-env\scripts\verify-d148-week6-artifact-package.py --full-replay
```

During uncommitted development only, add `--worktree`. A released or reviewed
revision should use the default Git-blob mode.

## 5. Optional PDF source replay

If the five inspected Week 5 PDFs are locally available, run:

```powershell
python p0-env\scripts\verify-d148-week6-artifact-package.py `
  --full-replay `
  --source-root C:\path\to\papers
```

Expected output includes `pdf_source_hashes=passed;count=5`. The PDFs are not
redistributed in this artifact; their DOI and expected SHA-256 identities are in
the Week 5 source ledger.

## 6. Receipt replay is an expected fail-closed stop

The strict command is:

```powershell
.\p0-env\scripts\audit-d148-cpu-publication-evidence.ps1 -RequireReceiptReplay
```

In the current artifact it must fail with:

```text
d148_cpu_receipt_replay_not_ready
```

This failure means C148-05 remains held. It does not mean the tracked registry,
reports, descriptive tables, or 0/15 manifestation count failed. Do not search,
copy, restore, or reconstruct receipt bundles unless the user separately
authorizes a source-bound operation and the supplied bundle is independently
hash-verified.

## 7. Failure interpretation

- `registry_count_mismatch`: stop; do not edit counts to fit the manuscript.
- `aggregate_mismatch`: stop; inspect accepted membership and tracked evidence.
- `manifest mismatch`: distinguish Git-blob bytes from checkout line endings;
  never bypass a real blob mismatch by normalizing after hashing.
- Week 4 missing-boundary failure: narrow the manuscript; do not weaken the
  verifier merely to pass prose.
- Week 5 DOI/PDF mismatch: stop using the affected source claim until identity
  is resolved.
- Receipt strict failure: expected at 0/21; do not convert it into success.

## 8. Independent falsification questions

The package is falsified or must be narrowed if a deterministic recount differs
from 35 total, 21 valid, and 14 invalid; if any of the 15 valid fault contracts
has a non-null frozen-SLO manifestation; if one of the six descriptive cells
changes; if an invalid attempt enters an outcome denominator; or if a claimed
Git-blob manifest does not match its payloads.
