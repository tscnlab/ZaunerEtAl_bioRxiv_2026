# H03–H11 scientific-closure status reconciliation

Decision ID: `AUDIT-004`

Date: 2026-08-13

Status: verified

## Scope

This decision reconciles the central stage and comparison status for H03,
H04, H07, H08, H09, H10, and H11. Their central rows still contained the
initial Stage 1 placeholders even though the hypothesis-specific scientific
workflows had been completed and handed back with accepted reader reports and
preparation-and-provenance companions.

H05, hourly H06, and complementary H06_daily were already current in the
central ledgers and are not scientifically changed by this reconciliation.

## Decision

For each hypothesis in scope:

1. Stages 1 through 4 are recorded as complete and verified from the accepted
   hypothesis handoff and sealed reader/preparation sources.
2. The Stage 1, Stage 2, and Stage 3 author gates are recorded as approved.
3. A separate production-computation gate is recorded as not required. No
   accepted final inference in these workflows depended on an outstanding
   production bootstrap or simulation.
4. The scientific workflow and gate are recorded as closed.
5. Submitted-versus-audited implementation, result, claim, preregistration,
   and prepared-data-sensitivity comparisons are recorded as complete. A
   sensitivity that was scientifically non-estimable, such as H09's
   registered longest-period comparison on the gap-timing-unaware dataset, is
   complete when its non-estimability and consequence are explicitly
   documented.
6. Verification is labelled `producer_pass`, not `independent_pass`. This
   central reconciliation checks accepted handoff states, source identities,
   and ledger structure without refitting models or independently reproducing
   every scientific result.

REPORT-017 harmonization, targeted website rendering, visual QA, navigation,
and principal/supplemental output selection remain display-integration work.
They do not reopen a scientific gate unless they expose a verified scientific
discrepancy or alter an accepted result or claim.

## Authoritative evidence

| Hypothesis | Accepted handoff SHA-256 | Reader QMD SHA-256 | Preparation QMD SHA-256 |
|---|---|---|---|
| H03 | `dae48601f0ba90ee2932556b312ac2e0e94db0bc695ea242c01328c9ea6a0fec` | `84625736235533fc80da6f4b24b6c9904c7e59db0cb9545da9ceebc1c2cfd093` | `b7671d848544228088df9bbe179a172fd7402e7fa18c3029be9b499d0ef2f760` |
| H04 | `f9ae486c9857e2081098c74670ef325042500d5c21af477194cd23c9d1773834` | `3f56afe495a343218a8ae1803be4d56bd5768447a2e6bee4bd695f1ea1269837` | `616015f7dca943eb26a06dd9a03a0c7a646991710fa5785459a5ac3847207b77` |
| H07 | `95351007249f187a5c6650e951a1ad1078923ca35c628d730334866cf3593a3e` | `c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226` | `a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b` |
| H08 | `8a7be6d71075cd4e4bb3884c24ee2465fbb333bc3dc042192b03dd3897005642` | `1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1` | `3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d` |
| H09 | `f6a596f9c2ac8ad295e13d2283026c5068da57af36914cccb662620da861fcf4` | `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6` | `7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46` |
| H10 | `70f4b211d329f893ce5f75ac3e494e634546e160f96761509259f7ba6518087f` | `3c8d6891854a298e4fad69d1d7499c4d45a7d7c522f50e920b6b6aa1e4abac3f` | `c46d6ae965daba94750220e6eeaf95aa01b5cff4bc929117848f72090b7583f1` |
| H11 | `5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289` | `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867` | `3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816` |

The H11 registered-hourly wording is additionally governed by CHG-129. It is
superseded preregistration provenance, not an unfinished sensitivity. The H07,
H08, H09, and H10 METRIC-011 maintenance work is bounded follow-up and does
not reopen their accepted scientific workflows.

## Result effect

None. This decision changes only central workflow metadata. It does not alter
data, samples, metrics, models, estimates, intervals, p-values, multiplicity,
diagnostics, sensitivities, figures, tables, or scientific claims.

## Reopening condition

Reopen a hypothesis only if a cited identity or focused verifier fails, the
author changes an accepted analysis decision, a verified discrepancy changes
an accepted result or claim, or display-integration work changes scientific
content rather than presentation.
