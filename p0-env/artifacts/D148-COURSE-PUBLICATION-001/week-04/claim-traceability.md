# Week 4 claim traceability

| Claim | Manuscript treatment | Evidence boundary | Falsification / hold condition |
|---|---|---|---|
| C148-01 | 35 unique attempts: 21 valid and 14 invalid; valid set is 6 normal plus 15 fault. | Canonical registry and Week 3 run-accounting table. | Any deterministic recount producing different totals falsifies the sentence. |
| C148-02 | Six workload/profile cells have the reported means and CVs. | Week 3 physical-effect table derived from registry-valid reports. | Recompute from tracked valid rows; any mismatch falsifies the numeric claim. |
| C148-03 | Frozen SLO manifestation was 0/15 among valid fault runs. | Week 3 valid-fault table and frozen SLO contract. | A registry-valid fault report with a supported positive manifestation falsifies 0/15. |
| C148-04 | No eligible positive warning interval; zero lead-time evidence. | C148-03 plus the rule that lead time requires manifestation. | A valid manifested fault run with eligible warning timing falsifies the claim. |
| C148-05 | **Held.** Receipt-level replay is not claimed. | Week 2 audit found 0/21 final-receipt/SHA-manifest pairs in this worktree. | The claim may be reconsidered only after all expected pairs are located and replayed successfully. |
| C148-06 | Mandatory limitation: same-host, single local deployment and bounded workloads/profiles. | Project protocol and tracked configuration scope. | Broader wording without new prospective evidence violates the boundary. |
| C148-07 | Mandatory limitation: descriptive statistics only; sample SD is not a confidence interval; no model. | Week 3 derivation and D-064 future target. | Inferential or predictive wording without a new preregistered analysis violates the boundary. |
| C148-08 | Mandatory limitation: D-147 is an incomplete 3/6 network-delay workflow stop, not CPU evidence or a root-cause diagnosis. | D-147 closure record. | Treating D-147 as completed baseline evidence, diagnosis, or CPU evidence violates the boundary. |

This table is a review aid. Canonical scientific status remains in the project
decision log, protocol, dataset card, and results registry.
