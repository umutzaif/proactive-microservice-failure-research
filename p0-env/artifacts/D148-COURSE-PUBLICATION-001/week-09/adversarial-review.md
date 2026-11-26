# D-148 Week 9 Adversarial Audience Review

## Review audience and test

Primary audience: software reliability and empirical systems reviewers plus
academic advisers. Secondary audience: a course or internship defense jury.

The review asks whether a technically competent reader can answer, from the
candidate package alone: what ran, what changed, how physical effect was
accepted, how service manifestation was defined, which attempts entered each
denominator, what was observed, and which conclusions remain forbidden.

## Gap-resolution matrix

| ID | Observed gap in Week 8 candidate | Why it matters | Canonical evidence | Week 9 resolution | Falsification check |
|---|---|---|---|---|---|
| W9-G01 | Low/medium/high were named but their requested CPU demand and target limit were absent. | A reviewer cannot distinguish profile labels from actual treatment magnitude. | `cpu-recommendation-low-v4.json`, `medium-v1.json`, `high-v1.json` and 15u counterparts. | State the 200 mCPU container limit and requested +50/+100/+150 mCPU duty-cycle demand. | Reject if any accepted run uses a different target, limit, requested demand or profile family. |
| W9-G02 | Fault and workload lifecycle durations were only implicit. | Reproduction and exposure interpretation require phase lengths. | Workload profiles; fault profiles; D-038 lifecycle decision. | State 300 s warm-up, 300 s baseline, 120 s ramp, 300 s steady and 300 s cooldown. | Reject if versioned metadata does not bind these durations or worker duration exceeds the recorded tolerance. |
| W9-G03 | Injector mechanics and termination boundary were absent. | Command success cannot substitute for physical effect, and an unbounded worker would be a safety defect. | Versioned fault profiles and `cpu-duty-worker.py`. | State 100 ms in-container Python duty cycle, automatic termination, 450 s maximum and worker-event timing source. | Reject if source hash/profile identity or termination/timing contract differs. |
| W9-G04 | Physical-effect eligibility was summarized but quantitative coverage and delta gates were absent. | Readers need to know why a run counts as actuated. | `experiment_protocol.md` and versioned fault profiles. | State Prometheus-derived adjacent-scrape intervals, at least 48 of 60 intervals in baseline and steady, and minimum +25/+50/+75 mCPU deltas. | Reject a run if either coverage or magnitude fails; injector exit status alone never passes. |
| W9-G05 | Workload generator details were too thin. | User count alone does not define workload behavior. | `ob-default-10u-1r-v1.json`, `ob-second-15u-1r-v1.json`. | State one loadgenerator replica, spawn rate 1/s, uniform 1-10 s wait, seed 1, Locust 2.43.0 and six task weights. | Reject if workload/profile identity or pinned loadgenerator contract differs. |
| W9-G06 | Invalid attempts were counted but their operational failure timing was not summarized. | Readers may suspect selective exclusion. | Week-2 audit recorded under D-148. | Report audit-only grouping: 2 invalid normals, 5 fault attempts stopped before actuation and 7 with later lifecycle/effect/finalization failures. | The grouping must never become a new scientific label or enter effect denominators. |
| W9-G07 | The results table omitted observed ranges. | With cell sizes of two or three, ranges help readers see dispersion without inferential overclaim. | Week-3 physical-effect CSV. | Add ranges beside mean, sample SD and CV. | Reject if ranges differ from accepted-run values or are presented as confidence intervals. |
| W9-G08 | The presentation did not expose enough protocol detail for technical questions. | A defense jury can ask how a valid fault run was constructed. | Same sources as W9-G01 through W9-G05. | Add a technical appendix with treatment, lifecycle, coverage and SLO contracts plus an evidence-boundary appendix. | Slides must remain readable and must not imply new execution or model results. |
| W9-G09 | “Submission-ready” could be inferred from visual polish. | Visual completion is not provenance completion. | C148-05 and Week-8 decision record. | Keep adviser-review status visible and state receipt replay 0/21, archive scope and outstanding adviser/venue review. | Reject any complete-reproducibility, public-release or submission claim. |

## Narrative decision

The Week 9 revision keeps the negative result as the center of the paper, but
moves the reader through a stricter chain:

1. fault request and bounded injector contract;
2. measured physical-effect eligibility;
3. frozen SLO manifestation;
4. valid/invalid denominator accounting;
5. bounded interpretation and reproducibility limits.

This order was selected over a model-centered narrative because the evidence
contains zero positive manifestation events and no frozen feature-window
dataset. It was selected over a purely operational report because the paper's
contribution is the scientific separation of actuation, manifestation and
validity, not a chronology of tooling failures.

## Remaining non-repairable limitations

- Receipt replay remains unavailable at 0/21.
- The evidence comes from one host and one target service.
- Cell sizes are two or three runs; analysis remains descriptive.
- No positive manifestation event exists, so predictive-model evaluation is
  undefined.
- Native PowerPoint behavior, adviser acceptance, venue-specific formatting
  and final double-blind review remain external checks.
