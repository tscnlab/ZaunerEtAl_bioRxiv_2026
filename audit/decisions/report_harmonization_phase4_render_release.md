# Reader-report harmonization Phase 4 render release

Decision ID: `REPORT-017`  
Change ID: `CHG-134`  
Date: 2026-08-12  
Status: approved serial focused-render and display-review window; `DOC-001`
remains pending rendered integration

## Evidence at release

The source-only harmonization gate is complete for the accepted reader corpus:

- `audit/report_harmonization/phase4_source_verification.md` records passing
  navigation, reader-link, country-coded site-name, Phase 2 package,
  preregistration-deviation, and non-strict table contracts for 35 accepted
  reader-facing QMD sources;
- all 11 hypothesis result reports are adjacent to their accepted
  preparation/provenance companions in the Nature Health render list and
  sidebar;
- `notebooks/preregistration_deviations.qmd` contains all 86 exact stable
  anchors and has already passed its deterministic focused source and preview
  checks;
- `_quarto-nathealth.yml` is accepted at SHA-256
  `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`;
- `index.qmd` is accepted at SHA-256
  `bde8b03095bc4d4a47a8398f4cf565b1d1aa6f1d1dc4989b81d91b9453898022`;
- `notebooks/preregistration_deviations.qmd` is accepted at SHA-256
  `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`;
  and
- H06_daily has completed its scientific Stage 2 work and is idle at the
  separate H06-D-G3 Stage 3 author gate. The compute hold in `REPORT-014`
  therefore no longer blocks serialized report rendering.

The accepted source verification also establishes that existing HTML files
predate some accepted source changes and that one expected HTML file is
absent. Source verification alone is therefore not the final rendered gate.

## Released Phase 4 work

The harmonization task may now coordinate the first author-approved
display-adjustment run under these constraints:

1. Wake and process only one document-owner task at a time.
2. Before each render, verify that the owner source identity and accepted
   scientific-output pins still match the owner handoff.
3. Render only the owner's targeted reader pages through the current Nature
   Health profile. Do not run a full-project render.
4. Regenerate only display assets that can be derived from stored accepted
   plot or table source data without fitting, predicting, resampling,
   simulating, recomputing diagnostics, or changing a scientific result.
5. Preserve every accepted estimate, interval, raw or FDR-adjusted p-value,
   sample, diagnostic disposition, sensitivity result, and qualification.
6. Return source, HTML, figure/table asset, and paired-source-data identities;
   focused structural tests; final-size visual QA; dynamic-link checks; and a
   protected scientific-identity check for each owner.
7. Stop and return any scientific discrepancy to the scientific owner. It
   must not be resolved as an editorial change.
8. Collect the first adjusted principal and supplemental figures and tables
   for author visual review. They remain provisional until that review.

The central preregistration-deviation page may receive a targeted render
through the same profile. Held reader pages may be rendered without executing
scientific code only when required to verify an accepted dynamic link and
when their held scientific prose remains byte-identical.

## Explicit exclusions

- H06_daily remains outside the Phase 4 corpus until its H06-D-G3 Stage 3
  source is explicitly author-accepted. Stage 4 remains a separate,
  unauthorized gate.
- The scientific/content holds on the landing page and supplementary
  information remain in force. This decision authorizes no scientific prose
  reconciliation there.
- No shared-preparation rebuild, data change, model fit, bootstrap,
  simulation, Shapley calculation, package installation, commit, push, or
  upload is authorized.

## DOC-001 disposition

`DOC-001` is not closed by the source-only checks. Its authoritative overlay
row remains `documentation_pending` because `REPORT-016` and the shared
handoff require both the stable source/link contract and a successfully
verified Nature Health render.

The later closure gate is:

1. the central deviation page renders successfully through the accepted
   Nature Health profile;
2. every accepted inbound dynamic QMD link is materialized and resolves to
   the intended one of 86 anchors in the rendered site;
3. the serially refreshed HTML corpus passes the final integrated link audit;
   and
4. the resulting source, HTML, resource, and verification identities are
   sealed.

The serial targeted renders authorized here may collectively satisfy this
integrated-render requirement; a full-project render is not required. Once
the four checks pass, record a separate `DOC-001` closure and update its
current reader-disposition overlay without rewriting the historical
`deviation_register.csv` row.

## Reopening condition

Stop or reopen this release if a source or accepted-output identity drifts, a
target render invokes prohibited scientific computation, a link or stable
anchor fails, a visual repair changes scientific content, concurrent heavy
computation resumes, or the author rejects the first adjusted display set.
