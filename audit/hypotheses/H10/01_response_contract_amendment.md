# H10 Stage 1 response-contract amendment

Date: 2026-08-07  
Gate: amended `H10-G3`  
Status: **approved before the first H10 fit**

## Finding

The H10 Stage 1 report reconstructed the pre-sleep TBT10 response model from
the superseded H01 prefit package. The final shared H01 package had already
selected a different common response model before H10 Stage 1 was written.

| Item | H10 Stage 1 table | Authoritative shared package |
|---|---|---|
| Metric | Time below 10 lx melEDI before sleep (`duration_below_10_pre_sleep`) | Same outcome and rows |
| Engine | `glmmTMB` | `lmer` |
| Family and link | Tweedie, log link | Gaussian, identity link |
| Response construction | Untransformed hours | Untransformed hours |
| Practical effect | Ratio and percent change | Difference in hours/minutes |

The other 16 metric response specifications are unchanged.

## Controlling evidence

- `scripts/hypotheses/H01/h01_contract.R`, SHA-256
  `4b63d96e5758bb95f9a550423626aa045f86ce1c565ba706885b5f5c4d25c8d0`,
  declares Gaussian identity for this metric.
- `artifacts/09_tables/H01/response_family_candidates/H01_response_family_candidate_selection.csv`,
  SHA-256
  `37e38ed7715c3c5e364557a79795c321548ee8f14efcca91204adbf26a1bf0e0`,
  records `GOOD_COMMON_DIAGNOSTICS` and states that the highest-ranked eligible
  alternative was selected.
- `audit/handoffs/H01_worker_handoff.md` records the final decision to change
  only this response family and close the H01 response-family gate while
  retaining disclosed warnings for the other reviewed families.

These are shared specifications, not H01 fitted estimates or significance
decisions. H10 would fit its own models and diagnostics.

## Recommended amended decision

Approve amended `H10-G3`: use the final shared 17-metric response package,
changing only pre-sleep TBT10 from Tweedie/log to Gaussian/identity relative
to the rendered H10 Stage 1 table. Keep the outcome values and exact candidate
rows unchanged. Report its age and Female-minus-Male effects as differences
in hours and minutes with 95% confidence intervals. Retain all other approved
H10 gates and response specifications unchanged.

## Consequence

The author approved this amendment in the H10 task on 2026-08-07 by directing
the worker to update the contract and use Gaussian. No H10 inferential model
had been fitted. Stage 2 may use the amended package. This approval does not
authorize a later response-family change, bootstrap production run, Stage 3,
Stage 4, or a shared-file edit.
