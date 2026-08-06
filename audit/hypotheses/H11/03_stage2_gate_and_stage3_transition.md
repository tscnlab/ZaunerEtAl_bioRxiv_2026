# H11 Stage 2 gate and Stage 3 transition

Date: 2026-08-01  
Branch: `rewrite/NH`  
Decision source: author message in the dedicated H11 task

## Author decision

The author wrote: “approve the gate and move on to Stage 3”.

This approves the Stage 2 recommendations and authorises construction of the
reader-facing Stage 3 H11 report. The decision is recorded as follows:

- `H11-STAGE2-001`: approved — the primary near-eye complete-curve result and
  complementary chest complete-curve result are supported; no planned
  level/shape component remains supported after its within-placement
  Benjamini–Hochberg adjustment.
- `H11-STAGE2-002`: approved — use participant-cluster-robust pointwise 95%
  confidence intervals and do not make a simultaneous or familywise clock-
  period claim.
- `H11-STAGE2-003`: approved — the chest change identified in the audit is
  attributed to model/inference implementation on a common preparation, while
  the subsequent preparation change preserves both accepted robust decisions.
- `H11-STAGE2-004`: approved — all four fitted models are acceptable with the
  specified limitations.
- `H11-STAGE3-001`: approved — proceed to the reader-facing Stage 3 report from
  verified accepted outputs.

## Optional computation decision

The message did not explicitly approve the optional 2,000-resample production
run offered under `H11-COMPUTE-001`. Therefore the conservative offered option
is selected: retain the 50-resample estimates as audit-only and omit production
bootstrap intervals from the reader-facing report. No additional model fit,
bootstrap, simulation, or scientific recomputation is authorised by this
transition.

The robust delta-method interval for equal-clock fitted sex-curve variation
and the participant-cluster-robust pointwise curve intervals are accepted
non-pilot outputs and may be reported.

## Stage 3 scope

Stage 3 will:

1. construct reader-facing source files only by selecting, renaming, or copying
   frozen Stage 2 outputs whose identities are verified against the Stage 2
   manifest;
2. create and render `notebooks/hypotheses/H11.qmd`;
3. apply REPORT-008 through REPORT-012, including the exact “Answer in brief”
   callout title, pointwise interval language, the required gap-timing-unaware
   terminology, the paired-placement applicability assessment, and final-size
   figure QA;
4. report near eye as primary and chest as complementary evidence; and
5. stop at the Stage 3 author-approval gate before any Stage 4 work.
