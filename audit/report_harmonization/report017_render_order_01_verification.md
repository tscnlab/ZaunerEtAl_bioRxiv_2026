# REPORT-017 Phase 4 order 01 verification

Date: 2026-08-13  
Scope: Descriptives target render and display-only acceptance  
Status: **source and target render accepted; principal-output appearance remains provisional for author review**

## Released inputs

Immediately before execution, the owner rechecked the three release
identities:

- `notebooks/descriptives.qmd`:
  `b631936d9e47c4988dd453ea22184090b076705e3716e8f037e1953e3309cd4c`;
- `_quarto-nathealth.yml`:
  `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`;
- `scripts/descriptives/build_publication_tables.R`:
  `3b75ff59af4ddb0d8f74c905f60e06539c2a8490cf29f4fa44ac74c524895834`.

All matched the coordinator's released identities. The normal-profile startup
gate had already passed under the sealed environment record
`report017_environment_startup_repair_verification.md`.

## Targeted render

The owner ran exactly one fresh command with narrowly elevated access to the
existing user-owned renv cache:

```text
quarto render notebooks/descriptives.qmd --profile nathealth
```

The ordinary project `.Rprofile` and `renv/activate.R` path remained active.
R was 4.6.1 and Quarto was 1.9.37. The command completed in 51.851 seconds
with exit status 0. All 31 knitr steps completed, including the four converted
native-`gt` endpoints. No second render ran.

The accepted HTML is:

- path: `_build/nathealth/notebooks/descriptives.html`;
- SHA-256:
  `51c674b3a416e3d5dda4c0f86c7e46818f8ae94fa052c0f060f5cd56821c4ffd`;
- bytes: 2,262,269.

## Protected and build inventories

The established pre-render and post-render inventories compared path, byte
count, modification time, and SHA-256.

- All 125 protected files remained byte- and metadata-identical. Both
  inventory files have SHA-256
  `d38c0000f21aea62cf91006ee413c27aa768c37af86a32747ca35eef3d39950d`.
- The Nature Health build retained 827 files. Exactly three contents changed:
  the targeted Descriptives HTML, `search.json`, and `sitemap.xml`.
- One Bootstrap stylesheet was touched but remained byte-identical at
  `b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c`.
  No other build content or metadata changed.

The final support identities are:

- `_build/nathealth/search.json`:
  `797b7ffd3f0c002d9b9327ffe539a3846fe80508abf5c279e1232feb42b3310a`;
- `_build/nathealth/sitemap.xml`:
  `81225707d58d848986845a332ae62e15485681f1afce1c06da39b589d3a9107c`.

The independent harmonization-worker subset remains 101 stored table,
figure, source-data, manifest, and audit files, totaling 104,084,718 bytes.
Its sorted SHA-256-list digest remains
`853c3c08ee9eb3484d16a9c2bdf1da591a335083e8a5d5f0bbaca4a12a9e015e`.
The stored participant-table PNG remains
`875164c74f784554cc6878c330bf2df5c723325e99c1d92200ca4f848c840582`
and was not regenerated.

## Semantic display contract

Read-only R 4.6.1 checks of the accepted HTML establish that all eight target
endpoints occur exactly once. Every table endpoint is a semantic native
`gt_table`:

| Endpoint | Headers | Data rows | Footnote blocks |
|---|---:|---:|---:|
| `tbl-participant-site` | 11 | 22 | 10 |
| `tbl-near-eye-metrics` | 14 | 17 | 4 |
| `tbl-recommendation-context` | 11 | 11 | 6 |
| `tbl-descriptive-sample-flow` | 4 | 8 | 0 |
| `tbl-descriptive-comparison-summary` | 2 | 6 | 0 |
| `tbl-descriptive-visual-export-comparison` | 6 | 10 | 0 |
| `tbl-descriptive-figure-contract` | 17 header cells across 12 columns | 6 | 0 |

The accepted stored-input contract also passes: the four converted display
objects and the main participant table are native `gt_tbl` objects; their
accepted shapes, keys, order, and input-object hashes remain unchanged.

The main figure resolves to the unchanged stored PNG, uses 100% column width,
and has nonempty alt text covering the protocol, nine country-coded sites,
collection dates, photoperiod, and repeated primary near eye profile.

## Reader language and links

The current HTML contains all five corrected reader strings and no occurrence
of `Near-eye`, `near-eye only`, or `submitted grouping` in main content. The
participant table now defines the placement roles and employment categories
without construction-history language. The metric and recommendation tables
use `near eye` consistently.

Quarto emitted these profile-relative links:

- `Preparation 01` to
  `../notebooks/preparation/01_import_state_alignment.html`;
- `Preparation 02` to
  `../notebooks/preparation/02_coverage_sample_flow.html`.

Both resolve to existing accepted HTML pages. There are no unresolved local
reader targets and no reader link exposes `.qmd`, `file:`, `_build`, or an
absolute local path. The first focused test run expected a shorter but
equivalent relative spelling. The owned test was repaired to validate link
identity and resolution instead of one serialized href spelling. It now
passes at SHA-256
`58c71f9220207825071883fe7436a9cb5dcfb33ea015eafcf2301096c24b858d`.

The active sidebar is `Descriptive results`. All nine registered
country-coded site labels are present. The final R 4.6.1 structural results
are:

- Descriptives render contract: PASS;
- post-render semantic HTML contract: PASS;
- navigation contract for 35 accepted sources: PASS;
- reader-link contract for 35 QMD sources and all 86 deviation anchors: PASS;
- country-coded site-name contract for 35 sources: PASS;
- error, warning, and stderr elements in the HTML: zero; and
- `git diff --check`: PASS for the scoped source, tests, and records.

The refreshed `phase4_corpus_manifest.csv` records the accepted source and
HTML identities and has SHA-256
`5ef78c0ce704dc66d916206f6acd38473b52e45dfba5cd43335cb19da6286b23`.

## Final-size review

At a desktop viewport, the reader content column measured 988.5 px. The main
figure measured 988.5 by 941.4 px and was visually inspected at a calibrated
170 mm-equivalent viewport. Its five panels, country-coded labels, caption,
and primary-profile context are readable without clipping.

At the desktop content width:

- sample flow, recommendation context, and comparison summary fit the 989 px
  table container;
- the participant table is 1,171 px wide at 12 px table text;
- the metric table is 1,798 px wide at 16 px table text;
- the visual-export comparison is 1,388 px wide; and
- the figure contract is 1,311 px wide.

The four wider tables use local horizontal scrolling rather than smaller
type. At the 708 px publication-width viewport, the content region measured
657 px, those scroll containers remained available, and the main figure fit
the content region. The page itself also reported a 1,720 px layout scroll
extent because of the wide table descendants. This is a known HTML
presentation limitation, not missing or clipped table content. It preserves
legibility and exact values but requires reader interaction on narrow screens.

The principal main figure and table roles, and the choice to retain local
scrolling for dense tables, remain provisional pending the author's visual
review. The unchanged stored participant-table PNG is a pre-correction preview
and is not used as evidence for the corrected HTML footnotes.

## Boundary and disposition

No scientific input, value, denominator, estimate, interval, p-value,
diagnostic, sensitivity result, claim, figure, table data, source-data file,
manifested scientific artifact, package, lockfile, configuration, central
ledger, bibliography, or manuscript file changed. No scientific builder,
model operation, bootstrap, simulation, full render, commit, or push ran.

Descriptives is accepted for Phase 4 source and target-render integration.
Its principal-output appearance stays provisional for author review. The
serial queue may advance to Preparation 01 through 07; DOC-001 remains open.

