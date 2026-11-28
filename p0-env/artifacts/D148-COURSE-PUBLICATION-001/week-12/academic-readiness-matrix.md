# D148 Venue Neutral Academic Readiness Matrix

Status: `academic_review_ready_but_not_submission_ready`

This matrix evaluates whether the current work functions as a defensible academic output independently of a conference template. It does not replace the canonical Research Decision Log, experiment protocol, dataset card, or results registry.

| Dimension | Academic acceptance test | D152 result | Remaining limitation or falsifier |
|---|---|---|---|
| Research problem | The paper states a consequential, answerable problem before presenting implementation detail. | Pass. The problem is the conflation of treatment request, physical actuation, and service manifestation. | Fail if the paper is reframed as a generic CPU benchmark or a model paper. |
| Research questions | Each question is answered by available evidence and has a bounded population. | Pass. RQ1 covers actuation, RQ2 manifestation, and RQ3 evidence governance. | Fail if any question implies production, cross-service, or causal generality. |
| Literature position | Prior work is used to define the gap, not merely listed. | Pass with nine primary scholarly sources spanning fault injection, microservice RCA, operational agents, and proactive SLO evaluation. | Reassess if a target discipline requires a systematic review or materially different nearest work. |
| Method transparency | Treatment, workload, lifecycle, physical-effect, SLO, denominator, and analysis contracts are independently inspectable. | Pass at the tracked-evidence layer. | Fail if the quantitative contracts are omitted or changed without a prospective canonical decision. |
| Evidence to claim traceability | Every result claim maps to canonical records or deterministic derived artifacts. | Pass for 35/21/14 accounting, six descriptive cells, and 0/15 manifestation. | Receipt-level replay remains unavailable at 0/21. |
| Statistical interpretation | Descriptive results are not promoted to significance, equivalence, or universal absence of effect. | Pass. Cell sizes, SD, CV, ranges, and 0/15 are explicitly bounded. | Fail on language such as proves no effect, statistically equivalent, or CPU faults do not cause failure. |
| Negative result value | The contribution remains useful beyond reporting a small null count. | Pass as a methodological boundary: actuation is separated from manifestation, invalid denominators stay visible, and unsupported model work is stopped. | Weakens if the governance recommendations are removed and only 0/15 remains. |
| Limitations | Construct, internal, conclusion, external, and reproducibility threats are explicit. | Pass. | Fail if 0/21 receipts, one-host scope, or two-to-three-run cell sizes are hidden. |
| Reproducibility | Reproducibility is described in layers and unavailable layers remain visible. | Pass for tracked sources and deterministic derivation; held for final receipts. | C148-05 stays held until authorized source-bound receipt bundles independently replay. |
| Ethical and operational boundaries | The document does not authorize runtime mutation or transfer scientific judgment to automation. | Pass. | Any runtime, recovery, submission, or publication action requires separate authority. |
| Presentation quality | The editable document and PDF use consistent academic typography and survive full-page visual inspection. | Pass. All eight rendered pages were inspected after correction of the initial title-border, alternating-header, and literal Markdown-marker defects. | Fail on clipping, overlap, broken tables, missing glyphs, or inconsistent pagination. |
| External submission | Venue rules, anonymity, author information, costs, attendance, and final artifact policy are resolved. | Not evaluated by D152 and deliberately open. | `not_submission_ready` remains binding; academic-review readiness is not submission readiness. |

## Decision

The project is capable of producing a venue-neutral academic output from existing evidence. Its strongest defensible form is a bounded empirical case study and methodological negative result. It is not yet a complete external-submission package because receipt replay, author and anonymity state, venue rules, and external authorization remain separate gates.
