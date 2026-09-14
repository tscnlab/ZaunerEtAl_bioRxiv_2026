# H06 daily Stage 2 acceptance and Stage 3 transition

Decision ID: `H06-D-015`  
Change ID: `CHG-133`  
Date: 2026-08-12  
Status: author approved; complementary Stage 3 authorized

## Author decision

While reviewing `H06-D-G2B-GAP-CLOCK-REPAIR`, the author explicitly replied
`approve - continue`. This accepts all five requested dispositions in
`audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_transition.md`:

1. the task-owned unit normalization and exact 90-cell gap clock-hour repair;
2. the H01-aligned diagnostic disposition of zero hard failures and 90
   visually reviewed limitations among the repaired cells;
3. the restored six gap 15-slot FDR families while keeping the accepted L10
   and MDER boundaries frozen;
4. continued disclosure of the AR, response-family, deletion-influence, and
   participant-cluster HC3 interaction limitations; and
5. closure of the H06_daily Stage 2 repair gate.

The word `continue` authorizes the next separately gated deliverable under
`H06-007`: the compact Stage 3 report of the complementary participant-day
analysis. It does not authorize Stage 4.

## Accepted Stage 2 identities

Before changing its task-owned gate transition, the H06_daily owner must
verify these exact pre-acceptance identities:

| Accepted input | SHA-256 |
|---|---|
| H06-007 primary/complement role decision | `c5c08a454ba94a4d955d9821be50b422b697d779b2b5ec921a316c508dd248c1` |
| H06-D-014 diagnostic decision | `64be7a03f6982d175e4372d8488d84ed3e427a9bd38e1eddbc55f0ce1c49375e` |
| CHG-132 coordinator gate record | `f971595dcd138a344aa69e9b88dd8b7115e44b425cacd0b176456f6afa1b26fe` |
| Gap-repair report source | `4f41a945e4633cc74f3bca4e3a225b90abfb538f07713708df1631ac23b3e179` |
| Gap-repair report HTML | `2988f010773f1eb084e1f2ceb7068d90e3d7ef05fe3471cd3d6b4491d7d20646` |
| Gap-repair transition | `296b093abc03bc3d041b60b8e73723926136cf42b22257ac67069b64acd2ac73` |
| Gap-repair report manifest | `74cf8348fc8166df94b70242f00200302a36801bdefbcf826cc2e2e309b96b52` |
| Gap-repair input manifest | `c0523db9c2e07973aafce393be378cadb2a3260d307107e13ebe27ddf4873275` |
| Gap-repair code manifest | `b0240835d7fcb173375aef8df2d307c5ffb6db40023b20c1071d0571e36483c2` |
| Gap-repair output manifest | `b1fcdefb963178deffcd515cb6d12610e1778e035bb378da31df92c5d68a6b7c` |
| Gap-repair software manifest | `0fcacb6f450dffbd8f4942fe706644fe04dfbea4368825f0c0cb1ffa9d0c8c0f` |
| Gap-repair focused test | `4a5450528ec95043aff4a8686a31d71a4ff7f033eb270e5abe1cd385a187bd23` |

The accepted evidence comprises 90 repaired and 378 invariant non-L10 cells,
30 repaired raw timing slots, six reconstructed gap FDR families, 12,837
deletion refits without failure, 90 visual residual-review limitations, 1,011
protected historical identities, all 997 frozen H06-D-G2A outputs, and 439
non-circular task-owned repair outputs.

After that intake check, the owner may update
`H06_daily_gap_clock_repair_transition.md` to record the author decision. The
new transition identity and the SHA-256 of this central decision must then be
the controlling Stage 3 input pins; the pre-acceptance transition identity
above remains historical gate evidence.

## Stage 3 authorization

The H06_daily owner may now create
`notebooks/hypotheses/H06_daily.qmd` as a concise standalone reader-facing
report. The report must:

- identify the completed hourly H06 analysis as the main analysis and this
  participant-day analysis as complementary evidence;
- state the preregistered daily-metric question and include the exact visible
  callout title **Answer in brief**;
- explain the participant-day estimands, the three approved predictors, the
  placement and sample roles, and the fixed 15-slot FDR families in plain
  scientific language;
- report exact participants, participant-days, sites, and other applicable
  denominators for every displayed result;
- distinguish primary from gap-timing-unaware and paired/common-sample
  evidence and preserve near-eye as primary and chest as complementary;
- preserve L10 mean as non-estimable under the accepted two-part route, with
  no shifted-log or component result substituted into its inferential slot;
- preserve the accepted MDER result and all frozen non-L10 estimates,
  intervals, raw p-values, FDR decisions, and multiplicity families;
- present all inferential results with 95% confidence intervals and the
  shared p-value display convention;
- state that all accepted model cells are usable with limitations rather than
  hiding the visual residual-review, AR, response-family, influence, or HC3
  interaction qualifications;
- describe the repaired gap timing results as sensitivity evidence, not as a
  replacement for either the primary daily dataset or the main hourly H06
  analysis;
- use dynamic `.qmd` links to the main H06 report and the preregistration-
  deviations page where relevant;
- follow the current reader vocabulary, country-coded site names, native `gt`
  table, figure readability, alt-text, and paired source-data contracts; and
- use only stored accepted outputs and bounded display calculations.

The Stage 3 source may create display-only tables, figures, and paired source
CSVs from accepted stored output rows. It must not fit or refit a model,
re-estimate AR parameters, rerun deletion analyses, reconstruct raw or FDR
p-values, change an accepted diagnostic verdict, regenerate shared data, edit
main H06, or modify shared Quarto configuration.

The task must stop at `H06-D-G3` after producing the Stage 3 source, focused
HTML, source-data and display manifests, readability/accessibility checks, and
task-owned handoff. Explicit author approval is required before Stage 4.

## Still blocked

Stage 4 remains a separate document at
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd` and is not
authorized by this decision. Website integration, shared configuration,
main-H06 changes, manuscript edits, commit, and push also remain blocked.

## Reopening condition

Reopen Stage 2 if any accepted identity or preservation check fails, if the
Stage 3 display requires scientific recomputation, if an estimate, interval,
raw or FDR p-value, diagnostic disposition, sensitivity classification, or
claim changes, or if the complementary analysis exposes a discrepancy that
materially changes the accepted main hourly H06 result.
