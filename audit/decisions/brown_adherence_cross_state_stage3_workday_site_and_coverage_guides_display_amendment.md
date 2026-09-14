# Brown adherence integrated Stage 3 Work-day site and coverage-guide display amendment

Decision ID: `BA-014`  
Change ID: `CHG-153`  
Date: 2026-08-20  
Status: author requested; bounded stored-output display amendment authorized

## Decision

Before accepting `BA-CS-G3-INTEGRATED-REVIEW`, the author requested two
reader-display additions:

1. a companion to `fig-main-site-free-work-contrasts` that shows the
   site-specific Work-day adherence level for each Brown state; and
2. visible vertical x-axis guides in `fig-main-coverage-sensitivity` so its
   labeled scale can be read directly.

`BA-014` and `CHG-153` authorize one stored-output-only Stage 3 display
amendment. The first display uses the frozen primary any-valid compact
adherence output. The second is a display-only copy of the accepted coverage
sensitivity forest. Neither display introduces a new model, estimand,
prediction, interval, test, p-value, multiplicity calculation, or scientific
claim.

The sealed 111-member site-interaction Stage 3 package remains historical
pre-amendment evidence. Its QMD and HTML are the only historical endpoints
authorized to acquire new identities. The other 109 sealed members and the
111-row final manifest itself must remain byte-identical. The mandatory author
stop remains open. Stage 4 and writer notification remain blocked.

## Controlling authority

This amendment is subordinate to `BA-003`, `BA-004`, `BA-008` through
`BA-013`, and their associated change records. The immediately controlling
central identities are:

| Authority | SHA-256 |
|---|---|
| `audit/decisions/brown_adherence_cross_state_stage3_site_interaction_render_retry.md` | `d5f2955dbe16fe670f531ddf8ce5d782cccb2505400a97a789315a285f831e48` |
| `audit/decisions/brown_adherence_cross_state_stage3_site_interaction_render_retry_manifest.csv` | `d96199e3adb84b5598402e0d317881bd7d44e3d53f7f61259fdd485bd8c312aa` |
| `audit/decisions/brown_adherence_cross_state_stage3_site_interaction_qa_equivalence.md` | `c760d3625f9e273a6db062ac0fe110d520b4f03701d070d2b43f4ed4f3e85d6e` |
| `audit/decisions/brown_adherence_cross_state_stage3_site_interaction_qa_equivalence_manifest.csv` | `2abb6d53ac62ee53ed8dc0280167a949a4eae0d70ed8df9a983a6470e9015442` |
| `audit/ledgers/decision_register.csv` after `BA-013` | `d59fde7505cef8f6f62f49aaccabdcd010427ef7a0658aea9a67b22e64d13c71` |
| `audit/ledgers/change_log.csv` after `CHG-152` | `2e4144c077f73494f158daf5758cd3f704bed6a7d3e67db41bb168dac0cd7ad1` |

The continuing task must verify unique `BA-014` and `CHG-153` rows and every
prior Brown decision and change identity before editing a source or building a
display.

## Historical Stage 3 baseline

The exact accepted-but-not-author-approved baseline is:

| Artifact | Members | Bytes | SHA-256 |
|---|---:|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 1 | 49,315 | `ef6ed62690afa30fe2801e559b487462a11c4130e903e3725bb164554bed191a` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 1 | 4,330,019 | `c65cf33519723b8bcc9f83550d1e0509099c9f6ffa1a37d7bcdd7fec2f9464c1` |
| `site_interaction_display_amendment/site_interaction_stage3_final_manifest.csv` | 111 | 65,113 | `a5571136cae902947b1116e597b7b01bed16b46558807c4dd16064108571cacf` |
| `site_interaction_display_amendment/site_interaction_stage3_success_handoff.md` | 1 | not controlling | `3232dbb242a163a7da9b513bd46ea9d8ee2b94f5be35c5d1d7338dc46d187961` |
| `site_interaction_display_amendment/site_interaction_integrated_author_gate.csv` | 1 | not controlling | `f095897c256102e9a35d40462710a1d45f76b329eca2df1cb504314ab823f235` |
| `site_interaction_display_amendment/site_interaction_stage3_finalization_checks.csv` | 1 | not controlling | `60e48a44b8ca7a8401e562a39756be74d1fd6bf678ca851e74c3c7f2ba7f0717` |
| `site_interaction_display_amendment/site_interaction_stage3_finalization_execution_record.csv` | 1 | not controlling | `cc1c59d60d83cd5d1e01cb9d4ade8caaee18cc2fe32705729c8012110395921d` |

Paths beginning with `site_interaction_display_amendment/` are relative to
`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/`.

R 4.6.1 must independently rehash all 111 manifest members. The historical
manifest, handoff, author gate, finalization checks, execution record, QA
evidence, screenshots, original figures, source data, and all earlier sealed
records remain immutable. The old QMD and HTML identities remain truthful
historical pre-amendment evidence and must be recorded explicitly in the new
amendment package.

## Frozen inputs and reproduced support

Only these frozen stored outputs may supply the two displays:

| Frozen input | Bytes | SHA-256 | Role |
|---|---:|---|---|
| `audit/analyses/brown_adherence/stage2_boundary/compact_adherence_table_source.csv` | 40,884 | `0c9c81ab166be1c0f581265ccb582080a9a62c64f4c1fb6891ba419bb44b23fe` | primary any-valid Work-day site adherence, intervals, and stored site-minus-average results |
| `audit/analyses/brown_adherence/stage3/source_data/figure_coverage_sensitivity_source.csv` | 1,158 | `f977b2beeaa055f82e93fea19dc339b8c7902bca080c91ea88124815c97665fa` | six accepted coverage-sensitivity estimates and intervals |
| `audit/analyses/brown_adherence/stage3/figures/coverage_sensitivity.png` | 48,324 | `f4113b56986b5467691c0a8a2a7cc6147583e66c21c2b2480ef93c16a8686a9a` | historical accepted 1,680 by 919, 200-dpi display |
| `audit/analyses/brown_adherence/stage3/figures/coverage_sensitivity.svg` | 7,068 | `7cb9290d20994e2aa434c7cc81c3346ec5f31ea2cef434c86194726020913415` | historical accepted vector display |

The original coverage PNG and SVG are preservation references, not inputs to
be overwritten.

A read-only R 4.6.1 audit reproduced:

- exactly 27 rows after filtering the compact source to
  `sample_id == "primary_any_valid"`, `row_kind == "site"`, and
  `day_type == "Work day"`;
- exactly three states and nine country-coded sites;
- exactly seven rows whose stored `contrast_significant` value is true, with
  exact equivalence to stored `contrast_p_adjusted < 0.05`;
- exactly three primary any-valid, equal-site Work-day reference rows;
- finite adherence estimates and confidence limits, with every estimate
  inside its stored interval; and
- exactly six coverage-sensitivity rows, comprising three states and two
  samples, with finite stored estimates and intervals.

The seven significance indicators refer to the stored site-minus-equal-site
Work-day contrasts. They must not be described as tests of the plotted
adherence levels.

## Exact authorized paths

The continuing Brown task may:

1. update only
   `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`;
2. replace exactly once
   `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html`;
3. create one new amendment root:
   `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/`;
4. create only amendment-owned R scripts, paired source data, PNG and SVG
   displays, source and render checks, identity inventories, execution records,
   QA records, screenshots, final handoff, author gate, and one non-circular
   final manifest inside that root; and
5. create the following reader artifacts inside that root:
   - `source_data/main_site_workday_adherence_forest_source.csv`;
   - `source_data/main_coverage_sensitivity_forest_source.csv`;
   - `figures/main_site_workday_adherence_forest.png`;
   - `figures/main_site_workday_adherence_forest.svg`;
   - `figures/main_coverage_sensitivity_guides.png`; and
   - `figures/main_coverage_sensitivity_guides.svg`.

The new coverage source-data file must be byte-identical to the frozen six-row
source. The original coverage source, PNG, and SVG must remain byte-identical.
No earlier amendment directory or sealed member may change.

No shared configuration, central ledger, main Brown source, Stage 2 output,
existing Stage 3 output, manuscript file, package, lockfile, full-project
render, commit, push, upload, or writer notification is authorized.

## Work-day paired source-data contract

`main_site_workday_adherence_forest_source.csv` must contain exactly 27 rows
and only privacy-safe display fields derived from the frozen compact source:

- state label and deterministic state order;
- country-coded site label and deterministic site order;
- Work-day adherence estimate and lower and upper 95% confidence limits,
  expressed as percentages;
- the stored site-minus-equal-site contrast and its stored adjusted p-value;
- the exact stored significance indicator;
- the corresponding state-specific equal-site Work-day adherence estimate,
  expressed as a percentage; and
- explicit fields distinguishing the plotted adherence-level quantity from
  the stored site-minus-average significance quantity.

The file must be a lossless deterministic filter, selection, renaming,
ordering, exact keyed join to the three equal-site rows, and multiplication by
100 for percentage display. No row aggregation, model access, prediction,
interval calculation, p-value calculation, FDR adjustment, or participant data
access is permitted.

## Work-day companion forest contract

Add one new reader-facing figure adjacent to and immediately before
`fig-main-site-free-work-contrasts`. Its Quarto label must be
`fig-main-site-workday-adherence` and must occur exactly once with exactly one
caption, one accessible alt text, and one direct link to the paired source CSV.

The figure must:

1. use three vertically stacked panels in the order Wake, Pre-sleep, Sleep;
2. show the same nine country-coded sites in the same deterministic order in
   every panel;
3. plot Work-day adherence percentage and its stored 95% confidence interval;
4. add the state-specific equal-site Work-day adherence percentage as a
   visually distinct long-dashed reference line;
5. emphasize exactly the seven stored FDR-significant site-minus-equal-site
   contrasts with redundant shape and line-weight encoding while retaining all
   20 non-significant rows;
6. use the same 2,640 by 3,360, 300-dpi PNG geometry as the accepted companion
   site-interaction forest unless a source-only check demonstrates that this
   would reduce legibility;
7. preserve every frozen value, interval, label, order, site code, state, and
   significance classification exactly; and
8. remain usable without document-level overflow at the accepted narrow-page
   contract.

The caption must state that the points are pooled-model Work-day adherence
levels, that emphasis denotes the separate stored site-minus-equal-site
contrast result, that the long-dashed line is the state-specific equal-site
Work-day mean, and that sites are neither independent replications nor causal
effects. The alt text must describe the three states, nine sites, reference
lines, and seven emphasized rows without implying ranking, causality, or new
inference.

## Coverage-sensitivity display contract

Regenerate a new amendment-owned display from the exact six-row copied source
without changing the accepted figure label, caption, alt text, or inferential
meaning in the QMD. The QMD may change only the included image path and paired
source link for this figure.

The new PNG and SVG must:

1. preserve all six point estimates, 95% confidence intervals, state labels,
   sample labels, colors, shapes, order, axis labels, title, caption meaning,
   and dashed zero line exactly;
2. retain the historical PNG geometry of 1,680 by 919 pixels at 200 dpi and
   the matching SVG canvas;
3. add visible vertical major grid guides exactly at the labeled x-axis ticks
   `-10`, `-5`, `0`, `5`, `10`, and `15`;
4. keep the dashed zero line visually distinguishable from the grid guide at
   zero; and
5. change no source row, estimate, interval, statistic, or claim.

The new coverage source-data copy must be byte-identical to the frozen source.
The original accepted coverage artifacts remain immutable.

## Source verification and one replacement render

Before rendering, R 4.6.1 source-only checks must verify:

1. every central authority, historical-package, and frozen-input identity;
2. all 111 historical manifest rows and exact preservation of the 109 members
   other than the QMD and HTML endpoints;
3. the exact 27-row, three-state, nine-site, seven-emphasis Work-day contract;
4. exact source-row, key-join, unit-conversion, and no-recalculation provenance;
5. the byte-identical six-row coverage source copy and exact preservation of
   its six plotted estimates and intervals;
6. PNG and SVG parity, declared dimensions and DPI, captions, alt text,
   endpoint labels, paired-source links, and deterministic ordering;
7. exactly one new Work-day figure endpoint and exactly one unchanged coverage
   figure endpoint; and
8. no fit, refit, prediction, new inferential calculation, FDR recalculation,
   resampling, participant disclosure, or change outside the authorized paths.

After every source and display check passes, execute exactly once from the
continuing Brown worktree:

```text
RENV_PATHS_LIBRARY='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library' \
BROWN_ADHERENCE_PROJECT_ROOT='/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026' \
BROWN_ADHERENCE_AUTHOR_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026' \
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

Use R 4.6.1, Quarto 1.9.37, the normal project profile, and narrow elevated
access to the existing author-owned `renv` library from the outset. Do not
first attempt the render under the restricted cache boundary. Do not bypass
`renv`, install a package, modify `renv.lock`, or use a different library.

Stop and seal on a startup failure, render failure, scientific discrepancy,
unexpected identity change, or any requirement for a second render. No second
replacement render is authorized.

## Post-render and visual QA

After the sole replacement render, require complete source, HTML, semantic,
privacy, link, cross-reference, table, figure, no-error, and protected-identity
verification for the whole integrated page. The checks must include:

- exactly 27 Work-day site points and intervals, three state panels, nine
  sites per panel, three equal-site reference lines, and seven emphasized
  stored contrast results;
- exactly six coverage points and intervals, the six labeled vertical guides,
  and the retained visually distinct dashed zero line;
- exact caption, alt-text, endpoint, and paired-source contracts for both
  displays;
- no loss or change to any previously accepted table, figure, source link,
  cross-reference, result, limitation, or privacy condition; and
- exact preservation of the frozen scientific packages and all prior sealed
  evidence.

Apply the already authorized `BA-013` bounded viewport method. Use one secure
server bound only to `127.0.0.1`, inspect the served page at the in-app
browser's native 1280 by 720 viewport, inspect both new PNGs at their declared
intended sizes, and perform deterministic responsive structural checks at
390-pixel width. Do not claim a mobile screenshot or emulated viewport. Do not
use an iframe, CDP, alternate browser surface, or policy workaround.

Inspect the complete page and both amended figure contexts for legible text,
correct guides and reference lines, complete labels, contained overflow,
unobscured captions and source links, and absence of clipping or overlap.
Record observed native visual evidence separately from deterministic narrow
structure. Stop the server, prove that its process and listener are gone, and
rehash all protected paths after QA.

Seal one amendment-owned non-circular final manifest, execution record,
verification record, QA record, screenshots inventory, handoff, and renewed
author gate. Return one combined stopped package on any failure. No additional
source revision or render is authorized within this decision.

## Mandatory author stop and writer status

The mandatory stop remains `BA-CS-G3-INTEGRATED-REVIEW`. The renewed author
gate must supersede only the current QMD, HTML, two amended displays, their
paired sources, and amendment-owned evidence. Every prior gate remains
byte-identical historical evidence.

The required author wording remains:

> Approve Brown cross-state integrated Stage 3 as written.

Stage 4 and notification of Nature Health writer task
`019ffb39-372e-7262-bfac-192751fd0e63` remain blocked until separate central
acceptance and notification authority is issued.

## Reopening condition

Return to the coordinator before editing or rendering if a frozen identity
fails, the exact 27-row or seven-emphasis contract does not reproduce, the
coverage source copy is not byte-identical, a display requires any new
prediction or inferential calculation, a prior sealed member would need
rewriting, the exact path boundary is insufficient, or a second render would
be required.
