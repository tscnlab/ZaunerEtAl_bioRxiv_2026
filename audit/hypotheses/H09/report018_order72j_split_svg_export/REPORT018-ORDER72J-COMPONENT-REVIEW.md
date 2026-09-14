# REPORT018-ORDER72J-COMPONENT-REVIEW: H09 return

Date: 2026-09-11

Status: `CANDIDATE_PASS_AWAITING_INDEPENDENT_ACCEPTANCE`

## Authority and scope

The controlling order is
`audit/report_harmonization/owner_orders/72j_native_svg_component_exports_and_optional_compatibility.md`,
SHA-256 `ed7c0b94b5ad380e1ec8b29d09aec07eedda9fdfa5c5ad8752f2b9dd913e182a`.
The independent release acceptance is
`audit/report_harmonization/report018_order72j_component_exports_release/independent_preflight_acceptance.md`,
SHA-256 `8e5d95479865fa4b71f11a133ae08b6aa2b067976305b190f267ac14d8514cd3`.

All new writes are confined to
`audit/hypotheses/H09/report018_order72j_split_svg_export/`. Existing source,
figure, model, manifest, QMD, HTML, Quarto, Word, profile, and lock files were
not changed. No model or inferential RDS was read. No data preparation, model
method, prediction, inference, multiplicity calculation, broad builder,
Quarto render, or Word generation was run.

## Native SVG candidates

| Component | Candidate | SHA-256 | Bytes | Native dimensions |
|---|---|---|---:|---:|
| Primary effects | `candidate/H09_primary_effects.svg` | `a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a` | 20,707 | 1134 × 702 pt |
| Observed timing patterns | `candidate/H09_observed_timing_patterns.svg` | `c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3` | 1,245,097 | 1134 × 918 pt |

Each candidate is byte-identical to its retained single native `svglite`
trial in `attempts/trial_01/`. There were zero renderer corrections. The first
and only export command wrote and closed both SVG device outputs, then exited
nonzero in a validation-only assertion because scalar `&&` was applied to a
two-element existence vector. The assertion was corrected to vectorized `&`.
Neither device was rerun. The existing trial files passed the complete static
gate before they were copied together into `candidate/`.

## Frozen inputs and plotting implementation

The only scientific display inputs read were:

| Input | SHA-256 | Bytes | Rows |
|---|---|---:|---:|
| `artifacts/11_source_data/H09/H09_primary_effects_data.csv` | `3972ae75c9aef8551cc85f50d7a438b35b7a55dca58d81f3630133132a25aaf6` | 6,778 | 20 |
| `artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv` | `34640aba210181b973902e00cd6924f79f6ae76faf01fa3c5b66078e2e2e7cee` | 3,028,981 | 5,678 |

The observed source contains 4,701 participant-day point rows, 606 sealed
model-line and interval rows, and 371 de-identified participant-level
chronotype overview rows. The primary source contains the complete 20-row
metric, instrument, and placement grid.

Four copied functions match their pinned source expressions exactly:
`geom_errorbarh_frozen()`, `make_primary_plot()`, `h09_clock_labels()`, and
`h09_make_stage3_observed_plot()`. The detailed expression hashes are in
`evidence/copied_function_checks.csv`.

Implementation identities are:

| File | SHA-256 |
|---|---|
| `code/build_h09_order72j_svg_exports.R` | `3b8a0d3f071a21b264970bf864f2efdf987f30046e24f913a41f8c56832e739c` |
| `code/check_h09_order72j_svg_exports.R` | `15a677cf1e74b4b21820fcb113e641edfa0f8be03f2706fd6fcc6f1e51cce1ff` |
| `code/seal_h09_order72j_component_review.R` | `db3a27237b0e6f829500612984b3af6f39490fdbe5b2d6b5bf53860621f501d4` |

All three R files parse under R 4.6.1 and pass `air format --check` and
`git diff --check`.

## Static and scientific-preservation checks

The preflight passed 123 of 123 release-manifest rows, 37 of 37 H09 execution
pins, and 566 of 566 H09 preservation rows. The same three inventories passed
again after candidate sealing.

Eight plot-layer mappings passed before and after export. They preserve the
20 point estimates and 20 horizontal 95% intervals in the primary display;
4,701 participant-day points, 606 model lines, 606 model interval rows, 371
chronotype points, and the deterministic 18-group boxplot geometry in the
observed display. Site labels, ordering, colours, shapes, metric and instrument
panels, placement encodings, state fields, line meaning, and interval values
remain those of the frozen CSVs.

Both trials and both sealed candidates pass XML parsing. Across the two trial
files, all 30 structure checks passed: zero image, script, foreign-object,
raster, external-link, or external-CSS resources; unique IDs; all local
references resolved; expected dimensions and viewBoxes; all required visible
labels; and zero identifier or SHA leakage in visible text or metadata. The
same 30 checks passed again on the candidate copies.

The accepted PNG and PDF comparators remain exact under the input and
preservation pins. They were not modified or used as vector sources.

## Runtime, attempts, and visual hold

R was 4.6.1 with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` and the accepted
project R 4.6 library. Exact commands, library paths, package versions, session
records, stopped preflight attempts, and wall times are retained under
`evidence/`.

No serial visual-QA lease was issued. No browser, office application, static
server, or loopback listener was started, and `qa/` remains empty. Therefore
this return is static candidate acceptance only. Original-size, 170 mm, and
708 px visual comparison against the accepted PNG/PDF remains deferred to the
Harmonizer's serial lease. Native Word compatibility also remains provisional.

The sibling `non_circular_manifest.csv` is generated after this handoff and
excludes itself and future coordinator records. No candidate is promoted by
this return.
