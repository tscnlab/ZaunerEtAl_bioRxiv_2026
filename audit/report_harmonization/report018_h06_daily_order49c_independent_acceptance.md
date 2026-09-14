# REPORT-018 H06_daily order49c independent acceptance

Date: 2026-08-21

Status: **ACCEPTED**

## Disposition

The order49c owner return is accepted as a clean browser-capability stop, and
the missing viewport coverage has now been completed independently against the
preserved canonical HTML without editing or rerendering it. No reader-facing,
semantic, scientific, build, or protection defect remains.

The accepted H06_daily result and preparation/provenance companion are both
complete under REPORT-018. Brown language harmonization and later serial
renders were not touched during this acceptance.

## Accepted identities

- companion source:
  `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`, SHA-256
  `b1d2c9ec6184e9c537af04119d94040b581ae691069e38e0a713935ab1582536`,
  35,521 bytes;
- canonical companion HTML:
  `_build/nathealth/audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html`,
  SHA-256
  `768d4675a54e183ddc06df66a255c6d83919268d16f02d27169ec89f5bbb0fd6`,
  5,570,770 bytes;
- accepted result source:
  `notebooks/hypotheses/H06_daily.qmd`, SHA-256
  `8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`;
- accepted result HTML:
  `_build/nathealth/notebooks/hypotheses/H06_daily.html`, SHA-256
  `74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`;
- profile:
  `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

The obsolete source-side HTML remains absent. Its historical identity remains
preserved only in historical evidence, as accepted after order49b.

## Owner return replay

R 4.6.1 independently verified the 74-row non-circular owner manifest at
SHA-256
`92d7c0b6f7bcbda38dbe050458742b15ea3e23b1f0e323220863fee87886f025`.
The owner fail-closed record is SHA-256
`eaab2c905f59ed5756af41af0532a074383c704dd66e29f363168ee7c3364a66`.

The single render exited successfully. The static contract already passed:

- exactly 17 native gt tables, one stored figure, one top-down analysis-path
  diagram, and two dynamic reader links;
- the stored figure is embedded from the exact accepted PNG at SHA-256
  `f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff`;
- 905 header-bearing attributes and 1,193 header tokens resolve correctly;
- the semantic hook made 1,003 reversible substitutions across the 17 tables;
- the semantic ledger reverses the accepted HTML exactly to pre-hook SHA-256
  `1c65ce045383951d98114b36bae4382058c82c18175656e5c7526a2a6badc7bf`;
- all 424 reader links resolve, all nine country-coded study sites are present,
  and there are no embedded problem nodes or user-local resource paths.

## Completed viewport QA

The missing checks were performed on a temporary read-only server rooted
exactly at `_build/nathealth` and bound only to `127.0.0.1:50184`. The exact
companion route was inspected through explicit browser viewport overrides.

- At 1440 x 1000, the page had no horizontal overflow. All 17 tables were
  contained and the figure, diagram, navigation, headings, callouts, and links
  were usable.
- At 708 x 1000, the page had no horizontal overflow. All 17 tables remained
  contained. Three wider tables used contained scrolling. A representative
  table scroller moved from 0 to 100 pixels on a 109-pixel range.
- At 720 x 500, the accepted 200-percent-equivalent review had no page
  overflow. All 17 tables remained contained, and the responsive navigation,
  prose, figure, and diagram remained usable.
- The frozen figure was inspected at its 642-pixel, 170-mm-equivalent display
  width. Its complete labels, axes, legend, caption, and points were legible,
  with the already accepted 8.67-point minimum text size.
- The analysis-path diagram remained contained at 654 x 342 pixels with 13
  labels and a measured 16-pixel minimum text size.
- Browser console review found zero warnings or errors attributable to the
  page.

The browser tab was closed, the temporary viewport override was reset, the
server was stopped, and `lsof` confirmed no listener remained on port 50184.

## Post-QA protection

R 4.6.1 rehashed all 850 build members and all 3,527 protected members after
QA. Every SHA-256 and byte count remained exact. The build contains zero
symlinks. No Quarto command, source edit, QMD execution, scientific
computation, manifest builder, package or lock change, commit, push, or upload
was performed during the independent continuation.

## Conclusion

H06_daily result and companion integration is accepted. The serial render gate
may advance only through the next separately sealed REPORT-018 order.
