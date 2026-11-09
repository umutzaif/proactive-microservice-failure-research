# D-148 contribution comparison

## Comparison matrix

| Work | Primary timing/task | Inputs and evaluation unit | Reported outcome | Relation to D-148 |
|---|---|---|---|---|
| MULAN [1] | Reactive root-cause localization | Metrics + logs; 4/5/5 recorded faults across three datasets | PR@K, MAP@K and MRR root-cause ranking | Establishes that multimodal causal-graph RCA is prior work; D-148 has no RCA model or ranking result. |
| GALR [2] | Post-event root-cause localization and recovery planning | Metrics + logs + traces + LLM priors; window labels anchored at injection time | Top-k/MRR and offline action-overlap accuracy | Establishes that LLM + GAT + recovery is prior work; D-148 does not reproduce or outperform it. |
| Between Promise and Pain [3] | Interactive LLM-agent diagnosis | Tool-augmented agents over microservice incidents and healthy cases | Diagnostic accuracy, efficiency, cost and qualitative failure modes | Supports guarded evidence use and no autonomous mutation; D-148 does not evaluate an LLM gate. |
| Proactive SLO mini-review [4] | Prospective SLO/prefix prediction taxonomy | Partial traces/history; request or incident outcomes | Precision-constrained earliness, coverage and false-alarm measures | Defines what future early-warning evidence should contain; D-148 has no positive event on which to compute these measures. |
| LLM4AIOps survey [5] | Broad AIOps taxonomy | 183 articles from 2020–2024 | Task, data, method and evaluation synthesis | Background context only; not a direct baseline. |
| D-148 present study | Prerequisite fault-effect and evidence-governance case study | One host; two workloads; six physical-effect cells; 35 attempts, of which 21 are valid | Ordered descriptive actuation, 0/15 frozen-SLO manifestation, explicit validity and replay accounting | Does not compete on model accuracy; exposes the evidence conditions required before prospective model comparison. |

## Admissible contribution statements

### W5-C01 — Fault actuation is not outcome manifestation

Across the tested same-host cells, the three CPU profiles produced ordered
descriptive physical effects, yet none of the 15 valid fault runs manifested the
frozen SLO. The contribution is the measured separation of these two concepts
in this bounded environment, not a universal statement about CPU faults.

### W5-C02 — Fail-closed run accounting changes the evidential denominator

The study preserves 35 unique attempts while restricting scientific outcome
counts to 21 registry-valid runs. Fourteen invalid attempts remain visible as
operational evidence but cannot inflate the effect or manifestation denominator.
This is an auditable study-design contribution, not a new RCA algorithm.

### W5-C03 — Reproducibility has separable layers

Tracked registry/report evidence deterministically supports the bounded counts
and descriptive summaries, while receipt-level replay remains unavailable at
zero of 21 expected receipt/manifest pairs. Reporting these layers separately
prevents historical receipt-pass statements from being promoted to a replay
claim that the current worktree cannot independently establish.

## Claims that remain prohibited

- “We propose a novel multimodal RCA method.” MULAN and other prior work already
  cover multimodal causal-graph RCA, and D-148 contains no RCA model.
- “We introduce the first LLM-GAT microservice framework.” GALR already combines
  LLM-derived priors with graph attention, and D-148 implements neither.
- “Our method predicts SLO violations early.” There are zero positive
  manifestation/lead-time events and no trained or evaluated predictor.
- “CPU stress has no service impact.” The valid statement is only that the frozen
  SLO did not manifest in these 15 valid same-host fault runs.
- “The treatment has no causal effect.” The study reports descriptive actuation
  and a bounded null manifestation result, not an identified causal effect.
- “The artifact is completely reproducible.” Tracked evidence is checkable, but
  receipt-level replay remains incomplete at 0/21.
- “Invalid attempts demonstrate robustness.” Invalid attempts document workflow
  and failure modes; they are excluded from scientific outcome denominators.
- “D-147 confirms network-delay infeasibility.” D-147 is an incomplete 3/6 normal-
  collection stop with no headroom or treatment result.

## Falsification and revision rules

W5-C01 must be narrowed if the accepted run membership, frozen SLO identity, or
six cell summaries change. W5-C02 is falsified by a deterministic registry count
other than 35 total, 21 valid, and 14 invalid, or by evidence that an invalid run
entered a reported scientific denominator. W5-C03 may be revised only after an
authorized, source-bound receipt bundle supplies and successfully verifies all
21 expected pairs. New model, causal, or external-validity contributions require
new prospective decisions and evidence; they cannot be inferred from Week 5.
