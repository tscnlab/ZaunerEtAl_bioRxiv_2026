# REPORT-017 H01 order 32d stopped-state independent acceptance

Date: 2026-08-15

Status: **Accepted as a fail-closed implementation-harness stop. No durable
figure, report, manifest, or rendered-page change occurred. A separately
authorized consolidated continuation is required.**

## Authority and scope

The controlling order is
`audit/report_harmonization/owner_orders/32d_h01_consolidated_display_repair_and_rerender.md`,
SHA-256
`f0c1a708258ec5b3e24e0f209e4ad46d5c61115728ade6f59750e6f490206a37`.
Its 34-row dispatch seal is
`audit/report_harmonization/report017_h01_order32d_dispatch_manifest.csv`,
SHA-256
`69ba1a555e195ad80b96dd68ad29d21e94e75fb5c03667db9e13e02ef7ccec24`.

The H01 owner completed the strict pre-inventory and recoverable quarantine,
created the bounded candidate implementation, and made one temporary candidate
attempt. The attempt stopped before creating a baseline or candidate figure.
The owner then stopped without patching or retrying, as the order required.

## Independent findings

### RH-H01-32D-IMPL-001: overstrict unused-level guard

Classification: implementation-harness defect, confirmed, no scientific or
reader-source discrepancy.

The new refresh implementation required the current frozen model-support data
to contain `Not estimable` and the current frozen diagnostic data to contain
`Fail`. R 4.6.1 independently confirmed the exact stored sets:

- model support: `Not supported`; `Supported`;
- diagnostic assessment: `Not applicable`; `Pass`; `Review`;
- paired effect scale: `Difference`; `Ratio`; and
- all 30 paired rows have `sample_exactly_matched == TRUE`.

The three source files retain their sealed identities and contain 136, 204,
and 30 rows, respectively. The unused declared categories are valid scale
possibilities but are not observed in the current frozen inputs. Requiring
them to be observed is therefore a guard-classification error. The smallest
fail-closed repair is to require the exact observed sets above while retaining
all later factor-level and scale declarations.

### RH-H01-32D-IMPL-002: new-script formatting

Classification: mechanical implementation defect, confirmed.

Air 0.4.1 reports that
`scripts/hypotheses/H01/refresh_h01_order32d_figures.R`, SHA-256
`71062634e718c588a2e885ae05ff1d745a020eca18ab7de8ecd7666da544c3e2`,
requires formatting. Formatting this newly created script is allowed only in a
separately authorized continuation and must not alter its semantics.

### RH-H01-32D-IMPL-003: stopped-sealer path basis

Classification: evidence-harness defect, confirmed.

The stopped-state build inventory records paths relative to
`_build/nathealth`, while the quarantine table's `original_path` values include
the `_build/nathealth/` prefix. Consequently, the sealer compared unlike path
bases and labelled the three authorized absences as unexpected. Its comparison
must use the already present build-relative `recovery_relative_path` values.
No fourth build difference exists.

## Preservation and quarantine acceptance

Independent R 4.6.1 reconciliation passed:

- 1,704 common protected files retain exact SHA-256 and byte counts;
- all 818 common build files retain exact SHA-256 and byte counts;
- the only removed protected paths are the three authorized duplicate build
  files;
- the only newly present protected path is the stopped refresh implementation;
- the six durable figure targets, accepted builder, result and companion QMDs,
  result HTML, and frozen companion HTML remain exact; and
- no Quarto render, browser server, model operation, scientific calculation,
  manifest reseal, or durable candidate replacement occurred.

The duplicate files remain recoverable under
`/private/tmp/H01-order32d-quarantine.Xc28uF`. The three recovery files retain
their exact original hashes and byte counts. The stopped candidate directory
`/private/tmp/H01-order32d-candidates.nW90PN` is empty.

The only valid frozen companion HTML SHA-256 remains
`5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

## Consolidated continuation recommendation

To avoid another sequence of piecemeal orders, authorize one continuation that
keeps the existing quarantine and repairs all three harness defects before
resuming the remaining order-32d package:

1. change only the two overstrict observed-category comparisons;
2. format only the new refresh implementation with Air 0.4.1;
3. change only the sealer's quarantine-path comparison to the build-relative
   values;
4. run one non-mutating R 4.6.1 preflight that proves the repaired category and
   quarantine classifications before candidate generation;
5. create one fresh temporary candidate directory and execute the complete
   three-figure candidate, validation, one-write replacement, focused reseal,
   exactly-one-render, semantic, and visual-QA sequence from order 32d; and
6. retain the one-combined-stop rule for any newly exposed defect.

No H01 companion or later REPORT-017 render should be released before this
continuation is independently accepted.

