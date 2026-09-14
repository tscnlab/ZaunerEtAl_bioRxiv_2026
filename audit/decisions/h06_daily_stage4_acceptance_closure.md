# H06 daily Stage 4 acceptance and complementary-analysis closure

Decision ID: `H06-D-017`
Change ID: `CHG-136`
Date: 2026-08-13
Status: author approved; complementary analysis complete

## Author decision

The author accepted the bounded H06_daily preparation and provenance companion
with the instruction `approved - wrap up`. This closes `H06-D-G4` and the
scientific H06_daily task.

The accepted Stage 4 endpoint is:

| Artifact | SHA-256 |
|---|---|
| `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd` | `fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e` |
| `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html` | `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259` |
| `audit/hypotheses/H06_daily/H06_daily_stage4_preparation_gate.md` | `075d5e4b749d0e4f814dd925b54bea6a9619245b202e5d8f1f01a6a7debee974` |
| `audit/hypotheses/H06_daily/H06_daily_stage4_preparation_acceptance.md` | `8af64ee0f658f188bab55a06652ce91741a6909e08f6f4353a740d0daf069fad` |
| `artifacts/12_manifests/H06_daily/H06_daily_preparation_acceptance_manifest.csv` | `1923a5a81b16aee478436980f24bccc6ed58836550876e6758753640357eaad3` |
| `tests/hypotheses/H06_daily/test_h06_daily_preparation_report.R` | `4fbf8ba28dc957295ec5c90e42247f644c0010b3097195652d1e260fb6bdc2a0` |
| `tests/hypotheses/H06_daily/test_h06_daily_preparation_acceptance.R` | `c232630f6760c74e67378fcf9eeda06064d3bca671c0ffc8a3b57cfa782dfc32` |
| `audit/handoffs/H06_daily_worker_handoff.md` | `70482aaaa6c7de7554d54e2c193c3f4de1b6a2fb959ff64993e91cfb89550095` |

The frozen task-owned baseline is commit
`442ddd1b592374440f1446c26234c5d6e12cce92` (`Complete complementary H06
daily-metric workflow`). The commit contains only H06_daily-owned sources,
scripts, tests, audit records, and handoffs. It excludes central ledgers and
decisions, shared configuration, main H06, other hypotheses, generated HTML,
and `artifacts/` paths.

## Final scientific hierarchy

- `notebooks/hypotheses/H06.qmd` remains the main, submission-facing hourly H06
  result.
- H06_daily is complete complementary evidence addressing the participant-day
  daily-metric question.
- The two analyses retain different analytical units, estimands, and temporal
  weighting. H06_daily is not a replacement, replication, or equivalence
  analysis.
- All accepted H06_daily limitations remain part of the final complementary
  interpretation.

No model, estimate, interval, raw or adjusted p-value, diagnostic, sensitivity,
figure, table value, or scientific claim was recomputed by this closure.

## Remaining editorial actions

Reader-language harmonization and Nature Health website integration remain
separate display-only work. The harmonizer must first complete the bounded
source-only pass. The coordinator may then place the complementary result and
preparation pages together after the main H06 result and companion, following
the active REPORT-017 serial render order. Neither action reopens the scientific
H06 or H06_daily workflows.

## Reopening condition

Reopen the scientific closure only if a sealed endpoint or focused verifier
fails, the author changes the main/complementary hierarchy, or a later verified
discrepancy materially changes the accepted main-H06 result or a complementary
claim. Editorial harmonization and website integration alone do not reopen it.
