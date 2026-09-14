# REPORT-018 Brown order 65 dispatch

Date: 2026-09-02

Destination task: `019fffdf-66d4-7802-9091-09283ad27b7f`

## Disposition

The previously proposed Brown Stage 3 recommendation-window and BA-M display
package is released exactly once as owner order 65. It resolves queue item 1
from the post-navigation display queue. The later accepted 12 px table
convergence is preserved through a two-row current pin overlay. No scientific
result, model, source data, sample, estimate, interval, p-value, FDR decision,
or claim is changed.

## Dispatch controls

- Queue SHA-256:
  `9ebb1d81ef202b420aec42d12e5de372871edec780c5f72885e18d327f0f5a36`.
- Final order SHA-256:
  `497aa2f1ece654f908f2b58abfaf04f4887a7af0da81b183ea582fd4a8f9cef5`.
- 42-action matrix SHA-256:
  `ee5c41c7c135b4bce257c5f7556ff2c3b023869afe7c6ae097c78fc8ac10b777`.
- Historical 57-row inventory SHA-256:
  `b1f7ced77ade2ce95480f3b43d6cbeb0649f672c403a3c6336da7c7a944f14b5`.
- Current two-row pin overlay SHA-256:
  `4f3ab64ca80252e2f2a1c8eb5d58da4863475bd3aa691013b6ebf73831df46ab`.
- Current R 4.6.1 preflight checker SHA-256:
  `89538ab9ccb98798f7f1a94f8e626514bda12b046533115351337629f4d14ca5`.

## Independent pre-send check

The current checker completed under R 4.6.1 with:

`BROWN_ORDER65_PREFLIGHT=PASS inventory=57 pins=39 matrix=42 qmd=19 builders=13 assets=10 ba_manifest=38 R=4.6.1`

It rehashed all current pins, overlaid only the two accepted QMD transitions,
confirmed all 42 matrix actions, applied and reversed all 32 text
substitutions in memory, reproduced six exact prospective source identities,
verified frozen display-source dimensions and current figure geometry, parsed
all four prospective builders, and confirmed that the 36 unchanged rows of
the historical BA-M manifest plus the two current QMD overlays are exact.

## Execution boundary

The owner may execute only the source/display order. No Quarto, Pandoc, knitr,
HTML mutation, analysis, fit, prediction, inference, resampling, or manuscript
edit is authorized. A separate independent acceptance is required before any
serial render release.
