# Candidate Methods, Results, and Threats to Validity

> **Status.** Repository-only candidate prose derived from tracked evidence. It
> is not submission-ready. The tracked-evidence layer is reproducible, but the
> current worktree contains zero of the 21 expected final-receipt/SHA-manifest
> pairs, so receipt-level replay and claim C148-05 remain unavailable.

## 3. Methods

### 3.1 Study objective and research questions

This bounded same-host study examined whether CPU stress applied to the
`recommendationservice` produced the intended physical actuation and whether
that actuation manifested under a frozen service-level objective (SLO). Three
questions governed the analysis: RQ1 asked whether the requested low, medium,
and high CPU profiles produced distinguishable physical effects; RQ2 asked
whether valid fault runs manifested the frozen SLO and yielded positive warning
lead time; and RQ3 asked which parts of the result could be reproduced from the
tracked repository evidence. The questions were fixed before this publication
synthesis and were not expanded to support a more favourable interpretation.

### 3.2 System, workloads, and fault profiles

The evidence came from the local Online Boutique deployment and was collected
on the same host. Two versioned workload profiles were used: 10 virtual users
and 15 virtual users, each with one Locust worker. The CPU fault ladder used
three versioned profiles labelled low, medium, and high. This manuscript does
not treat those labels as direct measurements; the reported physical-effect
statistics come from the tracked run evidence. Host-specific scheduling,
resource contention, and the single deployment environment bound external
validity.

### 3.3 Frozen manifestation rule

Manifestation was evaluated with the frozen P1 CPU SLO. Five-second windows
were anchored to the normal-baseline start and were not realigned at phase
boundaries. A run manifested when either product-service p95 latency exceeded
345.992 ms for three consecutive populated windows or global error rate was
greater than zero for three consecutive populated windows. Empty windows reset
the consecutive-window streak. The rule was not tuned after viewing the fault
outcomes.

### 3.4 Attempt accounting and inclusion

The registry contains 35 unique attempts: 21 valid and 14 invalid. The 21 valid
attempts comprise six normal controls and 15 fault runs. Inclusion was
fail-closed: a run contributed to the descriptive result only when the canonical
registry classified it as valid and the required tracked evidence supported
the field being summarized. Invalid attempts remain part of the operational
accounting but do not enter the scientific outcome denominator.

Two reproducibility layers were kept separate. The tracked-evidence layer uses
version-controlled registry and report content. The stronger receipt layer
would additionally require each valid run's final receipt and SHA manifest.
The present worktree has zero of 21 expected receipt/manifest pairs; therefore,
the analysis does not claim receipt-level replay.

### 3.5 Analysis

The analysis is descriptive. For each workload-profile cell, the arithmetic
mean and sample standard deviation (SD) were calculated across valid runs, and
the coefficient of variation (CV) was reported as sample SD divided by the
mean, expressed as a percentage. Sample SD is not a confidence interval. No
hypothesis test, causal effect estimate, predictive model, or trained machine-
learning model was produced. Warning lead time was only eligible when the
frozen SLO manifested in a valid fault run.

## 4. Results

### 4.1 Run accounting

Of the 35 unique attempts, 21 were registry-valid and 14 were invalid. The
valid set contained six normal controls and 15 CPU-fault runs. The invalid
attempts were retained as operational provenance and excluded from the outcome
counts; this prevents failed or protocol-ineligible attempts from silently
inflating the scientific sample.

### 4.2 Physical actuation

The tracked reports showed ordered physical effects across the three fault
profiles at both workloads. At 10 users, the mean physical-effect values were
50.349, 99.649, and 146.941 for low, medium, and high, with CVs of 3.576%,
4.947%, and 2.254%, respectively. At 15 users, the corresponding means were
51.098, 93.987, and 140.435, with CVs of 5.384%, 0.704%, and 5.312%. These
descriptive values support the bounded claim that the profiles produced
separable physical actuation in the recorded same-host runs. They do not, by
themselves, establish user-visible degradation or causal generalization beyond
the observed environment.

### 4.3 SLO manifestation and warning lead time

None of the 15 valid fault runs manifested the frozen SLO: 0/15. Consequently,
no valid fault run had an eligible positive warning interval, and the observed
lead-time contribution is zero lead-time evidence rather than evidence of
early prediction. An SLO event observed in an invalid 15-user normal attempt
was excluded by the preregistered validity rule; it cannot be reassigned to the
valid normal or fault denominator.

### 4.4 Reproducibility result

RQ3 has a split answer. The tracked-evidence layer is reproducible from the
repository: the attempt counts, valid-run classifications, per-cell descriptive
statistics, and 0/15 manifestation count can be recomputed deterministically.
The receipt layer is incomplete in this worktree because zero of the 21
expected final-receipt/SHA-manifest pairs are present. This absence is a claim
about the inspected checkout, not proof that receipts never existed elsewhere.

## 5. Threats to Validity

### 5.1 Construct validity

Physical CPU actuation and user-visible service degradation are different
constructs. Ordered physical-effect values establish that the injected profiles
were materially different; they do not establish that the frozen latency/error
SLO should manifest. The frozen SLO reduces post-hoc threshold flexibility but
may not capture every meaningful degradation mode.

### 5.2 Internal validity

The same-host design limits environmental variation but increases the risk that
host scheduling, background load, or shared-resource interference influenced
measurements. Invalid attempts were excluded according to the registry rather
than reinterpreted after outcomes were known. Even so, the small number of
valid repeats prevents strong separation of treatment effects from residual
run-to-run variation.

### 5.3 Conclusion validity

The cell sizes are small and only descriptive statistics are reported. CVs and
sample SDs describe observed dispersion; they are not confidence intervals and
do not justify population-level significance claims. The 0/15 result supports
a bounded non-manifestation statement under the frozen rule, not proof that CPU
faults can never manifest or that an early-warning method is ineffective in all
settings.

### 5.4 External validity

The evidence is limited to one local deployment, one host, two workload levels,
one service target, and three CPU profiles. Results should not be generalized
to production clusters, other services, other resource limits, or other fault
classes without new prospective evidence.

### 5.5 Reliability and reproducibility

Repository-tracked inputs and the Week 3 derivation are deterministically
checkable, but receipt-level replay is currently blocked by the missing 21
receipt/manifest pairs. A successful repository verifier establishes internal
consistency of the tracked layer; it does not recover absent artifacts or prove
that the original runtime environment can be reconstructed exactly.

### 5.6 Scope and future work

D-147 stopped the later network-delay normal-baseline collection incomplete at
3/6 accepted normals; it is workflow provenance, not a Kubernetes root-cause
finding and not additional CPU evidence. No model was trained in the present
milestone. The D-064 target of 60 independent positive incidents plus 60 normal
control runs remains future confirmatory work and cannot be replaced by windows
within a run, the 15 CPU-fault runs, or the incomplete D-147 collection.
