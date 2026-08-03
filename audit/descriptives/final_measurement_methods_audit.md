# Final measurement-methods audit: descriptive tables and figures

## Verdict

**Ready for descriptive-task handoff.** No open defect was detected in the
current prepared-input-to-report chain. The rebuilt descriptive outputs match
their final manifest, the displayed denominators reconcile to the approved
sample contract, figure source-data links resolve, and the rendered HTML uses
the registered site convention and accessible resource markup.

This verdict is scoped to the descriptive rebuild. It accepts the 12 pinned
shared preparation manifests as the upstream checkpoint and does not repeat
the coordinator-owned raw-import, calibration, or full state-alignment audit.
It does not audit models, hypothesis notebooks, the manuscript, or central
ledgers.

## Audit contract and evidence

- Branch and inspected HEAD: `rewrite/NH` at
  `b2f0415c54806d67e3466091ea67f33b9fed3232`; this audit also covers the
  uncommitted descriptive worktree outputs listed in the final manifest.
- Authoritative sample rules: ≥80% of the complete real 24-hour cycle;
  exact-all-zero day exclusion; near-eye primary and chest complementary;
  placements never pooled; sleep and declared non-wear as defined by the
  shared preparation contract.
- Shared manifest evidence:
  `audit/descriptives/shared_manifest_verification.csv` (12/12 `PASS`).
- Consumed-file evidence:
  `audit/descriptives/prepared_input_provenance.csv` (20/20 `PASS`).
- Display evidence:
  `config/site_display_registry.csv` and
  `audit/descriptives/site_display_registry_provenance.csv`, registry SHA-256
  `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.
- Output evidence:
  `artifacts/12_manifests/descriptives/descriptive_artifacts.csv`, containing
  68 current file hashes, manifest SHA-256
  `69c4398a5ba57e396e64ecaefb52ea820e445b859bab3cf73f3d3f5576338e8c`.
- Figure lineage:
  `artifacts/12_manifests/descriptives/figure_source_data_map.csv`, containing
  21 source-file links and hashes for six figures.
- Visual-replication evidence:
  `audit/descriptives/visual_export_comparison.csv` contains all four table
  and six figure original/rebuilt path, hash, and dimension pairs;
  `audit/descriptives/visual_export_review.md` records native-resolution review
  and every required visible difference.
- Software evidence:
  `audit/descriptives/package_versions.csv` and
  `audit/descriptives/session_info.txt` (R 4.6.1; consequential package
  versions recorded); ENV-001 `renv.lock` SHA-256
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`,
  246 package records, and bounded status result
  `RENV_STATUS_SYNCHRONIZED=TRUE`.
- Report evidence:
  `notebooks/descriptives.qmd` and
  `_build/nathealth/notebooks/descriptives.html`.

## Findings

### Open findings

None.

### Confirmed findings resolved before this final audit

| ID | Severity | Confidence | Category | Evidence and violated invariant | Consequence | Resolution and closing verification |
|---|---|---|---|---|---|---|
| DESC-LEGACY-01 | High | Confirmed | sample/reporting | Read-only old-output inventory showed placement pooling, near-eye non-wear reused for chest, an incorrect chest completeness stage, and interchanged MPI/TUM institution labels. Placements and denominators must remain distinct. | Old cells and panels could describe the wrong placement or denominator. | Rebuilt from pinned prepared artifacts; cell-level old/new comparisons recorded; 816 near-eye, 902 chest, and 643 paired days reconcile independently. |
| DESC-CIRC-01 | High | Confirmed | metric/reporting | `audit/descriptives/circular_summary_repair_proposal.md` and `audit/descriptives/metric_group_context_repair_proposal.md`. A transient `quantile()` argument typo and dropped `group_modify()` keys made timing summaries vulnerable to linear treatment and wrong denominator context. | Clock-time summaries and participant-day denominators could be wrong. | Corrected before final output; independent circular checks and positive metric-specific observation/participant/day assertions pass in a clean R session. |
| DESC-PLOT-01 | Low | Confirmed | reporting | `audit/descriptives/final_audit_repair_proposal.md`. Pseudo-log labels overlapped and terminal 24:00 was clipped. | Publication readability only. | Deterministic axis annotations repaired; all six final PNGs and JPEGs were inspected directly, all six PDFs were rendered and inspected, and all SVGs parse. |
| DESC-STYLE-01 | Low | Confirmed | reporting | `audit/descriptives/table_figure_style_replication_repair_proposal.md`. The first rebuild used a different table theme and changed several figure themes, dimensions, and encodings despite correct content. | It did not satisfy the requested submitted-style replication. | The final tables reuse the submitted `gt` grammar and viewports; figures reuse submitted layouts and physical dimensions. Ten original/rebuilt pairs were reviewed at native resolution. The contextual Overall row additionally has the user-requested 6-pixel white divider. |
| DESC-HTML-01 | Low | Confirmed | reproducibility/accessibility | `audit/descriptives/html_publication_repair_proposal.md` and `audit/descriptives/thumbnail_accessibility_export_repair_proposal.md`. Absolute figure paths became invalid `../Users/...` URLs, and Quarto removed thumbnail `alt` attributes while rewriting embedded images. | Broken portable figures and inaccessible redundant thumbnails. | Source-relative resources resolve under `_build`; six figure images retain non-empty alt text; 17 metric-specific descriptions are visually hidden and 17 redundant images are marked `aria-hidden` and presentational in the rendered DOM without changing the table PNG. |
| DESC-DISPLAY-01 | Low | Confirmed | reporting | `audit/descriptives/display001_visual_repair_proposal.md`. Final visual inspection found internal codes on the latitude diagnostic. | One figure violated DISPLAY-001 visible labels. | Both latitude helpers use the shared registry; the final SVG contains all nine registered labels in registered order and the raster was re-inspected. |
| DESC-EXPORT-01 | Low | Confirmed | reproducibility/deliverables | The active completion contract required PDF and JPEG for every figure, but the inspected figure set initially contained PNG/SVG only. | The visual analyses were complete, but the requested publication delivery set was incomplete. | The single R export helper now writes PNG, maximum-quality JPEG, deterministic one-page PDF, and SVG from each verified plot. Tests enforce six of each, exact dimensions, valid PDF/JPEG structure, manifest coverage, and byte-for-byte rebuilds. |

## Claim-to-source traceability

| Claim/output | Authoritative source | Producing step | Status |
|---|---|---|---|
| Roster and main sample flow | normalized inputs, placement coverage files, `audit/descriptives/sample_count_contract.csv` | `build_descriptive_data.R` | Verified |
| Participant/site Table 1, extended and manuscript variants | `participant_site_characteristics_replica.csv`; `participant_site_characteristics_manuscript_replica.csv` | `build_descriptive_replications.R`; native `gt` in `build_publication_tables.R` | Verified |
| Near-eye metric Table 2 | pinned `metrics_glasses_*` artifacts; `metric_descriptive_summary_replica.csv` | `build_descriptive_replications.R`; native `gt` in `build_publication_tables.R` | Verified |
| Overview and placement profiles | `collection_days.csv`, `profile_summary.csv`, `profile_context_bands.csv`, `profile_average_periods.csv`, site/map/protocol sources | `build_descriptive_data.R`; `plot_descriptive_replications.R` | Verified with LightLogR-pooled 15-minute profiles and declared non-wear omitted |
| Metric distribution figure | `metric_plot_values.csv` from verified metric artifacts | `plot_descriptive_replications.R` | Verified |
| Time-series explanation | four `time_series_replica_*` CSVs | `build_descriptive_replications.R`; `plot_descriptive_replications.R` | Verified for the seven V0 participants, V0 study days 2–6, increasing TAT250 order, and LightLogR 30-minute means |
| Latitude diagnostic | `latitude_photoperiod.csv` from verified solar context | `plot_descriptive_replications.R` | Verified |
| Brown et al. contextual table | `recommendation_context_near_eye.csv`, `recommendation_context_replica.csv` | `build_descriptive_data.R`; native `gt` in `build_publication_tables.R` | Verified with contextual, non-adherence wording |
| Site labels, order, colours | `config/site_display_registry.csv` | registry helpers in `descriptive_contract.R` | Verified |
| Stand-alone publication exports | Four table replica CSVs; all mapped figure source CSVs; retained submitted PNG comparators | `build_publication_tables.R`, `plot_descriptive_replications.R`, and `build_descriptives.R` | Verified in the 10-row visual comparison and native-resolution review |
| Reader-facing HTML | all objects above | `notebooks/descriptives.qmd` under the `nathealth` profile | Verified |

## Sample and join-cardinality reconciliation

- Normalized roster: 191 participants.
- Near-eye: 818 days pass coverage before the all-zero screen; 2 all-zero
  days are excluded; final 141 participants, 816 participant-days, and
  1,175,160 real one-minute rows.
- Chest: 905 days pass coverage before the all-zero screen; 3 all-zero days
  are excluded; final 154 participants, 902 participant-days, and 1,298,880
  real one-minute rows.
- Paired main subset: 112 participants and 643 participant-days.
- `collection_days.csv`: 1,718 unique placement/site/participant/date keys,
  exactly 816 near-eye plus 902 chest.
- `profile_summary.csv`: 1,824 placement/site rows, with exactly 96 fixed
  15-minute bins per panel; each pooled median lies within the pointwise
  central 67% Overall bounds and nested central 50%, 75%, and 95% site-profile
  bounds. These are empirical value intervals, not confidence intervals.
- Metric publication data: 17 metrics × 10 display columns = 170 unique cells;
  every cell has positive observation, participant, and participant-day
  denominators.
- Time-series sources: seven fixed participants, 35 participant-days, 1,680
  unique half-hour bins, and exactly one joined verified daily metric per day.
- Latitude source: 816 unique main near-eye participant-days.
- Context table: overall plus nine sites, with eligible, wake, pre-sleep, and
  sleep minute denominators retained.

## Reproducibility, rendering, and accessibility

- The production build and final Quarto render completed in fresh R 4.6.1
  sessions using the activated project library.
- `tests/descriptives/run_tests.R` passed from a fresh R process with
  `All descriptive tests passed.`
- All 77 manifested files, all figure-source hash links, and all ten
  original/rebuilt visual-comparison hashes match.
- Six figure PNGs and six JPEGs have their declared 300-dpi pixel dimensions;
  six one-page PDFs have the declared physical page sizes and full-page raster
  dimensions; six SVGs parse as SVG. Four table PNGs use 1200-, 1200-, 1800-,
  and 992-pixel `gtsave()` viewports, and their widths remain close to the
  submitted comparator widths.
- Direct native-resolution inspection beside the submitted comparators found
  no clipping, broken band, stray layer, or unreadable label in any of the
  four table PNGs or six figure PNGs. Structural tests verify the JPEG, PDF,
  and SVG companion exports. The contextual Overall row has the final
  user-reviewed 6-pixel white divider.
- Rendered HTML contains four native `gt` tables; all
  six external figure paths are portable and resolve; each has non-empty alt
  text.
- The 17 miniature distributions are redundant to exact adjacent table cells;
  each has a metric-specific visually hidden description, while the image is
  hidden from assistive technology.
- Rendered-HTML structural inspection counted six figure alt texts, 17 hidden
  thumbnail descriptions, 17 decorative thumbnail markers, and four native
  `gt` tables. Standalone table and figure exports were reviewed at native
  resolution; local `file://` reload was unavailable under the in-app browser's
  security policy, so no browser-render claim is made.
- The bounded source-aware ENV-001 check completed in approximately 6.7 seconds with exit
  status 0 and `RENV_STATUS_SYNCHRONIZED=TRUE`.

## Evidence limitations and unresolved risks

- No raw-device or manuscript-number audit was repeated because those files
  are outside this task's ownership. Their upstream state is represented by
  the pinned shared manifests.
- ENV-001 resolved the previous dependency-snapshot limitation. Later package
  installation or `renv.lock` changes remain coordinator-owned.
- No open scientific or presentation gate was found for the descriptive
  handoff.

## Implementation handoff

No further R, Quarto, data, or documentation repair is required inside the
descriptive scope. Coordinator review is limited to the proposed central
ledger entries in `audit/handoffs/descriptives_worker_handoff.md` and any
later manuscript integration.
