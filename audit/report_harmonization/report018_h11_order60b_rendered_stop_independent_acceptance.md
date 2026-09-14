# REPORT-018 H11 Order 60b rendered-stop independent acceptance

Date: 2026-08-22

Disposition: `ACCEPTED_RENDERED_NO_RERENDER_TEST_CONTRACT_STOP`

## Accepted stopped state

The H11 Order 60b return is independently accepted as a clean fail-closed
stop after one successful result render and before browser QA. The 67-row
owner seal is exact, unique, and non-circular. The accepted rendered but not
yet visually accepted endpoint is:

- `_build/nathealth/notebooks/hypotheses/H11.html`
- SHA-256
  `2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a`
- 306,265 bytes

The sole target render exited 0. All 53 knitr cells, Pandoc, and the configured
semantic hook completed. The semantic repair contains exactly 15 tables, 146
ID substitutions, 229 `headers` substitutions, and 375 total substitutions.
Independent reversal reconstructs the raw rendered HTML at
`f07fdab80eb8d7c8ae5e89c6c106d2ef04d77b727bd2ac24365057b5f3923cc8`;
reapplication reconstructs the accepted post-hook HTML exactly.

The only build changes are the H11 result HTML, `search.json`, and
`sitemap.xml`. No build path was added or removed, zero symlinks exist below
`_build/nathealth`, all 336 protected paths remain exact, all 193 H11
scientific assets remain exact, and the 25-file Sass cache inventory is
unchanged. The companion, sensitivity page, profile, lockfile, historical
manifests, handoff, and all source files remain fixed.

## Complete downstream disposition

Fresh R 4.6.1 replay identifies exactly three stale rendered-text assertions
in `tests/hypotheses/H11/test_h11_stage3_reader_report.R`:

1. `Gender is a distinct construct` must follow the accepted source wording
   `Gender identity is a distinct construct`.
2. `pointwise 95% intervals` must follow the rendered phrase
   `pointwise 95% confidence intervals`.
3. `0.050214` must follow the accepted reader display
   `displayed as FDR-adjusted p = 0.050`.

The full-precision chest activity-adjusted value remains exactly
`0.05021431625388684` in the frozen paired source. The reader page deliberately
rounds it to 0.050 under the accepted p-value display policy and does not bold
it. This is a test-contract transition, not a source or scientific defect.

The replay also identifies one downstream checker type-classification defect.
The 193-row scientific inventory has identical paths, SHA-256 values, and
numeric byte counts, but `identical()` rejects the in-memory numeric byte
column against the CSV-imported integer byte column. Column-wise path and hash
identity plus numeric byte identity passes 193/193 without weakening the
contract.

After applying only those four verifier classifications in temporary copies,
the complete post-render checker passes 14/14. Both complete transition-aware
H11 tests pass, all 15 tables and eight figures are present, all 584 table
header tokens resolve exactly once to a `th` in their own table, IDs are
unique, alt text is present, links and deviation anchors resolve, and no
embedded error or warning node is present. No additional masked failure
remains.

## Evidence

- independent checker:
  `scripts/report_harmonization/check_report018_h11_order60b_rendered_stop_and_downstream_replay.R`
- independent checks:
  `audit/report_harmonization/report018_h11_order60b_downstream_replay/independent_downstream_replay_checks.csv`
- exact prospective test transition:
  `audit/report_harmonization/report018_h11_order60b_downstream_replay/prospective_stage3_test_transition.csv`
- complete prospective post-render replay:
  `audit/report_harmonization/report018_h11_order60b_downstream_replay/prospective_postrender_replay/report018_h10_h11_checks_postrender.csv`

The mandatory next action is one no-rerender, test-only continuation followed
by the previously authorized bounded loopback QA. H11 companion and sensitivity
remain held.
