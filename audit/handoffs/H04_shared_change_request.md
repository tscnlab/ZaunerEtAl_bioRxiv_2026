# H04 shared change request

Date: 2026-08-11

Requested owner: coordinating task

## Resolved locally: METRIC-010 provenance repin

During preparation-report verification, the shared near-eye and chest
one-hour RDS files had the current METRIC-010 provenance pins rather than the
byte identities recorded when H04 was fitted:

| Input | Accepted H04 SHA-256 | Current SHA-256 |
|---|---|---|
| Near-eye one-hour outcome | `cee864bb0e329b98444088b777c7245250be68111ec9f24db7c0e3f395ed6445` | `27b17c0232a90b6982377b1944b30e5574a02e691217a81f671ab14e45916f67` |
| Chest one-hour outcome | `50f50ca5d39d621d06f2794037c4b769e01fc7329a70432e79a51203727ed209` | `99885940c952c60ff6981ce029758ac43aec22c41cc27f22176fb3ab4f9c7186` |

The H04 worker did not modify either shared input. Under R 4.6.1,
`verify_h04_metric010_frame_invariance.R` rebuilt all 14 H04 analysis frames
from the current inputs and compared them with the accepted frozen frames at
tolerance zero. All frame values, row counts, column counts, and ordering were
identical. Twelve main-input-derived frames differed only in embedded
metric-setting attributes; the two gap-timing-unaware frames were also
attribute-identical. The evidence is:

- `artifacts/08_diagnostics/H04/H04_metric010_frame_invariance.csv`, SHA-256
  `0beda6a458c46e2d79e1a90d45dd9acdfcca5968e5e958ab2a6b6d535ac8fb68`;
- `artifacts/08_diagnostics/H04/H04_metric010_input_reconciliation.csv`,
  SHA-256
  `8968f0f63377329c5df447c20166f7857ac19b4b2124aedf8417dfb8f1091f3a`.

The H04-local current input pins were updated. Accepted frozen model objects,
estimates, intervals, diagnostics, sensitivities, and claims remain
controlling; no model was refit. No shared data or preparation change is
requested for this already-reconciled repin.

## Nature Health profile registration

The completed H04 analysis-preparation companion needs two coordinator-owned
entries in `_quarto-nathealth.yml`:

1. add
   `audit/hypotheses/H04/H04_analysis_preparation.qmd` immediately after
   `notebooks/hypotheses/H04.qmd` in the project render list; and
2. add a navigation item immediately after **H04 results** with the text
   **H04 preparation and provenance** and the href
   `audit/hypotheses/H04/H04_analysis_preparation.qmd`.

The H04 worker will not edit the shared profile. Until the coordinating task
registers these entries and performs the integrated profile render, H04 uses a
direct single-document render and a byte-identical temporary copy under
`_build/nathealth/audit/hypotheses/H04/`, matching the accepted H03
preparation-companion pattern.

## Verification after the shared change

Run the focused H04 preparation test after the profile render:

```bash
NATHEALTH_PROJECT_ROOT=<project-root> \
Rscript --vanilla tests/hypotheses/H04/test_h04_preparation_report.R
```

The shared verifier should then confirm that the result and preparation pages
are adjacent in both the render list and navigation, that their links are
reciprocal, and that the website-path source is byte-identical to the H04
authoring source.
