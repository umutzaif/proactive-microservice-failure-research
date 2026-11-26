# EASE 2027 RENE Adaptation Gap Analysis

Status: `preparation_only_not_submission_ready`

Official source checked: [EASE 2027 Reproducibility and Negative Results](https://conf.researchr.org/track/ease-2027/ease-2027-reproducibility-and-negative-results), 2026-11-26.

## Decision summary

EASE 2027 RENE remains the strongest scientific target, but it is conditional.
The current package fits the track's interest in informative negative results,
methodological boundary conditions, artifact transparency, and empirical
software engineering. It does not yet meet the full submission contract.

Two gates precede venue-specific manuscript conversion:

1. at least one adviser commits to attend and present in Hanoi, or the
   organizers confirm in writing that remote author presentation satisfies the
   attendance and proceedings requirements;
2. the advisers accept a RENE framing centered on actuation-versus-
   manifestation methodology and fail-closed evidence governance, rather than
   treating `0/15` as a powered universal null result.

## Official requirements captured on 2026-11-26

- PDF submission through EasyChair.
- Maximum ten pages for the main text, including figures, tables and
  appendices, plus at most two reference-only pages.
- ACM Primary Article Template with
  `\documentclass[sigconf,review,anonymous]{acmart}`.
- Double-anonymous review, including anonymous online supplements and
  replication packages.
- Compliance with the SIGSOFT Open Science Policy and ACM publication,
  integrity, human-participant, and AI-generated-content policies.
- Review criteria: soundness, significance, novelty, verifiability and
  transparency, and presentation.
- Artifact availability is particularly important for RENE submissions.
- A negative result must be informative and methodologically sound. A small or
  underpowered sample alone is not a suitable negative-result contribution.
- Abstract deadline: 2027-02-22 AoE. Full-paper deadline: 2027-03-01 AoE.
  Notification: 2027-04-12. Camera-ready and early-registration deadlines are
  still to be announced.
- At least one author must register and present an accepted paper. The inspected
  call does not state that remote author presentation is available.
- Accepted papers use ACM ICPS open-access publication. An ACM APC may apply,
  depending on author circumstances and current ACM policy.

## Gap and action matrix

| ID | Requirement or reviewer risk | Current evidence | Status | Required action | Falsification or stop condition |
|---|---|---|---|---|---|
| W11-G01 | The contribution must be informative beyond observing a missing effect. | The draft separates physical actuation, frozen-SLO manifestation, validity accounting, and replay layers. | Partial | Make boundary conditions and actionable experimental recommendations the paper's main contribution. | Stop if the paper's novelty collapses to “0/15 occurred.” |
| W11-G02 | A small or underpowered sample alone is not a suitable RENE negative result. | Cell sizes are two or three and analysis is descriptive. No inferential null-effect claim exists. | High risk | Retain the bounded case-study language and explicitly state that `0/15` is an observed outcome, not evidence of no effect or statistical equivalence. Obtain adviser judgment that the methodological insight is sufficient for RENE. | Reject the RENE route if reviewers would receive only a small-sample null result without independent methodological significance. |
| W11-G03 | ACM anonymous `sigconf` format, ten main pages plus two reference-only pages. | The current output is a four-page Letter-layout PDF derived from Markdown, not `acmart` LaTeX. | Open | Create a new venue-specific LaTeX candidate only after the attendance and framing gates pass. Do not edit the sealed Week-9 PDF. | Fail if format, page accounting, or conference metadata differs from the live official call. |
| W11-G04 | Double-anonymous manuscript and supplements. | Paper text uses `Anonymous Author(s)`, but Git history, repository URLs, local paths, metadata, and export history are not yet a verified anonymous distribution surface. | Open | Build a history-free export, scan document properties and identifiers, review self-citations in third person, and perform a final double-blind audit. | Fail on any author, institution, account, host, email, repository-owner, course, or adviser identifier. |
| W11-G05 | Verifiable and well-documented artifacts, preferably in a persistent repository. | Tracked evidence, scripts, configurations, and deterministic Weeks 3–10 replay pass. Receipt pairs remain unavailable at `0/21`. | Held | Present layered reproducibility honestly. Decide with advisers whether a tracked-evidence artifact with the explicit receipt limitation is sufficient. Never reconstruct or imply absent receipts. | Stop if the manuscript or artifact claims receipt-complete reproduction or silently removes C148-05. |
| W11-G06 | At least one author must register and present. | Adviser acceptance is recorded, but physical attendance and remote author presentation are unconfirmed. | Blocking | Obtain adviser attendance commitment or written organizer confirmation that remote presentation satisfies publication requirements. | Do not select EASE or adapt the paper if neither route is available. |
| W11-G07 | Open-access and registration costs must be known before commitment. | The call states that an ACM APC may apply. Registration rates and the early-registration deadline are not yet published on the inspected page. | Open | Recheck ACM Open eligibility, geographic/institutional waivers, author registration category, APC, and university support before submission or payment. | Stop before financial commitment if the total cost or payer is unresolved. |
| W11-G08 | AI-assisted content must follow ACM disclosure policy and remain author-controlled. | AI assistance has supported drafting and verification, while scientific claims remain tied to canonical evidence. No venue disclosure text has been approved. | Open | Prepare an adviser-approved disclosure that accurately describes assistance without assigning authorship or scientific judgment to AI. | Fail if disclosure is omitted where required or overstates independent human authorship of generated text. |
| W11-G09 | Abstract and paper deadlines must be feasible. | The current bounded manuscript, figures, tables, bibliography, supplement, and review archive exist. | Feasible with gates | If EASE is selected, freeze the abstract before 2027-02-22 AoE and the complete anonymous package before 2027-03-01 AoE with internal review margin. | Stop if attendance, anonymity, artifact, cost, or adviser review remains unresolved at the internal freeze. |
| W11-G10 | Submission status must match evidence. | Adviser acceptance and native PowerPoint compatibility are verified. Receipt replay is `0/21`; no external upload or final double-blind approval exists. | Not ready | Keep `not_submission_ready` until every blocking gate is independently verified. | Any `submission_ready=true` label before those gates pass is invalid. |

## Recommended order

1. Obtain the attendance-mode answer without sending the manuscript or artifact.
2. Ask the advisers to approve the RENE methodological framing in light of the
   explicit small-cell-size warning.
3. Recheck registration and ACM APC exposure.
4. Only then create a new anonymous `acmart` candidate from the verified
   manuscript source and Week-9 method addendum.
5. Run content, artifact, anonymity, visual, and venue-compliance review before
   requesting separate upload or submission authority.

## Unchanged scientific boundary

This preparation changes no run, threshold, label, denominator, Dataset entry,
or scientific conclusion. The evidence remains `35/21/14`, six descriptive CPU
cells, `0/15` frozen-SLO manifestations, and receipt readiness `0/21`. D-147
remains stopped at `3/6`. No model, runtime, receipt recovery, upload,
submission, publication, registration, or payment is authorized.
