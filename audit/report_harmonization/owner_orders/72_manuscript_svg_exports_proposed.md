# Proposed owner order 72: native SVG exports for seven manuscript figures

Date: 2026-09-11

Workflow: `REPORT-018`

Status: **PROPOSED, NOT RELEASED, DO NOT EXECUTE**

Central owner: Coordinator task `019faf58-3df3-7383-8034-f715cdfdd154`

## Author direction and current blocker

The author requires SVG as the manuscript source format. The current Nature
Health manuscript has 20 selected figures. Thirteen have accepted SVG
counterparts or are already current SVG inputs. Seven accepted displays have
no SVG endpoint. No exact owner-scoped export order or dispatch receipt was
found for those seven endpoints.

This packet is a proposed release document only. It does not authorize an
owner task to start. The Coordinator must pin this packet, record its release,
and send the applicable section to each owner task before any work begins.

The Writer may integrate the 13 already accepted SVG inputs now. The Writer
must hold the seven figures in this packet at their accepted PNG identities
until central independent acceptance supplies an exact SVG path and SHA-256.

## Common export contract

Every owner section below is a separate candidate-only export job under R
4.6.1. Each job must:

1. Reproduce every pinned accepted PNG, PDF, frozen plotting-source, and
   builder identity before any write.
2. Read only the frozen plotting source listed for that figure. Do not read a
   model object or rebuild an analytical dataset when the listed frozen
   plotting source is sufficient.
3. Create a minimal export-only R script in the listed evidence root. The
   script may reproduce only the pure plotting code from the accepted builder
   reference and add one native SVG device call. Reconstruct the plot only
   from frozen display columns and the pinned factor, palette, night-shading,
   sample-label, and display-text inputs. It must not execute a broad analysis,
   reporting, or Quarto builder, read a model archive, or calculate a
   prediction, interval, p-value, or scientific summary.
4. Write a native vector SVG to the evidence-root `candidate/` directory.
   Do not embed the accepted PNG or another raster image inside the SVG.
5. Preserve the accepted canvas ratio, panel structure, visible labels,
   values, ordering, colours, scales, legends, geometry, and whitespace.
   Preserve existing panel tags, capitalization, and positions exactly. Do
   not add a tag to an untagged display or move a tag in this format-only
   export. This is a format export, not a redesign.
6. Render the candidate SVG to the accepted PNG pixel dimensions for visual
   comparison. Record unclipped text, matching panel and layer geometry,
   matching colour mapping, matching legend content, and matching visible
   scientific tokens. Raster antialiasing differences alone are not a
   failure.
7. Verify that the SVG contains vector drawing elements and does not contain
   a raster payload, participant identifier, hidden data payload, external
   resource, script, or unresolved font resource.
8. Record the candidate SVG SHA-256, byte size, `viewBox`, width, height,
   source hashes, script hash, R version, consequential package versions,
   semantic checks, visual checks, and `sessionInfo()` in a non-circular
   completion manifest.
9. Stop once on any source-pin, export, semantic, visual, or manifest failure.
   Do not patch and retry in the same order.

No canonical artifact, accepted PNG/PDF, QMD, HTML, DOCX, model, prediction,
source data, scientific table, manuscript source, central ledger, shared
configuration, package lockfile, or production render may be modified.

## H02: Main Figure 2

Owner task: `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Evidence root:
`audit/hypotheses/H02/report018_order72_svg_export/`

Candidate endpoint:
`audit/hypotheses/H02/report018_order72_svg_export/candidate/figure4_exact_layout_replication.svg`

Pinned inputs:

| Role | Path | SHA-256 |
|---|---|---|
| accepted PNG, 3300 x 4200 px | `artifacts/10_figures/H02/figure4_exact_layout_replication.png` | `2d31f38a169659b37a16c44b9845605186709e4dc7734a8f97342408711f9ac2` |
| accepted PDF | `artifacts/10_figures/H02/figure4_exact_layout_replication.pdf` | `daccad7889e79d11980e0543f154421d3d238c0b2c3e34ddae42de3b31106ba4` |
| frozen plotting source | `artifacts/11_source_data/H02/figure4_exact_layout_source.rds` | `63ea7588e5a19f5df64710e54d647b18cc74bc7c87dc7e8829bf65b7dfea825b` |
| accepted provenance reference, never execute | `scripts/hypotheses/H02/build_h02_figure4_replication.R` | `aed917fa24180d7e2bb0a30917046f43cf55fcdc50b11e667b175282148d9d00` |
| pure pointwise layout helper | `scripts/hypotheses/H02/h02_figure4_pointwise.R` | `ba6ae587bb8cde296f4273f5c40dd97a073bf1df422c694481404ae8ad3475ae` |
| bracket layout helper | `scripts/Brown_bracket.R` | `55f82d40dec1ff287fc2e0a36bc09ca9e8bcb5f382d679410cf5e975b0ac5de0` |

The candidate must preserve the accepted four-panel composition as one SVG.
Extract only the pure layout function. Reconstruct layout-only factor,
palette, night-shading, and background-replication objects from fields already
stored in the frozen RDS. Never call `h02_build_figure_contract()` or execute
the broad builder because those paths read fitted models and calculate
predictions and intervals.

## H06: Supplementary Figures S9 and S12

Owner task: `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Evidence root:
`audit/hypotheses/H06/report018_order72_svg_export/`

Candidate endpoints:

- `audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_paired_placement_effects.svg`
- `audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_stage3_site_specific_significance_screen.svg`

Pinned inputs:

| Display | Role | Path | SHA-256 |
|---|---|---|---|
| S9 | accepted PNG, 2141 x 1511 px | `artifacts/10_figures/H06/H06_paired_placement_effects.png` | `e0a63c615a5422d28e1af7d2cc15ca29e65057b7639308c5cbdcb028e25f9478` |
| S9 | accepted PDF | `artifacts/10_figures/H06/H06_paired_placement_effects.pdf` | `035f8a32d2356d33280d6f8945bbef7b4e5ba24d6c0fbd4fe251296eac0c7fa7` |
| S9 | frozen plotting source | `artifacts/11_source_data/H06/H06_paired_placement_effects_figure.csv` | `b50dc0a8db8396666fb1ea8cf18cfbf01bb3bb022973755de0edcf835168fba2` |
| S9 | accepted builder reference | `scripts/hypotheses/H06/build_h06_stage2_reader_artifacts.R` | `3588b7440c4d5b0f7614034762c40cb62cb7e0fe36c32ff896dd1237df4c3291` |
| S12 | accepted PNG, 2141 x 1700 px | `artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.png` | `88aeef89cda1208a80ead843ca9551011350ed5f78734c57ceee380bf994f02e` |
| S12 | accepted PDF | `artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.pdf` | `fc5d39926af682d629bca21966dd68dbc9bda89e51a511003004d033d6185694` |
| S12 | frozen plotting source | `artifacts/11_source_data/H06/H06_stage3_site_specific_significance_screen_figure.csv` | `8d15804a66a6589b6c6f408db147e65c0fa2a42f71cd32fb1dcd2acd6657d642` |
| S12 | accepted builder reference | `scripts/hypotheses/H06/build_h06_stage3_site_specific_screening.R` | `e92aedc03a2f5e75e9c6ce884498ebb69fa8ea79af4ce122325fc2dd26ebd7cd` |
| S12 | shared site display registry | `config/site_display_registry.csv` | `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809` |

Current S12 is the H06 site-specific significance screen. It is not the
removed H06_daily display. Do not reinstate or modify H06_daily.
For S12, use the shared registry only for ordering and colours. Require exact
agreement between its relevant fields and the registry fields already frozen
in the 27-row display CSV. Extract only the plotting code after source
derivation. Do not run the model-reading screening builder.

## H05: Supplementary Figure S13

Owner task: `019fba35-6fd8-73c3-970f-e41f8b759bb6`

Evidence root:
`audit/hypotheses/H05/report018_order72_svg_export/`

Candidate endpoint:
`audit/hypotheses/H05/report018_order72_svg_export/candidate/H05_reader_near_eye_effects.svg`

Pinned inputs:

| Role | Path | SHA-256 |
|---|---|---|
| accepted PNG, 2700 x 2700 px | `artifacts/10_figures/H05/H05_reader_near_eye_effects.png` | `70c1013d51f7619fafe0d38664db7dcf55692990993098948ed443e83c35e1a5` |
| accepted PDF | `artifacts/10_figures/H05/H05_reader_near_eye_effects.pdf` | `81977488d595dd660202ea3e498f6db26bbf27bb79bf4955cd8d5796a8851337` |
| frozen plotting source | `artifacts/11_source_data/H05/H05_reader_near_eye_effect_figure_data.csv` | `e563514cfac059a284d0c38ad733bef708f92ba13fec6686e0aa07804e835ec1` |
| frozen common-scale companion | `artifacts/11_source_data/H05/H05_reader_chest_effect_figure_data.csv` | `c7b976fff6d43af5adb64fbb67c6fa348d357ad43e856ba7664c2edbeac719eb` |
| accepted builder reference | `scripts/hypotheses/H05/build_h05_reader_artifacts.R` | `7cecc2ec14b23085c50da300f04a1506f161df755e21ff636ed92ac1a84a6177` |

Use the frozen chest rows only to recover the accepted common colour limit
across both placements. Plot only the near-eye rows and use the stored
`effect_fill` and `effect_label` fields. Do not read model tables.

## H08: Supplementary Figure S14

Owner task: `019fbdb6-b6a8-7e53-8e84-7a2967af9ea5`

Evidence root:
`audit/hypotheses/H08/report018_order72_svg_export/`

Candidate endpoint:
`audit/hypotheses/H08/report018_order72_svg_export/candidate/H08_near_eye_effects.svg`

Pinned inputs:

| Role | Path | SHA-256 |
|---|---|---|
| accepted PNG, 2007 x 1606 px | `artifacts/10_figures/H08/H08_near_eye_effects.png` | `f1cc8e33829cdf821140e95238d20b1516d5796f741002a1f27568d3f9fd7405` |
| accepted PDF | `artifacts/10_figures/H08/H08_near_eye_effects.pdf` | `4f5b3201703036fa5320433c6e600f8cc8ba84b20b6015f89ccac517381415fe` |
| frozen plotting source | `artifacts/11_source_data/H08/H08_near_eye_effects_data.csv` | `0f7ab7b06a23a16089b000607d4cfb239c323ba39df9c549c365c4da1878dd51` |
| frozen metric-order registry | `artifacts/06_model_data/H08/H08_metric_registry.csv` | `ba60163a1248a03c6c95cfa36fc0b66801f1fdd4af2fa114e024944c2aa3893f` |
| accepted builder reference | `scripts/hypotheses/H08/rebuild_h08_reader_figures.R` | `96be883521683fbb951b715dd14b5eb1b6986abd5cfdf60f21fecc4e8857302c` |

Use the pinned registry only to reproduce the accepted metric factor order.

## H10: Supplementary Figure S16

Owner task: `019fdc1b-b77b-7972-aed0-784da328e115`

Evidence root:
`audit/hypotheses/H10/report018_order72_svg_export/`

Candidate endpoint:
`audit/hypotheses/H10/report018_order72_svg_export/candidate/H10_age_site_significant_associations_selection_candidate.svg`

Pinned inputs:

| Role | Path | SHA-256 |
|---|---|---|
| accepted selection PNG, 2820 x 3900 px | `audit/manuscript_nature_health/figure_table_selection_assets/H10_age_site_significant_associations_selection_candidate.png` | `e989646f21543203ef07916dde8917e85243667d54b5aa492815476edc6c4b60` |
| canonical PDF, reference provenance only | `artifacts/10_figures/H10/H10_age_site_significant_associations.pdf` | `5f5c5cdf91b62dbe3fbb2cd215d6f1658d1835c62eab5504d9aa3570a60de5cf` |
| frozen plotting source | `artifacts/11_source_data/H10/H10_age_site_significant_associations_data.csv` | `5f06ab98bada441d02123e56d073e52bfacae75c0277ab73803efd401c33c8fd` |
| accepted selection display-text contract | `audit/hypotheses/H10/manuscript_selection_figure_candidate/candidate_display_text.csv` | `e34ffd6de2bf1abb1e50a1474fd8c84611a2cef9ee7a8b9b4e7b971a25bb3ce5` |
| accepted selection builder reference | `audit/hypotheses/H10/manuscript_selection_figure_candidate/build_h10_selection_figure_candidate.R` | `5a2f9cb8fee62a5f19002405db4bb4868a7a1b13ebc950719335dd33458b8c7c` |

The candidate must reproduce the accepted manuscript selection layout, not
the broader canonical H10 layout. Preserve the frozen 322-row display source
and all current labels. The accepted selection PNG and display-text contract
control the SVG. The canonical PDF is reference provenance only.

## H11: Supplementary Figure S17

Owner task: `019fba59-0f3c-74a0-ab3d-58d389365ad1`

Evidence root:
`audit/hypotheses/H11/report018_order72_svg_export/`

Candidate endpoint:
`audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg`

Pinned inputs:

| Role | Path | SHA-256 |
|---|---|---|
| accepted PNG, 3150 x 3300 px | `artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.png` | `33ac814200fc1d69dcf462d0a156b2b950ef0588f47974881fb56f140a414f70` |
| accepted PDF | `artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.pdf` | `ff99643a56830938de7c70cfb60acce43282c0de4a300a8e28231776c6a3616a` |
| frozen plotting source | `artifacts/11_source_data/H11/stage3/H11_reader_sex_specific_curves.csv` | `76d733c5d04dd6e359aa85b578e54c5d4f292296fa2f5a17e03282856fbc72f3` |
| frozen lower-panel contrasts | `artifacts/11_source_data/H11/stage3/H11_reader_female_minus_male_contrasts.csv` | `f1950da8a8ffc9d4e344604e384dc2c1facd99610039226d82df1210780cf5fb` |
| frozen night-shading context | `artifacts/11_source_data/H11/stage3/H11_reader_solar_context.csv` | `acdb226b5e93123f893cb8a6f59382fc87c0fc2a39a9be1d9648f92acdddd793` |
| frozen sample labels | `artifacts/09_tables/H11/stage3/H11_reader_samples.csv` | `2aa7c87705db6068c410319eccbc35036b65fbac678c5ab4409581109315d58c` |
| accepted builder reference | `scripts/hypotheses/H11/build_h11_stage3_figures.R` | `405b357920ce9ba15d4fadd3f34d4ebd33f19ab463b89d856d46ab125318fde2` |

The existing filename is frozen provenance. Reader-facing manuscript text
must continue to omit redundant `primary` wording where `near-eye` is
sufficient.
Use only the four frozen H11 display inputs above to reproduce the upper and
lower panels, night shading, and sample annotation. No residual, activity, or
fitted-model source is required or allowed for this target.

## Central acceptance and Writer release

Owner completion is not manuscript acceptance. After all released owner jobs
return, the Coordinator must commission one independent read-only acceptance
that checks:

- exact reproduction of every pinned input;
- native-vector SVG structure with no embedded raster payload;
- accepted visible text and scientific-token equivalence;
- accepted geometry, canvas ratio, panel order, existing panel-tag content
  and position, colours, scales, legends, and unclipped labels;
- absence of participant identifiers, hidden data payloads, scripts,
  external resources, and embedded raster images;
- a unique candidate path and SHA-256 for each of the seven figures; and
- no modification outside the six evidence roots and any separately approved
  central acceptance root.

Only after that acceptance may the Coordinator send the Writer an exact
seven-row SVG path and SHA-256 manifest. The Writer must then integrate the
accepted SVGs as the authoritative manuscript figure parts. A Word-generated
compatibility preview is allowed only when the SVG remains embedded as the
authoritative source.
