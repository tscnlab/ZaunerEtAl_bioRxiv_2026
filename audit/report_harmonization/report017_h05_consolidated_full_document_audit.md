# REPORT-017 H05 consolidated full-document audit

Date: 2026-08-14

Status: complete read-only source audit; one consolidated source-only owner order is appropriate; H05 rendering remains held

## Controlling boundary

This audit follows REPORT-014, REPORT-016, REPORT-017, the accepted H05 scientific closure, the current MDER and numerical-zero decisions, and the consolidated-document-pass protocol. It covers the complete H05 result report, its preparation and provenance companion, every reader-facing table and figure endpoint, directly dependent tests and manifests, dynamic links, the current owner handoff, and provisional main and supplemental output roles.

No data, model, estimate, interval, p-value, model check, sensitivity, multiplicity decision, sample definition, table, figure, source-data file, or scientific artifact was changed. No Quarto render or scientific analysis was run. Structural inventories, source reading, link checks, checksum checks, and image inspection were non-analytical. H05 remains scientifically closed.

## Reviewed identities

- Result source: `notebooks/hypotheses/H05.qmd`, SHA-256 `b4167419ce0f22b635d41c98d3d7edda2717fc73e6c963371f79035a334d793c`, 70,979 bytes.
- Companion source: `audit/hypotheses/H05/H05_analysis_preparation.qmd`, SHA-256 `f7d7d3ef4bdf9b29403e85592b7dd2737f7e3c9dcfdc0ff7275eeefa7735c28f`, 74,171 bytes.
- Current result HTML: `_build/nathealth/notebooks/hypotheses/H05.html`, SHA-256 `58be9b4da8bb67a4322af7096472de1bf97c47d17c79f39078692577a2788b96`, 573,311 bytes.
- Current companion HTML: `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html`, SHA-256 `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`, 839,152 bytes.
- Stage 2 scientific test: `tests/hypotheses/H05/test_h05_stage2.R`, SHA-256 `76008cadabc573005f4833c21494a61f034ff376ea6ef92612691e2694bbb1b7`.
- Stage 3 reader test: `tests/hypotheses/H05/test_h05_stage3_reader_report.R`, SHA-256 `982162ccbd55def924beff3fbb0e98d31a94884aeb8cc683f817189e1171d4f4`.
- Preparation test: `tests/hypotheses/H05/test_h05_preparation_report.R`, SHA-256 `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e`.
- Stage 2 manifest: `artifacts/12_manifests/H05/H05_stage2_artifacts.csv`, SHA-256 `09363abf0557646870d0752f08b00f42013deec471a1ea97067c2333a1a811cc`, 77 rows, all current.
- Stage 3 manifest: `artifacts/12_manifests/H05/H05_stage3_artifacts.csv`, SHA-256 `9dabc70a0ab6554a0b4d9dbc175cd4009b1f57a57c975cb4677b45ead2620100`, 177 rows.
- Preparation manifest: `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv`, SHA-256 `bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36`, 141 rows.
- Owner handoff: `audit/handoffs/H05_stage4_handoff.md`, SHA-256 `896205d9b7f0403e7cb70023ebb392526e58a30825c4d2b151488098602018b4`, 14,619 bytes.
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Phase 2 output catalog: `audit/report_harmonization/phase2_main_supplement_output_catalog.csv`, SHA-256 `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`.
- Central deviation page: `notebooks/preregistration_deviations.qmd`, SHA-256 `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.
- Site display registry: `config/site_display_registry.csv`, SHA-256 `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.

The H05 handoff and all three tests were read completely. Every R chunk in both QMDs parses under R 4.6.1 without execution. The result contains 39 R chunks, 30 unique table endpoints, and seven unique figure endpoints. The companion contains 27 R chunks, 22 unique table endpoints, and three unique figure endpoints.

The Stage 3 and preparation manifests are accepted historical render records. Their current mismatch sets reflect later accepted shared and source changes. The Stage 3 set is exactly `change_log.csv`, `hypothesis_stage_gates.csv`, the H05 result QMD, and the Nature Health profile. The preparation set is exactly the result QMD, companion QMD, profile, and `h01_contract.R`. These manifests should remain byte-identical in the source-only order.

## Scientific result boundary

The primary analysis uses near-eye measurements as the closest available measure of personal light near the eyes. Chest measurements are complementary and are not interpreted as ocular exposure. Four LEBA factors are crossed with 17 light-exposure metrics. Each inferential family therefore contains 68 tests and retains zero FDR-supported associations.

The four sleep-environment cells remain part of the planned family but are unfit for H05 inference under the accepted response definition and model structure. The two largest descriptive F2 estimates concern time above 1,000 lx melEDI and melEDI dose. Their magnitudes, intervals, raw p-values, and FDR-adjusted p-values remain unchanged and are not multiplicity-retained.

The accepted MDER estimand is the arithmetic mean of viable one-minute melEDI-to-illuminance ratios, with strictly positive paired channels and at least 720 viable minutes. The gap-timing-unaware dataset remains a named sensitivity. The common-sample placement comparison assesses concordance of separately fitted near-eye and chest estimates. It is not an equivalence test or a direct placement-effect test.

Fixed site effects define the primary analysis. The registered random-site model remains a sensitivity, and leave-one-site-out refits describe site influence. Every formula, sample, estimate, interval, p-value, FDR decision, model check, influence result, sensitivity classification, source-data row, and scientific conclusion must remain unchanged.

## Result-report findings

### Information hierarchy

The Answer in brief is accurate but long. Four methods or sample tables occur before the principal near-eye table, and the central figure is delayed by detailed factor, formula, response, and sample material. A reader reaches the complete finding only after passing through much of the analysis dossier.

The coherent target order is:

1. Question and a shorter Answer in brief.
2. A compact orientation defining the primary near-eye role, complementary chest role, four LEBA factors, participant-day, participant-level SD, 95% CI, FDR, and common sample.
3. Primary near-eye result, beginning with `fig-h05-near-effects`, then `tbl-h05-near-results-a` and `tbl-h05-near-results-b` as one continued main table.
4. The two leading descriptive F2 magnitudes and their explicit non-retained interpretation.
5. Complementary chest evidence.
6. Model checks, including the four unfit sleep-environment cells.
7. MDER and upper-tail evidence.
8. Common-sample, random-site, leave-one-site-out, gap-timing-unaware, and exact-period sensitivities.
9. Interpretation and limitations.
10. A late detailed analysis record containing factor construction, exact samples, formulas, response specifications, registration links, and technical source links.

This makes the proposed main figure the first result figure and `tbl-h05-near-results-a` the first result table. Every other endpoint remains present exactly once.

### Vocabulary and prose

- Use `near-eye measurements` for the primary position and explain that they measure light close to the eyes. Do not call them direct retinal measurements.
- Keep `chest measurements` explicitly complementary and non-ocular.
- At first use, explain `participant-day`, `participant-level standard deviation`, `95% confidence interval`, `FDR adjustment`, `random effect`, `fixed site effect`, `Tweedie model`, `back-transformed`, `likelihood-ratio comparison`, and `sensitivity analysis` in plain language.
- Describe the common sample first as the same participants and participant-days at both sensor positions. `Common sample` may then be used as the short label.
- Keep `MDER` and `gap-timing-unaware dataset` only after their concise first-use explanations.
- Replace visible all-capital production states with sentence-case reader labels. Code-only `PASS`, `FAIL`, `DESCRIPTIVE_PASS`, family IDs, and historical object names may remain where reproducibility requires them.
- Use `FDR` in compact reader displays. The full Benjamini-Hochberg method name may remain in subordinate technical provenance. Do not expose the `BH` abbreviation in reader prose.
- Replace submitted-site and submitted-manuscript wording with `study sites`, `country-coded study-site order`, or `shared site display registry`.
- Replace visible internal family IDs with plain family descriptions.
- Replace prose em dashes with punctuation or separate sentences. Missing-value dash symbols may remain.
- Keep every literal site name country-coded.

### Progressive disclosure

- Keep the main near-eye figure, continued main table, and their interpretation visible.
- Place detailed near-eye model-check tables and residual figures in `Show detailed near-eye model checks`.
- Keep the complementary chest conclusion visible and place its full tables and model checks in `Show complementary chest results and model checks`.
- Keep the MDER conclusion visible and place scenario, upper-tail, and influence tables in `Show MDER details and upper-tail checks`.
- Keep the overall sensitivity conclusion visible and place common-sample, random-site, leave-one-site-out, gap-timing-unaware, and exact-period tables in `Show detailed sensitivity results`.
- Move factor construction, exact samples, formulas, response specifications, registration details, and subordinate source links to the late detailed analysis record.

### Principal and supplemental outputs

- `fig-h05-near-effects` remains the provisional main H05 figure. The stored PNG is 2,700 by 2,700 pixels at 300 dpi, SHA-256 `70c1013d51f7619fafe0d38664db7dcf55692990993098948ed443e83c35e1a5`. Static inspection found a polished, readable display with no internal terminology that requires a baked-label refresh.
- `tbl-h05-near-results-a` and `tbl-h05-near-results-b` remain one provisional continued main H05 table. Preserve their native gt construction, rows, order, values, units, captions, and notes.
- `fig-h05-near-adequacy` remains supplemental model-check context. Its PNG is 2,700 by 2,550 pixels at 300 dpi, SHA-256 `a457fda5dfb9025f21b72daab52c3e5338ba1657f7183ad4726ddd9b57561edf`.
- `fig-h05-paired-placement` remains supplemental sensitivity context. Its PNG is 2,700 by 2,400 pixels at 300 dpi, SHA-256 `b30291d1c1f483202b6b3303045a760e03ef43b1fdf18a36a525543b1a387774`.
- No H05 figure regeneration is proposed before rendering. All current figure and table roles remain provisional until the author sees the fresh focused render.
- HTML tables must work reasonably at a typical screen size. If an exported table PNG exists or is later produced, that PNG is the controlling exported-table visual check.

## Companion findings

The companion is scientifically faithful and already distinguishes primary near-eye and complementary chest evidence, participant and participant-day outcomes, fixed and random site roles, complete 68-test families, model checks, sensitivities, current MDER, and numerical-zero qualifications.

The remaining repairs are reader-facing and structural:

- Add `lightbox: true`.
- Move the existing `About this analysis record` callout from Technical provenance to the opening and rename `Purpose` to `About this analysis record`.
- Correct the registration-summary sentence from plural `are mapped` to singular `is mapped`.
- In `tbl-h05-prep-integrity-checks`, replace the stale visible expected value `12 matches` with `17 matches`. The code already requires and observes the exact 17 current result-input roles.
- Display verification states as `Verified` and `Review needed`, while preserving stored PASS/FAIL values and fail-closed checks in code.
- Replace submitted-manuscript site/order/registry wording with study-site and shared-registry wording.
- Map internal family IDs to plain reader descriptions and display FDR rather than BH.
- Use spaced reader labels in tables, including `Calculated when rendered`, `Reads or defines`, `Why separate`, `Entry point`, and `Runs when page renders`.
- Keep full technical filenames, exact formulas, commands, checksums, package names, and the full Benjamini-Hochberg method name only where reproducibility needs them.
- Replace the reader-facing output-registry `_build/.../H05.html` row with the authoring result QMD as `Reader report source`. Do not expose build-directory paths as reader content.
- Keep all fitting, prediction, bootstrap, simulation, model-check repetition, leave-one-site-out reruns, and scientific artifact construction outside the render.

## Source-test and provenance strategy

The current Stage 3 and preparation tests are render-coupled and contain historical HTML expectations. Editing them for a source-only rewrite would create avoidable transition loops. The source-only order should therefore:

1. Preserve all three existing H05 tests byte-for-byte.
2. Preserve all three existing H05 report manifests byte-for-byte.
3. Add one new H05-owned source-only harmonization test that validates both QMD sources, every endpoint, first-endpoint order, formulas, dynamic links and anchors, country-coded sites, vocabulary, scientific-call boundaries, historical-manifest mismatch sets, and protected scientific identities.
4. Add one bounded non-circular H05 source manifest that pins the final QMDs, new source-only test, unchanged existing tests and manifests, handoff, principal and supplemental figures, source-data files, stale HTML context, profile context, and owner evidence. It must not claim that current HTML corresponds to revised source.
5. Run the new source-only test once under R 4.6.1 after the complete rewrite is assembled. Parse every R chunk without execution. Do not run the Stage 2 scientific test or the render-coupled Stage 3 and preparation tests in this source-only order.

This produces one current source seal without rewriting historical evidence or entering a sequence of test-only repairs.

## Stored-figure disposition

The main figure, near-eye model-check figure, and paired-placement figure were inspected at original resolution. They already use reader-facing terminology, legible labels, and the accepted scientific roles. No baked `BH`, `equal-site`, unexplained heterogeneity, uncoded site name, or production-history label was identified in the controlling H05 reader figures.

The owner should inventory and pin the stored figures and builder but must not regenerate them. If the later focused render reveals a final-size issue, collect all display findings before one bounded display order.

## Current render disposition

The current result and companion HTML files predate the consolidated hierarchy and terminology pass. They remain stale render context, not final visual evidence.

After independent source acceptance, H05 should receive exactly one result render and one companion render in the serial REPORT-017 queue. Review both pages together for semantic tables, links, endpoint numbering, disclosures, lightbox behavior, main-figure and main-table readability, desktop and narrow layout, and protected scientific identities. Collect any newly exposed display defects before one combined correction order.

## Disposition

No scientific discrepancy blocks H05. One consolidated source-only owner order may overlap other path-disjoint source work. H05 must not render, edit the shared profile, touch the semantic hook, modify build outputs, change central or harmonizer-wide files, regenerate figures, or run scientific computation. The owner should implement the complete matrix once, run the one source-only suite once after all edits, and stop for independent acceptance.
