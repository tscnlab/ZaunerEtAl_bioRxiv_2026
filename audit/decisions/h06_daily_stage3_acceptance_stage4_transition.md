# H06 daily Stage 3 acceptance and Stage 4 transition

Decision ID: `H06-D-016`
Change ID: `CHG-135`
Date: 2026-08-13
Status: author approved; complementary Stage 3 accepted; Stage 4 authorized

## Author decision

The author accepted the revised standalone H06_daily Stage 3 report and
instructed the task to continue. The accepted report remains complementary
participant-day evidence. The completed hourly H06 analysis remains the main
H06 result.

The accepted Stage 3 endpoint is:

| Artifact | SHA-256 |
|---|---|
| `notebooks/hypotheses/H06_daily.qmd` | `0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc` |
| `notebooks/hypotheses/H06_daily.html` | `5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3` |
| `audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md` | `733dd1dd4c57bfdb6df7bf10e69e635455c451373c8dd0f6e3060c12b6e3884e` |
| `audit/hypotheses/H06_daily/H06_daily_stage3_acceptance_stage4_transition.md` | `80d52eea0d175c55098f5aaa716f0d37f5ba4ff532aca5c35fd94a4912549c67` |
| `tests/hypotheses/H06_daily/test_h06_daily_stage3_reader_report.R` | `16e3d02bbfe443928708a8a6e2c793a04c47281afaa8993116e1c27d0bdaa8d2` |

The report retains the distinct participant-day estimand, the selected hourly
H06 comparison, the fixed FDR families, the non-estimable L10 slots, the
accepted MDER result, and every residual, AR, response-family, influence, and
participant-cluster HC3 interaction qualification. No scientific result or
main-H06 conclusion changes.

## Stage 4 authorization

This acceptance closes `H06-D-G3` and authorizes only the separate bounded
preparation and provenance companion at
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`. The companion
may verify and describe stored inputs, samples, scripts, model routes,
diagnostics, sensitivities, and outputs. It must not fit or refit a model,
regenerate predictions, rerun deletion analyses, recompute raw or adjusted
p-values, or alter the accepted Stage 3 report or main H06.

The task must stop at `H06-D-G4` for explicit author review. Shared website
integration, reader harmonization, manuscript changes, commit, and push remain
separate actions.

## Reopening condition

Reopen this transition only if a sealed Stage 3 identity or verifier fails, an
accepted estimate, interval, FDR decision, diagnostic qualification, or claim
changes, or the complementary analysis materially changes the accepted hourly
H06 conclusion.
