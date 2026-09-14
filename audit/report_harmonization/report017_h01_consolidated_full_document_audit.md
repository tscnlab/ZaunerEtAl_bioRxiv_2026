# REPORT-017 H01 consolidated full-document audit

Date: 2026-08-14

Status: complete read-only audit; one consolidated owner order proposed; all H01 renders remain held

## Controlling boundary

This audit follows REPORT-014, REPORT-017, the author-approved Phase 2 vocabulary and structure, and the consolidated-document-pass protocol. It covers the H01 result report, its preparation and provenance companion, all current table and figure endpoints, source tests, current manifests, dynamic links, and the current rendered HTML.

No data, model, estimate, interval, p-value, diagnostic, sensitivity, multiplicity decision, sample definition, source-data file, or scientific artifact was changed. No Quarto or R execution was performed for this audit. A stored-results-only R 4.6.1 check was used earlier to verify the exact sample summaries quoted below.

## Reviewed identities

- Result source: `notebooks/hypotheses/H01.qmd`, SHA-256 `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`, 90,640 bytes.
- Companion source: `audit/hypotheses/H01/H01_analysis_preparation.qmd`, SHA-256 `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`, 54,405 bytes.
- Current result HTML: `_build/nathealth/notebooks/hypotheses/H01.html`, SHA-256 `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`.
- Current companion HTML: `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`, SHA-256 `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`. This render predates the accepted companion source and semantic gt hook.
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Reporting manifest: `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`.
- Stage 3 reporting manifest: `16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e`.
- Worker manifest: `debce70f59c8e2c401ad36291694604246349633079bcd4d706aba6cf4d548c5`.
- Preparation-report manifest: `bae856c2bb75df317f476e7e993178061628c0fcdbc6795a4b88f78843f8d9d0`.
- Phase 2 output catalog: `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`.
- Consolidated-pass protocol: `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.

## Scientific result boundary

The H01 scientific result is accepted and frozen. The proposed work is editorial and structural. It must preserve all 36 result tables, 10 result figures, 20 companion tables, two companion figures, formulas, numerical values, model engines, model-check classifications, multiplicity families, sensitivity classifications, and source-data links.

The exact primary support varies by metric. Stored accepted outputs show 139 to 141 participants and 655 to 816 participant-days for primary near-eye participant-day outcomes, with participant-level outcomes supported by 141 participants and 816 participant-days across nine sites. Complementary chest outcomes use 153 to 154 participants and 743 to 902 participant-days across eight sites, with participant-level outcomes supported by 153 participants and 900 participant-days. These ranges may be used only to orient readers early in the report. Exact metric-specific tables remain authoritative.

RH-SCI-H01-003 resolved one wording discrepancy. Term-specific part-R² values are reductions in R² when a term is removed from its fitted model. Shared predictor information means these reductions can overlap and must not be summed. The accepted replacement is:

> Marginal R², conditional R², participant-associated share, and model-specific term part-R² values that may overlap and must not be summed

Latitude remains a term part-R² from its separate same-frame model, as already explained below the table.

## Result-report findings

### Information hierarchy

The report currently puts the full registration table and 36-link registration list before the model and results. This delays the central answer and makes the proposed main table appear as Table 3. The approved common structure instead calls for the question, answer in brief, concise analysis scope, model and estimand explanation, and principal result first. Detailed registration, sample, diagnostic, and formula records can remain complete but should move later.

The coherent target order is:

1. Question and scope.
2. Answer in brief.
3. What was analysed, including a concise exact-support orientation and definitions of all-available and matched samples.
4. Statistical models and reported quantities.
5. Results overview, beginning with `fig-h01-model-support` and `tbl-h01-primary-publication-summary`.
6. Primary near-eye results.
7. Complementary chest results.
8. Matched near-eye and chest evidence.
9. Model checks, with detailed examples in a disclosure.
10. Sensitivity analyses.
11. Interpretation and limitations.
12. Detailed analysis record containing exact fitted samples, registration changes, response/model-family registry, exact formulas, implementation details, and source data.

This preserves every endpoint while making the principal result immediately visible.

### Vocabulary and prose

- Replace the internal subtitle `Standalone results report` with a scientific subtitle describing site, photoperiod, and latitude associations in personal light exposure.
- Retain `FDR` in compact displays. Do not expose `BH` in reader-facing table or figure language. The full Benjamini-Hochberg false-discovery-rate method may remain once in technical reproducibility text.
- Change visible `Within-metric adjusted p` labels and notes to `Within-metric FDR-adjusted p` without changing any stored p-value or decision.
- Retain `site-average estimate` and its first-use explanation that it gives every site equal weight.
- Retain the explained `gap-timing-unaware dataset` term because it names a precise accepted sensitivity.
- Replace prose em dashes with colons, commas, parentheses, or separate sentences. A dash glyph used only for a missing or unsupported table cell may remain as a symbol.
- Replace `Primary publication summary` with `Primary near-eye summary`. Replace the source-note phrase `This publication summary` with `This summary`.
- Use `Registration changes and related records` for the late registration section. Its table caption should describe changes relative to the registered or expected analysis, not present all linked implementation history as current scientific deviations.

### Progressive disclosure

- Put the topic-organized 40-link registration list in a disclosure labelled `Show linked registration entries by topic`. Preserve all 40 exact relative links and 36 unique lower-case anchors.
- Keep the concise model-check conclusion visible. Put the representative diagnostic table and four diagnostic images in a disclosure labelled `Show representative model-check details`.
- Keep exact formulas and engine tables in a disclosure within the late detailed analysis record.
- Add `lightbox: true` to the result HTML format so dense figures remain inspectable at narrow viewport sizes without changing or regenerating them.

### Principal outputs

- `fig-h01-model-support` remains the provisional main H01 figure. The accepted stored PNG is 3,360 by 2,368 pixels at 320 dpi. The current HTML still shows the pre-refresh `BH-adjusted result` legend because it predates the accepted title-only artifact repair. A fresh render must show `FDR-adjusted result`.
- `tbl-h01-primary-publication-summary` remains the provisional main H01 table. It is readable at a typical desktop width and remains usable at 708 pixels. No substantial table redesign is warranted.
- No exported PNG for the H01 main table was found. HTML is therefore the current table-review surface. If an exported table PNG is later produced for submission, that PNG becomes the final exported-table visual check.
- All other H01 figures and tables retain their accepted supplemental roles. The main and supplemental shortlist remains provisional until the author sees the fresh focused outputs.

## Companion findings

The companion source already follows the numbered provenance structure, but several visible labels remain implementation-oriented.

Required reader repairs are:

- Add `lightbox: true`.
- Remove the unused render-side `source_dir` and `dir.create()` statements. They do not contribute to the page and create an unnecessary project-side write attempt.
- Rename `Purpose` to `About this analysis record` and `What is calculated when this page opens` to `Render boundary`.
- Define a model frame at first use as the exact rows and variables used for one fitted model.
- Replace visible underscore-separated table headers with spaced reader labels.
- Replace visible `model-data bundle` with `analysis dataset`.
- Put model engine names after a plain description, for example `Participant-level model (ordinary Gaussian linear model, lm)`.
- Use `marginalization` consistently with the result report.
- Apply the exact RH-SCI-H01-003 part-R² wording.
- State explicitly that within-metric site follow-ups use an FDR adjustment.
- Replace `Stored joint-refit audit` with `Stored joint-refit support` and display internal PASS/CHECK states as `Verified` and `Review needed` without changing their stored values.
- In the visible model-check map, replace filenames with reader roles such as `Participant-deletion influence` and `Leave-one-site-out latitude analysis`. Preserve filenames and hashes in technical provenance.
- Replace the final takeaway's `two verified model-data bundles` and `single declared 17-response implementation` with `two verified analysis datasets` and `one declared model implementation for 17 responses`.
- Keep exact commands, filenames, hashes, and environment details in the technical provenance section.

The current companion HTML is stale and contains duplicate gt-internal IDs across tables. This is not a source defect. One fresh profile render must run the accepted semantic post-render hook and produce document-wide unique IDs with complete header resolution.

## Test and manifest finding

Repeated H01 loops arose because historical reconciliation tests and broad manifests treat editorially mutable QMD and HTML identities as permanent live scientific pins. That coupling is unnecessary and makes every approved wording or render change look like a new scientific transition.

The consolidated order should perform one fail-closed cleanup:

1. Preserve every historical REPORT-016 file and historical owner manifest byte-for-byte.
2. Keep exact immutable scientific and stored-output identities in the existing scientific manifests.
3. Make the current reader-source contract semantic: endpoint counts, labels, dynamic links and anchors, FDR language, formulas, artifact references, protected values, and forbidden scientific calls.
4. Resolve current mutable QMD identities through the current reporting and Stage 3 manifest rows, which are resealed once in the same source order.
5. Remove the durable rendered HTML from the REPORT-016 scientific reconciliation test. Validate rendered HTML in the post-render semantic and visual acceptance record instead.
6. Add a source-only mode to the preparation test so the result and companion sources can be accepted before rendering. Preserve the complete HTML branch for the one later companion render.
7. Do not run the broad preparation-manifest builder in the source-only order because it copies build assets and inventories unrelated current drift. Directly update only the result and companion source rows in current manifests. After the two final renders, perform one bounded post-render manifest reseal for the declared HTML, copied QMD, and page-owned assets.

This preserves the historical audit trail and strengthens the current semantic checks while avoiding repeated hash-only repair cycles.

## Visual review of current HTML

A temporary read-only HTTP server was rooted exactly at `_build/nathealth`, bound only to `127.0.0.1`, and stopped after inspection. Desktop 1,440 by 1,000 and narrow 708 by 1,000 views were inspected through the supported in-app Browser. Source, profile, and HTML hashes were unchanged after review.

- No page-wide horizontal overflow or embedded error was found.
- The current result has 36 native gt tables and 10 figure endpoints. All figures have alt text.
- The principal table is readable on desktop and remains usable on the narrow viewport. Dense tables use contained horizontal scrolling.
- The principal figure is readable on desktop but too small for comfortable narrow-screen label reading. Lightbox support is the smallest suitable repair.
- The companion's tables use contained narrow scrolling where needed. Its current duplicate gt IDs must be repaired by the accepted post-render hook on the fresh render.
- The known unbuilt Supplementary information target remains DOC-001 shared work, not an H01 source defect.

## Disposition

One consolidated source-only order is appropriate. It should cover both QMDs, their directly dependent source tests, bounded current source-manifest rows, and the H01 handoff. It should not render. After independent source acceptance, run exactly one result render and exactly one companion render, then perform one combined semantic, link, table, figure, exported-output, desktop, narrow, and protected-identity review. Any defects found during that review should be collected across both pages and returned as one correction package.
