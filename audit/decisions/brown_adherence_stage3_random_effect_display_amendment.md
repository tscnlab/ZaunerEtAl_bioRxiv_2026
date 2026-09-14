# Brown recommendation adherence Stage 3 random-effect display amendment

Decision ID: `BA-004`  
Change ID: `CHG-142`  
Date: 2026-08-15  
Status: author approved; bounded Stage 3 display amendment authorized

## Decision

The author requires the unsealed Stage 3 reader report to show the retained
random effect and to explain how the accepted response-scale R² partition is
distributed across random effects.

This request does not reopen Boundary Stage 2. The selected any-valid and
at-least-80% models each retain exactly one random effect, a participant
random intercept. The complete accepted random-effect R² increment is
therefore attributable to that participant intercept. A further allocation
among multiple retained random effects is neither available nor meaningful.

`BA-004` authorizes only a reader-facing display of frozen Stage 2 values and
one replacement targeted render before the existing `BA-BS3-REVIEW` stop.
It changes no model, estimand, sample, estimate, interval, test, multiplicity
result, diagnostic assessment, sensitivity result, or claim.

## Controlling frozen inputs

| Frozen Stage 2 input | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/stage2_boundary/random_sd_BA-EIBB-ANY-F3-R3-Q2-Q1-D0-OPTREC.csv` | `7341383f7ac6676a6d5b6d074b50c313b56362aaaa5c18e116ccf5ad07583673` |
| `audit/analyses/brown_adherence/stage2_boundary/random_sd_BA-EIBB-80-F3-R3-Q2-Q1-D0.csv` | `10759ddff047571714819b06a9bb9763a36a9c2344078f89d781d84af1d387c5` |
| `audit/analyses/brown_adherence/stage2_boundary/r2_variance_decomposition.csv` | `abffcdd17cb3b64254d91bcdb96a109a1d0053445b78cd08bc6996cb02178dd0` |
| `audit/analyses/brown_adherence/stage2_boundary/report_r2_decomposition.csv` | `d203cec7462ddab896f9b97336fa731967bd57306036d2523e1e7c2996100b04` |

R 4.6.1 verification matched these four files to their entries in the frozen
378-member Boundary Stage 2 manifest. It confirmed exactly one active random
effect in each selected model and reproduced the accepted partition identities
within numerical precision.

## Values authorized for display

| Analysis sample | Retained random effect | Logit-scale SD | Fixed-effect share, marginal R² | Participant-intercept increment | Observation and distribution share | Conditional R² |
|---|---|---:|---:|---:|---:|---:|
| Any-valid primary | Participant intercept | 0.316602062934113 | 58.4369553918453% | 2.18953887304749 percentage points | 39.3735057351072% | 60.6264942648928% |
| At least 80% coverage | Participant intercept | 0.308425103819607 | 59.2051886013216% | 2.13825538725695 percentage points | 38.6565560114214% | 61.3434439885786% |

The reader report may round these values consistently with its existing
display rules. It must identify the R² values as descriptive, point-only,
design-standardized response-scale summaries without confidence intervals,
p-values, or causal interpretation.

## Required reader explanation

Stage 3 must add:

1. a short random-effects subsection and one native `gt` table reporting the
   retained participant-intercept SD for both samples;
2. a revised R² table that distinguishes the fixed-effect share, the retained
   participant-intercept increment, the observation and distribution share,
   and marginal and conditional R²;
3. a plain statement that there is no additional retained random effect to
   decompose; and
4. a concise explanation that participant-level state and day-type slopes,
   the behavioral-cycle intercept, and participant intercepts for the endpoint
   processes were not retained after their recorded structural failures.

Rows marked inactive in the frozen random-effect CSVs are structural
placeholders. Their stored starting values are not fitted estimates. Stage 3
must not display those values, assign them zero variance, or imply that a
variance component was estimated for a term absent from the selected model.

## Bounded implementation contract

The Brown-adherence owner may update only:

- `audit/analyses/brown_adherence/07_results.qmd`;
- the paired Stage 3 display source data, native table code, focused tests,
  manifest, and visual-QA evidence under
  `audit/analyses/brown_adherence/stage3/`;
- the unsealed targeted output
  `audit/analyses/brown_adherence/07_results.html`; and
- `audit/handoffs/brown_adherence_strategy_handoff.md` solely for the current
  Stage 3 state and identities.

The first targeted Stage 3 HTML was not sealed or author accepted. It may be
replaced once after source-only verification. The replacement render must be
followed by the complete focused source and HTML checks, protected Stage 2
identity verification, and fresh secure-loopback visual QA.

No fit or refit, prediction, simulation, resampling, new R² or Shapley
calculation, inferential calculation, Stage 2 artifact regeneration, shared
configuration edit, manuscript edit, commit, push, or upload is authorized.
All 378 frozen Stage 2 manifest members must remain exact.

## Stop and notification boundary

The mandatory stop remains `BA-BS3-REVIEW`. Do not seal Stage 3, notify the
Nature Health writer, or begin Stage 4 until the amended reader report and its
replacement HTML have passed the complete gate and the author has reviewed
the finished Stage 3 package.

After Stage 3 is sealed for author review, follow the writer-notification
sequence already specified by `BA-003`: first send the pending-review result
package, then send the controlling acceptance identity only after explicit
author approval.

## Reopening condition

Return to Boundary Stage 2 only if the requested display cannot be built from
the four frozen inputs, a protected Stage 2 identity changes, a new variance
component or decomposition must be calculated, or the wording would imply a
random effect that is not retained in the selected model.
