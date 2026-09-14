# REPORT-014 Preparation 07 source/test independent acceptance

Date: 2026-08-14  
Reviewer: report harmonization coordinator  
Status: **accepted for source and focused test; render remains held**

## Accepted identities

| File | Accepted SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/07_example_days.qmd` | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` | 39,361 |
| `tests/test_preparation07_report.R` | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` | 11,897 |

The QMD implements the author-approved `PREP07-PROV-001` provenance-only
repair. It preserves the truthful historical producer file identity, pins the
accepted current site/daylight-context identity, reads only the sealed stored
equivalence evidence, and distinguishes exact file identity from verified
scientific-value equivalence. It changes no data, selection, figure, source
data, scientific value, or analytical handoff.

The focused test implements the approved classification and whitespace-only
repairs. It retains the scientific, execution-boundary, provenance, native-
table, figure, site, source-data, link, and rendered-error gates.

## Independent source review

The released pre-order source and test were independently recovered from the
owner's temporary pre-edit evidence. Their SHA-256 identities reproduce the
released pins exactly:

- pre-order QMD:
  `2293d2520dabaacc7394a39c00b5ac62911da1d34fb489ecf4bf232c55a2998f`;
- pre-order focused test:
  `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f`.

Zero-context review confirmed that the QMD delta is limited to:

1. sealed audit/evidence/seal identity and structure checks in the existing
   setup chunk;
2. the approved historical/current site/daylight disposition;
3. the exact approved reader explanation; and
4. the two existing provenance table displays and their immediately
   surrounding technical explanation.

The source still has exactly seven table labels, three figure labels, and the
unchanged LR Mermaid declaration. The selection, plotting logic, site order
and colours, captions, alt text, source-data link, and eight non-provenance
chunks are unchanged. The current QMD does not run a builder or strict
scientific verifier and does not write an artifact.

## Independent focused-test review

The final owner repair changed exactly two search targets:

```diff
-  grepl("figure source-data CSV", visible, fixed = TRUE) &&
-    grepl("split into three three-panel figures", visible, fixed = TRUE),
+  grepl("figure source-data CSV", visible_flat, fixed = TRUE) &&
+    grepl("split into three three-panel figures", visible_flat, fixed = TRUE),
```

Both required reader phrases and every other assertion remain unchanged.
The owner's pre-edit test copy independently hashes to
`a22182cb9b15e96d5c9e8dd66e98c486345d996c947ca757044f0bdbe0a96457`,
and the two-line diff produces the accepted final test identity above.

An independent R 4.6.1 source-only execution of
`Rscript --vanilla tests/test_preparation07_report.R` returned exit status 0:

```text
PASS: Preparation 07 satisfies the bounded-render, fixed-input, gt-table, accessible-figure, site-display, and provenance contract.
```

The test statically parsed all 11 QMD R chunks. No QMD chunk was evaluated.

## Owner evidence and protected identities

The final owner verification record is
`audit/preparation_reports/report014_preparation07_visible_flat_test_repair_verification.md`,
SHA-256
`36a2da7b7c30685ff725b93d680a7d61d263249af1afb24dd08157392477aced`.
Its non-circular 32-entry manifest is
`audit/preparation_reports/report014_preparation07_visible_flat_test_repair_manifest.csv`,
SHA-256
`a72b0e09f08aa8d480ad54f9ec9d3a590fcd689bd4cf82fe7492f734413aa7b9`.

Independent checksum verification passed all 32 manifest rows, including byte
counts. The protected set includes the accepted QMD, stale HTML, profile,
historical manifest, strict verifier, site/daylight files, selection files,
source-data CSV, durable PNG and SVG, sealed equivalence evidence, both prior
stopped checkpoints, and `renv.lock`.

Key unchanged identities are:

| Protected file | SHA-256 |
|---|---|
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| stale Preparation 07 HTML | `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc` |
| strict showcase verifier | `9a39ce7ab8e99187fdf14f2b750c3e3f9aa308de127e75a4923639dfb84d49b6` |
| historical showcase manifest | `c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322` |
| current site-context RDS | `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0` |
| equivalence audit | `870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164` |
| equivalence evidence | `0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97` |
| equivalence seal | `01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

`git diff --check` passes for the accepted QMD and focused test.

## Disposition

The Preparation 07 provenance-only source/test revision is independently
accepted. No scientific discrepancy remains, and no reader-source correction
is pending before rendering.

This acceptance does not release a render. Preparation 07 and all later
REPORT-017 targets remain held until the central coordinator issues a separate
single-target render order under the existing normal-profile, protected-input,
native-table, semantic-link, and secure-loopback visual-QA contract.
