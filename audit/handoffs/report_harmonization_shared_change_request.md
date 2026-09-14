# Report-harmonization shared change request

Status: **author-approved with amendments; coordinator implementation/acceptance required**

Coordinator task: `019faf58-3df3-7383-8034-f715cdfdd154`

This request records shared changes exposed by the Phase 1 reader-facing audit. The author approved the navigation/cross-link plan and country-coded site labels on 2026-08-12. The harmonization worker will not edit shared configuration, the site registry, or central ledgers; coordinator action remains required.

## Navigation and render configuration

After the Phase 2 package is approved, please consider these bounded changes to `_quarto-nathealth.yml`:

1. Add the accepted preparation/provenance companions for H03, H04, H07, H09, and H11 to the render list and sidebar beside their result reports.
2. Remove `audit/hypotheses/implementation_result_comparison_contract.qmd` and `audit/hypotheses/H03-H11_gated_workflow.qmd` from reader navigation. Retain both as audit documentation.
3. Remove `notebooks/assemble_artifacts.qmd` from reader navigation or reclassify it as contributor documentation; it currently exposes internal assembly mechanics rather than reader content.
4. After `notebooks/preregistration_deviations.qmd` is approved, created, rendered, and tested, replace the partial `_deviations.qmd` navigation target with the new QMD source path.
5. Keep the accepted hourly H06 result as the main H06 entry. Add links to the complementary H06_daily report only after that task has accepted Stage 3/4 reader sources; do not reopen the hourly material merely to await the daily analysis.
6. Do not finalize the current `index.qmd` wording until its legacy RQ claims and assets have been reconciled to the accepted H01–H11 reports. This is a scientific/content hold, not an editorial repair for the harmonization worker to resolve.
7. Make every reader-facing site label carry its ISO alpha-2 country code, for example `Tübingen (DE)`, preferably through the shared display registry so prose, tables, figures, legends, captions, and alt text use one authoritative label. Preserve the approved site order and colours.

## Central deviation evidence and Phase 3 page

REPORT-015 / CHG-125 reconciled the crosswalk and historical statuses. REPORT-016 / CHG-126 then preserved `audit/ledgers/deviation_register.csv` as historical evidence and supplied the authoritative current 86-row reader-disposition overlay at `audit/ledgers/deviation_reader_dispositions.csv`.

The harmonization task has now generated and focused-render verified `notebooks/preregistration_deviations.qmd` from the register, crosswalk, and overlay under R 4.6.1. The source has SHA-256 `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d` and contains:

- 60 current scientific deviations;
- one current qualification;
- 19 resolved implementation-history records; and
- six technical-provenance records.

All 86 stable IDs have one exact lower-case anchor. Every entry preserves the register's preregistered or expected statement and uses only the overlay for its current disposition, current implementation, rationale, interpretive consequence, related IDs, and source locators. The focused HTML, preview, resource manifest, and verification record are in `audit/report_harmonization/deviation_render/`, `audit/report_harmonization/deviation_render_manifest.csv`, and `audit/report_harmonization/deviation_render_verification.md`.

Coordinator action now requested:

1. Add `notebooks/preregistration_deviations.qmd` to the Nature Health render list and reader navigation after independent source/render acceptance.
2. Replace the partial `_deviations.qmd` route or include with a dynamic QMD link to the new page; do not combine the stale historical narrative into the new current-disposition page.
3. Add exact dynamic links from shared reader-owned pages where a preregistration deviation is mentioned. The current `index.qmd` scientific/content hold remains in force; link integration must not be used to editorially reconcile its stale scientific claims.
4. Keep DOC-001 pending until all inbound owner links and the integrated Nature Health render pass.

## Shared link policy

Please adopt and enforce the following for the Nature Health profile after approval:

- internal links use relative `.qmd` targets with optional anchors;
- no internal `.html`, `file://`, absolute local, `_build`, or build-directory links;
- every reader-facing preregistration-deviation mention links to the exact stable entry anchor;
- every accepted result and preparation/provenance companion links reciprocally;
- H11 companion links to H02 companion where it relies on the accepted temporal-model architecture.

The Phase 3 structural tests will verify these rules once the deviation document exists and owners have implemented approved changes.

## Evidence returned by this task

- `audit/report_harmonization/phase1_corpus_inventory.csv`
- `audit/report_harmonization/phase1_link_inventory.csv`
- `audit/report_harmonization/document_change_matrix.csv`
- `audit/report_harmonization/crosslink_plan.csv`
- `audit/report_harmonization/harmonization_proposal.qmd` and its targeted render

The author approved this shared plan on 2026-08-12. Coordinator implementation remains bounded by ownership, current scientific gates, and focused verification.

## Final source-only shared dispatch after the serial owner audit

All owner-owned deviation-link findings are now cleared. The remaining
structural-test findings are confined to coordinator-owned `index.qmd` and the
internal workflow page that the approved navigation plan removes. At the next
safe coordinator execution point, apply the following bounded shared changes;
do not interrupt H06_daily computation or its author gate.

Current dispatch identities:

- `index.qmd`: `d42715497d706a90d58f2cae5a0c7461a518b172c65365a3150dab27b336fb3d`;
- `_quarto-nathealth.yml`: `c19d49bff611f85736fef98db9e615799fd6438d0ff507d967910d311840e446`;
- `audit/hypotheses/H03-H11_gated_workflow.qmd`:
  `ba749fea6d198aaeef58c45e2b46a30b3f248f0a2eb8bb38d22d6b68077ae68e`.

In `_quarto-nathealth.yml`:

1. Add each accepted preparation/provenance companion immediately after its
   result in both `project.render` and the Hypothesis analyses sidebar:
   `H03/H03_analysis_preparation.qmd`, `H04/H04_analysis_preparation.qmd`,
   `H07/H07_analysis_preparation.qmd`, `H09/H09_analysis_preparation.qmd`, and
   `H11/H11_analysis_preparation.qmd`.
2. Remove `audit/hypotheses/implementation_result_comparison_contract.qmd`,
   `audit/hypotheses/H03-H11_gated_workflow.qmd`, and
   `notebooks/assemble_artifacts.qmd` from both `project.render` and the
   reader sidebar. Retain the source files unchanged as internal documentation.
3. Keep the accepted hourly H06 report as the only H06 reader entry. Do not
   add H06_daily until its Stage 3 source is complete and author-approved.

In `index.qmd`, preserve the scientific/content hold and change only the four
generic registration-change labels that the corpus link contract flags:

- `Deviations from the preregistration are documented in @sec-preregdev.`
  becomes `A consolidated record of registered-analysis changes and current
  qualifications is provided in @sec-preregdev.`
- `## Deviation from the preregistration and protocol {#sec-preregdev}` becomes
  `## Registered-analysis and protocol changes {#sec-preregdev}`.
- `This section summarizes deviations from the preregistration` becomes
  `This section summarizes changes relative to the preregistered analysis`.
- Change only the central-page link label from `Preregistration deviations and
  current analysis decisions` to `registration-change record and current
  analysis decisions`; preserve the dynamic target
  `notebooks/preregistration_deviations.qmd`.

These substitutions do not reconcile, update, or endorse any held result or
methods claim. Return pre/post hashes, an exact scoped diff, configuration
membership/order checks, and `git diff --check`. Do not run a full-project
render or scientific code. The harmonization task will update its owned corpus
inventory and rerun the structural contract after coordinator acceptance.

## Phase 4 country-code follow-up for the held landing page

After the shared navigation dispatch passed, the accepted reader-corpus
country-code test found bare or incorrect site labels only in `index.qmd`.
Apply these display-only substitutions at the next safe coordinator point;
do not otherwise reconcile or alter any held scientific claim:

- line 229: `Tübingen cohort` -> `Tübingen (DE) cohort`;
- line 267: `(Madrid: ...; Izmir: ...)` ->
  `(Madrid (ES): ...; Izmir (TR): ...)`;
- line 295: `In Borås,` -> `In Borås (SE),`;
- line 297: `Exposure in Kumasi` -> `Exposure in Kumasi (GH)`;
- line 313: correct `Delft (SE)` to `Delft (NL)`;
- line 437: `in Dortmund,` -> `in Dortmund (DE),`;
- line 439: add the registry code to every site-city occurrence in the
  nine-site recruitment list and to the repeated `Tübingen` and `Kumasi`
  occurrences later in that line: Borås (SE), Delft (NL), Dortmund (DE),
  Tübingen (DE), Munich (DE), Madrid (ES), Izmir (TR), San José (CR), and
  Kumasi (GH);
- lines 617–625: add the same registry code to each City cell in the
  site-data table, while retaining the separate Country column unchanged.

Do not alter `Munich Chronotype Questionnaire` or `Technical University of
Munich`; those are instrument and institution names, not study-site labels,
and the structural test explicitly exempts them. Preserve all numbers,
citations, links, prose other than the listed display labels, and every other
file. Return the pre/post `index.qmd` hash, exact diff, reverse-substitution or
equivalent one-scope proof, and `git diff --check`; do not render.

## REPORT-017 rendered-link correction

Render order 00a found one unresolved legacy target in the held landing page.
At `index.qmd` line 546, preserve the link text and surrounding methods prose,
but replace the excluded `RQ1.qmd` target with the accepted H01 metric-contract
table:

`audit/hypotheses/H01/H01_analysis_preparation.qmd#tbl-h01-prep-metric-contract`

This target directly contains the stated metric-specific transformations,
model units, response families, and reported-effect scales. It is therefore
more precise than the H01 result landing page. Apply only this target
substitution from the accepted pre-edit index identity
`bde8b03095bc4d4a47a8398f4cf565b1d1aa6f1d1dc4989b81d91b9453898022`.
Then target-render only `index.qmd` through the Nature Health profile with
execution disabled. Verify that the rendered link resolves to the H01
companion HTML and exact table anchor, that all other index source bytes are
unchanged, and that the deviation-page link and accepted navigation remain
intact. Do not change any claim, render another target, execute code, or close
DOC-001 yet.

## Phase 4 unresolved reader-shell disposition

The current Nature Health configuration still exposes two unfinished planning
shells as reader pages:

- `supplementary_information.qmd` says that methods, deviations, results,
  sensitivities, figures, and tables “will be assembled” and contains empty
  H01 through H11 headings;
- `notebooks/sensitivity_battery.qmd` is explicitly titled “Planned
  sensitivity checks,” describes outputs that “will” be produced, and contains
  a disabled setup cell rather than accepted results.

Neither source can be classified as an accepted reader-facing report or
target-rendered under REPORT-017 without presenting unfinished plans as current
scientific content. `supplementary_information.html` is already intentionally
absent; the existing sensitivity HTML predates the accepted corpus work.

Recommended coordinator disposition: remove both sources from
`project.render` and the reader sidebar until their scientific content is
complete and author-accepted, while preserving the QMD files unchanged as
planning sources. If either page must remain visible, assign a scientific
owner and explicit content gate before the harmonization task renders or
accepts it. Do not count either shell toward DOC-001 inbound-link closure or
the accepted reader-corpus total in the interim.

## REPORT-017 Descriptives environment-startup blocker

Phase 4 render order 01 is blocked before knitr. The sole authorized
Descriptives render spent approximately 72 minutes 28 seconds in project
R-profile and renv startup, with no source, build, scientific, or artifact
change. The sealed evidence is in
`audit/report_harmonization/report017_render_order_01_blocked_verification.md`.

Coordinator or environment-owner action is requested under the narrow gate in
`audit/report_harmonization/report017_environment_startup_repair_request.md`.
Keep the serial render queue held until normal R 4.6.1 project startup passes
the bounded smoke check. Do not install or update packages, edit `renv.lock`,
bypass the project profile for the acceptance render, or start another owner
render meanwhile.

The separate Descriptives display-text repair for `Near-eye`, `near-eye only`,
and `submitted grouping` remains assigned to the Descriptives owner. It must
not change values, artifacts, or the stored table PNG.

## H06_daily source-only profile integration

H06_daily Stage 3 and Stage 4 are scientifically accepted under H06-D-016 and
H06-D-017. REPORT-014 Orders 20 and 21 are also independently accepted:

- result source:
  `notebooks/hypotheses/H06_daily.qmd`, SHA-256
  `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`;
- preparation/provenance companion:
  `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`, SHA-256
  `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`;
- refreshed site-deviation PNG, SHA-256
  `a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1`;
- independent display acceptance:
  `audit/report_harmonization/h06_daily_order21_display_acceptance.md`.

From the current Nature Health configuration identity
`b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`,
add the two H06_daily sources to `project.render` and the Hypothesis analyses
sidebar immediately after the main hourly H06 result and its companion. Keep
the H06_daily result immediately before its own companion. Use reader labels
that preserve the hierarchy, for example `H06 complementary daily results`
and `H06 complementary daily preparation and provenance`.

This request authorizes source-only configuration placement. Do not render
either H06_daily page, run Quarto or R, edit either QMD or figure, or alter the
hourly H06 entries. The focused H06_daily renders remain held until the active
REPORT-017 serial queue reaches them. Return the configuration pre/post hashes,
exact scoped diff, adjacency checks in both render and sidebar order, proof that
all other configuration entries are unchanged, and `git diff --check`.

Completed at the serial safe point on 2026-08-13. The integrated configuration
SHA-256 is
`5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`.
Independent verification is recorded in
`audit/report_harmonization/h06_daily_profile_integration_verification.md`.
H06_daily remains unrendered pending its REPORT-017 serial place.
