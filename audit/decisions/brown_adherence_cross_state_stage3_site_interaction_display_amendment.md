# Brown adherence integrated Stage 3 site-interaction display amendment

Decision ID: `BA-011`  
Change ID: `CHG-150`  
Date: 2026-08-20  
Status: author requested; bounded stored-output display amendment authorized

## Decision

The author found that the unaccepted integrated Stage 3 reader report does not
yet show the site-specific Free-minus-Work interaction as a summary table or
figure. The page currently includes:

1. the global State by Site by Day-type test and the three state-specific
   heterogeneity tests;
2. prose naming the five FDR-significant site-specific localizations; and
3. a compact table of site deviations from the equal-site adherence average
   within Work and Free days.

The third item is not the site-specific Free-minus-Work contrast. The frozen
Boundary Stage 2 output `multiplicity_BA_M4.csv` contains the required 27
any-valid contrasts, one for each of nine sites in each Brown state, with
estimates, 95% confidence intervals, and the accepted 27-member FDR family.

`BA-011` and `CHG-150` authorize one display-only Stage 3 amendment that adds
a three-panel forest plot of those 27 frozen contrasts. It also authorizes one
replacement targeted render and complete amendment-owned verification and
visual QA. It does not reopen Boundary Stage 2, change the integrated report's
scientific content, or authorize a new estimate or inferential calculation.

The existing `BA-CS-G3-INTEGRATED-REVIEW` package remains unaccepted. The
current integrated QMD, HTML, 52-member manifest, handoff, gate, checks, and
visual-QA records remain historical pre-amendment evidence. Stage 4, writer
notification, shared integration, manuscript edits, commit, push, and upload
remain blocked.

## Central authority

The amendment is subordinate to `BA-003`, `BA-004`, `BA-008`, `BA-009`, and
`BA-010`. The immediately controlling central files are:

| Authority | SHA-256 |
|---|---|
| `audit/decisions/brown_adherence_cross_state_stage3_integrated_report_amendment.md` | `fafd7604f22c0c98328447d83cd8bada2b788b339931c564bf052183b00d34df` |
| `audit/decisions/brown_adherence_cross_state_stage3_integrated_report_amendment_manifest.csv` | `3e96ecb8a23931623445d9a857fc49f89aa97279c21434e52dab26e850454d1a` |
| `audit/ledgers/decision_register.csv` after `BA-010` | `dec28e312fa775a644856c9b0c37b74bde5af8f2c4ba5681b0e18c45c28917e9` |
| `audit/ledgers/change_log.csv` after `CHG-149` | `4fd4a03c43de7fbc6527370a10fa3155df037eeead3e946b5ef4b633150ba540` |

The continuing task must verify the unique `BA-011` and `CHG-150` rows and
all prior Brown authority rows before making any source or display change.

## Historical integrated Stage 3 baseline

The following unaccepted package is the exact pre-amendment baseline:

| Artifact | Members | Bytes | SHA-256 |
|---|---:|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 1 | 47,341 | `299e2dcdb9ca8de116dd05fad8e098fbdf4a8182bf93dd1d36dbc349ae4b6ce7` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 1 | 3,893,719 | `ce7ac00d380a405f55a116c3aabc73cc9ba95eb487ee446eb616b76fcff2b468` |
| `stage3_cross_state_association/integrated_report_amendment/integrated_stage3_final_manifest.csv` | 52 | 25,971 | `db7ede8e45280a2c6b38050031b6a6f7ef2334b9ba095f8059410541d74e4d4f` |
| `stage3_cross_state_association/integrated_report_amendment/integrated_stage3_handoff.md` | 1 | 7,519 | `dba0eb267dc0b0c8b9dc3d90957f85f0f4d4bce8e9447ec2cc4f1abd09c4a8b7` |
| `stage3_cross_state_association/integrated_report_amendment/integrated_stage3_author_gate.csv` | 1 | 1,389 | `b0b9d73e061d4309bd6f2bfa9988259bba7b4b81db2aa54660ef723a9f396318` |
| `stage3_cross_state_association/integrated_report_amendment/integrated_finalization_checks.csv` | 1 | 2,009 | `7abb19cc16308dda54499908e28b26287b40c36510a3e5b6ea1ca32f9dc25a49` |

Paths beginning with `stage3_cross_state_association/` are relative to
`audit/analyses/brown_adherence/`.

All 52 historical manifest members must verify before work begins. The QMD
and HTML are the only historical endpoints authorized to acquire new
identities. The historical manifest, handoff, gate, checks, scripts, QA
records, and all other 50 manifest members must remain byte-identical.

The earlier frozen packages must also remain exact at 378 of 378 Boundary
Stage 2 members, 82 of 82 main Stage 3 members, 162 of 162 cross-state Stage 2
members, and 54 of 54 pre-integration cross-state Stage 3 members, with only
the already authorized historical QMD and HTML transitions classified where
applicable.

## Frozen plot inputs

The forest plot must use only these two frozen stored outputs:

| Frozen input | Bytes | SHA-256 | Role |
|---|---:|---|---|
| `audit/analyses/brown_adherence/stage2_boundary/multiplicity_BA_M4.csv` | 13,034 | `49492492cf6d98a439ce4d9708dd8c9d8146e5ab5a5e726040702760dfefda25` | all accepted site-specific Free-minus-Work contrasts and 27-member FDR results |
| `audit/analyses/brown_adherence/stage3/source_data/table_primary_contrasts_source.csv` | 586 | `4e54613d1363ecfa4dc395b76bbee111e3730ee1e886ef106b27d616f867b20e` | state-specific equal-site Free-minus-Work reference estimates |

R 4.6.1 verification of the first input must reproduce:

- exactly 54 total rows, split into 27 `primary_any_valid` and 27
  `support_80` rows;
- exactly 27 primary rows, comprising three Brown states by nine
  country-coded sites;
- exactly one `Free day minus Work day` contrast per state-site cell;
- finite estimates and 95% confidence bounds with the estimate inside its
  interval; and
- exactly five primary rows with `p_adjusted < 0.05` in the accepted BA-M4
  family.

The second input must contain exactly one equal-site reference contrast for
each of Wake, Pre-sleep, and Sleep. Both files and every parent-manifest entry
must remain byte-identical.

## Exact authorized paths

The continuing Brown task may:

1. update only
   `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`;
2. replace exactly once
   `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html`;
3. create the new amendment directory
   `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_interaction_display_amendment/`;
4. create only display-building code, source and render checks, preservation
   records, visual-QA records, and final sealing evidence inside that new
   directory; and
5. create these reader artifacts inside that directory:
   - `source_data/main_site_free_work_forest_source.csv`;
   - `figures/main_site_free_work_forest.png`;
   - `figures/main_site_free_work_forest.svg`;
   - `site_interaction_amendment_final_manifest.csv`;
   - `site_interaction_amendment_handoff.md`; and
   - `site_interaction_amendment_author_gate.csv`.

No existing file in `integrated_report_amendment/` may change except through
the separately authorized QMD and HTML paths outside that directory. Do not
rewrite the historical 52-member manifest or any prior gate, handoff, script,
check, source data, figure, screenshot, or QA record.

No shared configuration, central ledger, main Brown source, Stage 2 artifact,
existing Stage 3 artifact, manuscript, H01 through H11 source, package,
lockfile, commit, push, upload, or full-project render is authorized.

## Paired source-data contract

`main_site_free_work_forest_source.csv` must contain exactly 27 rows and only
the following privacy-safe display fields:

- state and deterministic state order;
- country-coded site label and deterministic site order;
- Free-minus-Work estimate in percentage points;
- lower and upper 95% confidence limits in percentage points;
- accepted BA-M4 FDR-adjusted p-value;
- exact FDR-significance indicator using `p_adjusted < 0.05`; and
- the corresponding state-specific equal-site Free-minus-Work estimate in
  percentage points.

The 27 rows must be a lossless selection of `primary_any_valid` rows from the
frozen BA-M4 file, with only deterministic naming, ordering, logical
classification, and multiplication by 100 for percentage-point display. The
equal-site reference column must be an exact state-keyed join to the frozen
three-row primary-contrast source. No row aggregation, model call,
re-estimation, interval calculation, p-value calculation, FDR adjustment, or
participant-level data access is permitted.

## Forest-plot contract

Add one reader-facing figure immediately after the site-interaction test table
and localization explanation, before the existing compact site-by-day-type
adherence table. Its Quarto label must be
`fig-main-site-free-work-contrasts` and must occur exactly once with exactly
one caption.

The figure must:

1. use three vertically stacked panels in the order Wake, Pre-sleep, Sleep;
2. show all nine country-coded sites in every panel;
3. place the site-specific Free-minus-Work estimate on the horizontal axis
   with its 95% confidence interval;
4. include a clearly distinguishable zero line and a state-specific equal-site
   reference line;
5. emphasize exactly the five BA-M4 FDR-significant primary contrasts using
   redundant non-colour encoding, such as filled versus open points, while
   retaining every non-significant contrast;
6. label the horizontal axis in percentage points and make clear that positive
   values indicate higher adherence on Free days and negative values indicate
   lower adherence on Free days;
7. use the same deterministic site order across all three panels;
8. preserve all estimates, intervals, p-values, state labels, site labels,
   directions, and the 27-member multiplicity family exactly; and
9. provide a direct reader link to the paired source CSV.

The caption must state that the estimates come from one pooled interaction
model, that sites are not independent replications or causal effects, that
filled symbols mark the five contrasts passing the accepted 27-member FDR
family, and that the reference line is the equal-site estimate for that
state. The alt text must identify the three states, nine sites, zero and
equal-site references, and the five emphasized contrasts without implying
rank, causality, or independent replication.

The PNG and SVG must have identical data, ordering, labels, geometry, and
semantic meaning. Dimensions, DPI, font sizes, and export versions must be
recorded. The exported PNG at its declared intended size controls artifact
legibility. The HTML figure must remain usable on narrow screens, either by
retaining at least 7-point effective text or by a clearly contained and usable
horizontal-scroll treatment. No document-level overflow is allowed.

## Verification and one replacement render

Before rendering, a new R 4.6.1 source-only verifier inside the amendment
directory must check:

1. all central authority and frozen-package identities;
2. the exact 27-row, three-state, nine-site, five-significant paired-source
   contract and the three equal-site references;
3. exact source-row and unit-conversion provenance;
4. unique label, single caption, paired-source link, caption, and alt-text
   contracts;
5. no model object load for estimation, fit, refit, prediction, diagnostic,
   inferential calculation, simulation, resampling, or FDR recalculation;
6. no change outside the QMD and new amendment directory; and
7. exact preservation of every historical file.

After that source gate passes, the task may execute exactly once:

```text
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

Use R 4.6.1, Quarto 1.9.37, and the normal project profile. If sandboxed
`renv` activation requires cache access, use only the established narrow
access to the existing user-owned `renv` cache. Do not bypass `renv`, modify
`renv.lock`, install a package, or change a library.

After the render, require:

- complete source and HTML verification for all existing integrated-report
  contracts plus the new figure;
- exact figure and paired-source checks, including 27 plotted estimates, 27
  intervals, three zero lines, three equal-site reference lines, nine sites
  per panel, and exactly five emphasized contrasts;
- native `gt`, cross-reference, link, privacy, error, and protected-identity
  checks for the whole page;
- visual inspection of the new PNG at intended size and the complete page at
  1440 by 1000 and 390 by 844 through one secure `127.0.0.1` loopback server;
- desktop and narrow inspection of the site-interaction section, figure,
  caption, source link, surrounding tables, and complete page flow;
- complete server teardown, proof of no remaining listener, and post-QA
  identity stability; and
- one non-circular final manifest, handoff, and author-gate record in the new
  amendment directory.

Stop and return one sealed failed state on any unexplained identity change,
row or value mismatch, scientific recalculation, missing contrast, privacy
issue, render failure, broken link, material semantic or visual defect, or
incomplete teardown. No second replacement render is authorized.

## Mandatory stop and writer status

The mandatory author stop remains `BA-CS-G3-INTEGRATED-REVIEW`. The new
`site_interaction_amendment_author_gate.csv` must supersede the prior
unaccepted gate only for the current QMD, HTML, figure, source-data, and
amendment-evidence identities. The prior gate remains byte-identical
historical evidence.

The required author decision remains:

> Approve Brown cross-state integrated Stage 3 as written.

Stage 4 and writer notification remain blocked until that explicit approval.
Do not notify Nature Health writer task
`019ffb39-372e-7262-bfac-192751fd0e63` before a separate central acceptance
and notification authority is issued.

## Reopening condition

Return to the coordinator before source change or rendering if a frozen
identity fails, the 27-row BA-M4 contract does not reproduce, the figure
requires any new inferential or participant-level calculation, a prior sealed
file would need rewriting, the exact path boundary is insufficient, or a
second render would be required.
