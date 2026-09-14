# REPORT-017 order 32e: H01 order-32d consolidated continuation

Date: 2026-08-15

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released as one continuation containing the three accepted harness
repairs and every remaining part of order 32d. Do not split this work. The H01
companion and every later REPORT-017 target remain held.**

## Authority

The controlling parent order remains
`audit/report_harmonization/owner_orders/32d_h01_consolidated_display_repair_and_rerender.md`,
SHA-256
`f0c1a708258ec5b3e24e0f209e4ad46d5c61115728ade6f59750e6f490206a37`.

The accepted stopped-state authority is:

- independent acceptance
  `audit/report_harmonization/report017_h01_order32d_stopped_state_independent_acceptance.md`,
  SHA-256
  `b1c46acc3369b6c878bafff9ab3981d2ece296bedcba27c42fe21481ba89664d`;
- 25-row independent seal
  `audit/report_harmonization/report017_h01_order32d_stopped_state_independent_manifest.csv`,
  SHA-256
  `906a8e06a6811ae5957b585c112b4c3a151253a8a8975bf8b130d0c7e37b7ca7`;
  and
- stopped implementation
  `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`, SHA-256
  `71062634e718c588a2e885ae05ff1d745a020eca18ab7de8ecd7666da544c3e2`.

The coordinator independently reproduced the three implementation-harness
findings and authorized them together under this continuation.

## Complete preflight

Before any mutation, re-audit every row of the 25-row stopped-state seal and
require these exact live pins:

- result QMD `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`;
- companion QMD `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- result HTML `d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410`;
- frozen companion HTML, using only the full corrected identity,
  `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`;
- Nature Health profile
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- accepted builder
  `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7`;
- stopped sealer
  `audit/hypotheses/H01/report017_order32d_display_repair/seal_h01_order32d_stopped_state.R`,
  SHA-256
  `d1f093ba5cf0f988e460639f5ff25995318215eac869ccc50d442ef60b744aaa`;
- the three frozen source CSVs and six durable figures at the exact identities
  in the 25-row seal; and
- every current test, manifest, semantic hook, H01 protected file, and build
  member retained by order 32d.

Require `/private/tmp/H01-order32d-candidates.nW90PN` to exist and remain
empty. Require `/private/tmp/H01-order32d-quarantine.Xc28uF` to contain exactly
the three accepted recovery files with the exact paths, SHA-256 values, byte
counts, regular-file status, and nonsymlink status in
`quarantine_recovery_evidence.csv`. The three original duplicate paths must
remain absent. Do not move, delete, rename, recreate, or otherwise touch any
recovery file.

Stop before mutation on any drift.

## Part A: three exact harness repairs

### A1. Observed-category guard

In `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`, change only the two
observed-category comparisons:

- require model-support observations to equal exactly `Not supported` and
  `Supported`;
- require diagnostic observations to equal exactly `Not applicable`, `Pass`,
  and `Review`.

Keep the paired-scale and matched-sample checks unchanged. Keep every broader
declared plotting level, including unused `Not estimable` and `Fail`, unchanged
in factors, scales, colours, labels, legends, and construction code.

### A2. Air formatting

Run Air 0.4.1 formatting only on the new refresh implementation after the two
guard changes. Record pre-guard, post-guard/pre-format, and post-format
identities. Require:

- R 4.6.1 parsing before and after;
- an exact semantic/AST comparison showing that formatting made no expression
  change;
- an exact source-diff classification containing only the two guard changes
  plus Air whitespace/layout changes; and
- `air format --check` PASS after formatting.

Do not format or edit another file.

### A3. Continuation sealer path basis

Preserve the stopped order-32d sealer byte-for-byte. Copy it into the new
order-32e evidence directory or create an equivalent continuation sealer.
Change only the **build-delta** quarantine membership comparison from
`expected_quarantine$original_path` to
`expected_quarantine$recovery_relative_path`.

The **protected-inventory** comparison must remain against
`expected_quarantine$original_path`, because protected paths are
project-relative and retain the `_build/nathealth/` prefix. Require an exact
one-expression diff and reverse proof against the stopped sealer.

## Part B: one non-mutating repaired-classification preflight

Before candidate generation, run one non-mutating R 4.6.1 preflight that
proves all of the following together:

- exact source hashes, row counts, keys, and observed category sets;
- all 30 paired matched-sample flags remain true;
- the repaired observed-category guard passes;
- stopped build-inventory paths are relative to `_build/nathealth` and the
  three quarantine paths match exactly through `recovery_relative_path`;
- protected-inventory paths are project-relative and the same three paths
  match exactly through `original_path`;
- zero fourth mismatch exists in either path basis;
- the old failed candidate directory is still empty; and
- the quarantine remains exact.

This preflight may not create a candidate, change a project file, or replace a
durable output. If it fails, stop once and seal the complete state without
patching or retrying.

## Part C: resume the complete order-32d artifact package

After Parts A and B pass, create one fresh candidate directory under
`/private/tmp`. Do not reuse the old failed directory. Resume every candidate
and validation requirement in Parts B and C of order 32d, including:

- source-derived reproduction of the sealed pre-repair Figures 1, 5, and 6;
- Figure 5 direct-label layout only, preserving all data and geometry;
- Figure 1 and Figure 6 text and status-symbol sizing only, reaching at least
  7 points at the accepted 708-pixel final display;
- temporary PNG/SVG candidates first;
- exact source-row, key, value, mapped-aesthetic, layer, label, tile, status,
  symbol, panel, scale, ordering, dimension, DPI, and normalized-SVG checks;
- original-size, intended-final-size, 1440-pixel, 708-pixel, and 200-percent
  QA; and
- replacement of the six durable PNG/SVG targets once only, after the complete
  candidate set passes.

Temporary candidate tuning may change only the display parameters already
authorized by order 32d and must record every attempt. A genuinely new
implementation, source, data, scientific, or validation defect invokes the
one-combined-stop rule.

Update only the corresponding display literals in the accepted builder and do
not run the full builder. Copy the old semantic checker and correct only its
two retired section-ID expectations. Add the focused tests and reseal only the
directly dependent current manifest rows from leaves upward. Preserve all
historical and prior stopped evidence byte-for-byte.

Run the complete focused display, H01 reporting, REPORT-016, corrected
semantic, manifest, protected-inventory, R parsing, Air, source-data, and scoped
diff checks. Finish the entire safely executable check set before stopping on
any failure.

## Part D: exactly one H01 result render and complete acceptance

Only after all source, candidate, artifact, test, and direct-manifest checks
pass, create fresh pre-render inventories and run exactly once:

```sh
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

Use normal R 4.6.1 project startup and only the established narrow access to
the existing user-owned renv cache if required. Do not bypass the profile or
semantic hook and do not use `--no-execute`.

Complete every semantic, native-gt, endpoint-order, link, deviation-anchor,
source-data, navigation, country-code, error-node, protected-science, and build
classification requirement from Parts D and E of order 32d. The only
content-changing build outputs permitted are those already listed in order
32d, and the three quarantined duplicate paths must not reappear.

Run one secure read-only loopback inspection rooted exactly at
`_build/nathealth`, bound only to `127.0.0.1`, using the in-app Browser. Inspect
the complete result page at 1440 by 1000 and 708 by 1000, all ten figures at
final display size, Figures 1, 5, and 6 at intended final size and 200 percent,
and the principal table at desktop, narrow, and 200 percent. Apply the accepted
contained narrow-scroller table policy. Stop the server and prove no listener
and no post-QA drift.

Return one non-circular evidence manifest and one complete accepted result or
one complete stopped-state defect list.

## Prohibited work

Do not change a QMD, source-data value, model, estimate, interval, p-value,
FDR decision, diagnostic, sample, scientific artifact, profile, central ledger,
package, or lockfile. Do not fit, refit, predict, simulate, bootstrap, resample,
rerun Shapley, run the full reporting builder, render the companion or a later
target, run a full-project render, commit, push, upload, or delete a recovery
file.

The H01 companion and every later REPORT-017 target remain held until this
single continuation return is independently accepted.
