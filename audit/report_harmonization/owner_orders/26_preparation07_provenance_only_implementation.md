# REPORT-014 order 26: Preparation 07 provenance-only implementation

Date: 2026-08-14  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Scope: source-only Preparation 07 provenance repair  
Render status: **held**

## Authority and purpose

The author approved the bounded `PREP07-PROV-001` implementation with the
exact response:

> Approve the PREP07-PROV-001 provenance-only implementation.

The author-approved package, immediately before approval was recorded, was
`audit/report_harmonization/preparation07_provenance_implementation_approval_package.md`,
SHA-256
`c384e2dff8914a57610b7aaa4be660cb555e07fd3cc63a83bdc49bef6f82decf`.
The same package with the approval response recorded has SHA-256
`ee04570314579b724cb91faec30164b1b455586832caa8c533d5bdf643ea28dc`.

The sealed R 4.6.1 audit found a Low-severity, Confirmed provenance/reporting
mismatch. The frozen display manifest truthfully records the historical
site/daylight-context producer file. The accepted current file has a different
file identity because provenance attributes were repinned, but the audit
verified that its scientific values are exact. This order repairs only the
reader and test contract. It does not change data, a result, or an artifact.

## Exact editable scope

Edit only these reader/test files:

1. `notebooks/preparation/07_example_days.qmd`
2. `tests/test_preparation07_report.R`

Owner-owned verification records may be added under
`audit/preparation_reports/`, and the current preparation handoff may be
updated after completion. Do not edit another QMD, shared configuration,
central ledger, decision, audit seal, scientific artifact, production script,
strict verifier, manuscript file, lockfile, or rendered output.

## Required preflight identities

Stop without editing if any identity differs:

| File | Required SHA-256 |
|---|---|
| `notebooks/preparation/07_example_days.qmd` | `2293d2520dabaacc7394a39c00b5ac62911da1d34fb489ecf4bf232c55a2998f` |
| `tests/test_preparation07_report.R` | `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `audit/reconciliation/preparation07/site_solar_context_equivalence_audit.md` | `870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164` |
| `audit/reconciliation/preparation07/site_solar_context_equivalence_evidence.csv` | `0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97` |
| `audit/reconciliation/preparation07/site_solar_context_equivalence_manifest.csv` | `01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c` |

Also preserve the stopped-render record
`audit/preparation_reports/report017_preparation07_failed_render_verification.md`
at `1e482a14f95cb23a4bbc80669b4619ad21ee8ce7e957f498fc88ac0d01bfa1ad`
and its 23-entry manifest at
`bb05d47604b26e0082c9059a22a5ff2dd091410dc153f60702d55fb9056df591`.

## Exact source implementation

### Sealed evidence checks

In the existing setup chunk, add bounded reads and identity checks for the
sealed audit report, evidence CSV, and two-entry non-circular seal. Do not
open or independently compare the historical and current scientific RDS
objects.

Require all of the following from the stored evidence:

- exactly 17 unique `check_id` rows;
- exactly 16 rows with status `PASS`;
- the remaining `independent_verifier_total` row has status
  `EXPECTED_PROVENANCE_FAIL_ONLY`, with expected and observed values both
  equal to `17 PASS and manifest::input_hashes FAIL`;
- `historical_solar_rds_pin` records
  `b0e8de539572ee595cc91027e7a2d919ba01237f780e50a76e5e4468d497c4bf`;
- `current_solar_rds_pin` records
  `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0`;
- `context_csv_historical_current` records
  `7dc64cc5026947ef96d6e4ab112bb767414420be97817f022082248db68d7028`;
- `full_context_frame` records 618 rows, 47 columns, and zero changed cells;
- `selected_day_context_strings` records exact equality for nine keys and four
  stored fields; and
- the seal contains exactly the audit report and evidence CSV with their
  exact stored byte counts, hashes, R version `4.6.1`, and status `PASS`.

These are stored-evidence checks only. Do not rerun the strict verifier,
reconstruct the display, compare scientific frames, or recalculate any value.

### Historical and current input dispositions

Preserve the historical manifest SHA-256 and the exact historical producer
pin. Preserve exact current-file hashing for all three inputs. Replace only
the stale assertion that all three historical and current hashes must match.

The prepared near-eye input and site metadata must still require exact
historical-to-current identity. For site/daylight context, require both the
historical and current hashes above and the successful sealed equivalence
evidence. Use the plain reader status:

> Equivalent values, different file version

Do not translate this row into a false exact-hash match. Do not rewrite the
historical manifest or suppress the strict verifier's expected input-hash
failure.

### Reader explanation and existing tables

Use this approved visible explanation exactly in the technical-provenance
section:

> The stored example-day display was created from an earlier version of the
> site/daylight-context file. The accepted current file contains the same
> site/daylight values used here; only file-level provenance metadata changed.

Update only the existing `tbl-example-day-inputs` and
`tbl-example-day-current-checks` endpoints and their immediately surrounding
technical-provenance prose. Do not add a table endpoint.

The input table must separately show the manifest-recorded SHA-256 and current
SHA-256, because the site/daylight row no longer has one shared identity. Keep
the two exact-match rows visibly distinct from the equivalence row. Use plain
reader labels and wrap paths/hashes so the native HTML table remains usable at
ordinary desktop width and has contained horizontal scrolling if required at
708 pixels.

The current-checks table must report the sealed reconciliation as successful
without claiming that every historical/current input hash matches. Revise its
caption or source note only as needed to distinguish exact identity from
verified scientific equivalence.

Do not expose `PREP07-PROV-001`, machine status codes, internal change IDs, or
task mechanics in the ordinary reader explanation. Exact audit paths and
hashes may remain in subordinate technical provenance.

## Focused test update

Update `tests/test_preparation07_report.R` so it:

- requires all three sealed audit paths and their exact SHA-256 identities;
- requires both the historical `b0e8de53...` and current `39ffe488...` pins;
- requires the exact approved visible explanation and plain equivalence label;
- statically requires the 17-row, 16-pass, one-expected-provenance-failure
  contract and the non-circular two-entry seal;
- retains exact source and later-HTML checks for seven native `gt` tables,
  three figures, all country-coded site names, the source-data link, dynamic
  internal links, and absence of rendered errors; and
- retains every existing no-builder, no-production-verifier, no-writer,
  no-model, no-prediction, no-resampling, no-simulation, and no-scientific-
  regeneration assertion.

Add later-HTML assertions inside the existing optional HTML branch, but do not
run that branch against the stale HTML in this source-only order.

## Frozen scientific and display boundary

Do not run Quarto or knitr. Do not run any preparation builder, strict
showcase verifier, model, prediction, bootstrap, simulation, or scientific
reconciliation. Do not regenerate the PNG, SVG, source-data CSV, selection,
settings, context files, or manifest.

Preserve:

- all selection, seed, sample, minute-grid, mask, site-order, colour, figure,
  caption, alt-text, and no-hypothesis-handoff content;
- all seven table and three figure identifiers;
- all scientific and display artifacts listed in the approval package;
- the existing LR Mermaid declaration pending later measured visual QA;
- all current dynamic links and the absence of hard-coded internal HTML links;
  and
- the provisional principal/supplement output roles. This order changes no
  output role or styling beyond the two provenance-table layouts needed for
  truthful identities.

## Evidence to return

Return one completion packet containing:

1. exact pre/post SHA-256 values for the QMD and focused test;
2. reverse-substitution evidence or an exact zero-context hunk map proving the
   delta is limited to the approved setup, provenance prose, two table
   displays, and focused assertions;
3. R 4.6.1 static parsing of all 11 QMD R chunks and the focused test;
4. a source-only run of `Rscript tests/test_preparation07_report.R`;
5. byte-identity proof for the sealed audit inputs, strict verifier,
   historical manifest, current context RDS/CSV, selection files, source CSV,
   PNG, SVG, configuration, and stale HTML;
6. proof that the table/figure label sets, stored artifact references,
   scientific numeric tokens outside the approved evidence additions, and
   non-provenance executable chunks are unchanged;
7. `git diff --check` for the two edited files; and
8. a durable owner verification record and non-circular manifest.

Stop on any scientific discrepancy, unexpected source drift, failed sealed
evidence check, or need to change a protected file. Return it to the
harmonization coordinator instead of resolving it editorially.

Do not render. Preparation 07 and all later REPORT-017 targets remain held
until this source/test revision is independently accepted and a separate
single-target render is explicitly released.
