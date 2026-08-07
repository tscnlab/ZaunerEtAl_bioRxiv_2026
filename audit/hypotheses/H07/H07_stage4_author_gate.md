# H07 Stage 4 closure gate

Decision ID: `H07-005`
Date: 2026-08-07
Branch: `rewrite/NH`
Status: **approved; H07 worker closed, shared site integration pending**

## Decision context

Decision `H07-004` accepted the standalone reader report and authorized the
scientific analysis-preparation and provenance companion. Stage 4 is a bounded
documentation step, not another inferential analysis. It preserves the
accepted six-of-nine primary near-eye and seven-of-nine complementary chest
derivative-pattern classifications and every stated limitation.

## Deliverables ready for acceptance

- preparation source:
  `audit/hypotheses/H07/H07_analysis_preparation.qmd`;
- bounded standalone preparation render:
  `audit/hypotheses/H07/H07_analysis_preparation.html`;
- expected website source and render copies under
  `_build/nathealth/audit/hypotheses/H07/`;
- preparation artifact builder:
  `scripts/hypotheses/H07/build_h07_preparation_artifacts.R`;
- preparation manifest builder:
  `scripts/hypotheses/H07/build_h07_preparation_report_manifest.R`;
- focused verifier:
  `tests/hypotheses/H07/test_h07_preparation_report.R`;
- nine preparation source-data CSVs and two preparation figures under
  `artifacts/11_source_data/H07/preparation/` and
  `artifacts/10_figures/H07/preparation/`;
- four-figure REPORT-011 record, six A4-equivalent raster proofs, and a
  preparation provenance manifest under `artifacts/12_manifests/H07/`; and
- coordinator-owned integration request:
  `audit/handoffs/H07_shared_change_request.md`.

The companion contains the preregistered hypothesis, the revised plateau
assessment at the beginning, exact nine-metric response contracts and
Wilkinson formulas, metric-specific samples, site/latitude/photoperiod and
collection-period support, repeated-participant structure, derivative
settings, diagnostic evidence, sensitivities, leave-one-site-out influence,
code order, file identities, environment identity, and claim boundaries. It
links reciprocally with the H07 results report.

## Verification disposition

- All four consequential input identities pass.
- All 18 primary metric frames pass serialized-object identity, schema,
  unique-key, response-reconstruction, count, and latitude-within-site checks.
- The rendered companion contains 20 semantic `gt` tables, two external
  figures with captions and non-empty alternative text, and one Mermaid
  analysis map.
- The source and expected website QMD copy are byte-identical.
- Executable preparation cells contain no model-fit, prediction, derivative,
  simulation, or bootstrap call.
- All four reader-facing H07 figures pass REPORT-011 inspection at 170-mm
  display width; effective essential text is at least 7.81 pt.
- The H07 preparation verifier passes under R 4.6.1 before shared-site
  integration.

No new model was fitted, no prediction or derivative was recalculated, and no
bootstrap or simulation was run in Stage 4. The only result-report change was
the reciprocal preparation-page link. The two existing results figures were
re-exported at unchanged pixel dimensions with a physical-size-safe canvas
and shorter subtitle wrapping; their scientific content is unchanged.

## Shared integration still required

The H07 worker did not edit `_quarto-nathealth.yml`. The coordinator must add
the preparation source immediately after the H07 result in both the render
list and navigation, run the bounded H07 result/preparation render, rebuild
the H07 preparation manifest, and rerun the focused verifier. The exact
requested YAML is recorded in `audit/handoffs/H07_shared_change_request.md`.

## Accepted closure decisions

- `H07-S4-001`: accept the preparation companion as an accurate provenance
  account of the accepted H07 result.
- `H07-S4-002`: accept the bounded execution boundary, exact formula/sample
  records, and no-refit verification.
- `H07-S4-003`: accept the final-size figure readability evidence and
  display-only Stage 3 figure repair.
- `H07-S4-004`: authorize coordinator-owned shared-site integration and final
  central-ledger closure without scientific recomputation.

The author approved `H07-S4-001` through `H07-S4-004` on 2026-08-07 and
requested that the H07 worker wrap up and commit the H07-owned work.

Reopen the scientific result only if shared integration or a focused verifier
exposes a changed input, model frame, formula, estimate, derivative
classification, diagnostic disposition, sensitivity result, or claim. A
navigation, link, provenance, or display-only repair does not reopen the
accepted inference.
