# Brown adherence BA-015 cell-prediction hash clerical correction

Correction ID: `BA-015-CORR-001`
Related decision: `BA-015`
Related change: `CHG-154`
Date: 2026-08-20
Status: verified clerical correction and one preflight recovery authorized

## Disposition

The `BA-015` controlling decision contains one mistyped SHA-256 identity for
`estimand_cell_predictions.csv`. It omits the two characters `74` after
`c174`.

Historical mistyped token:

```text
86bc7c1c043e267f888a324c174d074a1062e8c81b829416c3c8cd076d3c6d
```

Correct controlling token:

```text
86bc7c1c043e267f888a324c17474d074a1062e8c81b829416c3c8cd076d3c6d
```

This correction supersedes only that one token wherever the `BA-015`
preflight derives its expected frozen identity. The original decision,
verification, checker, manifest, and ledger identities remain byte-identical
historical authority. No scientific contract, estimand, model, sample,
response-scale value, covariance, multiplicity rule, claim gate, display
rule, render boundary, or author gate changes.

Because this is a correction to a clerical token inside the already
registered `BA-015` and `CHG-154` authority, it does not create a new Brown
scientific decision or a new change-log entry. This correction record and its
non-circular manifest are the durable central recovery authority.

## Independent identity evidence

R 4.6.1 verifies that the correct token is shared by all authoritative
scientific identity sources:

| Evidence | Bytes | SHA-256 or recorded member identity |
|---|---:|---|
| `audit/analyses/brown_adherence/stage2_boundary/estimand_cell_predictions.csv` | 74,860 | `86bc7c1c043e267f888a324c17474d074a1062e8c81b829416c3c8cd076d3c6d` |
| `audit/analyses/brown_adherence/stage2_boundary/estimand_manifest.csv` | 3,856 | member identity is the same correct token |
| `audit/analyses/brown_adherence/stage2_boundary/boundary_stage2_final_manifest.csv` | 140,282 | member identity is the same correct token |
| `scripts/report_harmonization/check_brown_ba015_site_daytype_reopening.R` | 12,529 | checker requires the same correct token |

The independent checker passed all 378 Boundary Stage 2 members before the
`BA-015` transition was issued. No scientific artifact or accepted manifest
is inconsistent.

## Failed preflight evidence

The first source-only preflight stopped correctly before any `BA-M6`
calculation. Preserve these exact execution-time files before changing or
rerunning the preflight:

| File in `site_free_work_vs_equal_site_amendment/` | Bytes | SHA-256 |
|---|---:|---|
| `00_preflight_ba_m6.R` | 20,661 | `32fd4ea1b84b49a8b96665fe6d09eeaaaa0c3c0536a7b182bddadf75a89a65a7` |
| `authority_verification.csv` | 1,984 | `06a1dac6fdb0218cb30aec06489ef79e19b97cd2bef5a0e2018ba94f83fdf307` |
| `central_authority_manifest_verification.csv` | 2,360 | `36b9e3552ea0c53d9e7255a83994ed06c5abcb6d7ede058b3448e56f0ada7d7d` |
| `ledger_verification.csv` | 1,033 | `d2057539f331819630ad0a640134ba47f7baae01334fb7cb1a3731ca53be7aaa` |
| `frozen_input_verification.csv` | 3,607 | `42280a99368415d4604cafe251699060bd573e90c933774383fb1334d087323b` |

The four evidence tables contain:

- six of six central authority identities passed;
- seven of seven central authority manifest rows passed;
- 30 of 30 Brown ledger identities passed; and
- 11 of 12 frozen input identities passed, with the sole failure being the
  mistyped expected hash against the correct observed hash.

No derivation script, contrast, p-value, confidence interval, multiplicity
output, display artifact, QMD change, or render was produced.

## Authorized recovery

The continuing Brown task may perform exactly one source-only preflight
recovery:

1. Before editing, copy the five failed-attempt files listed above byte for
   byte into
   `site_free_work_vs_equal_site_amendment/preflight_clerical_stop/` and add a
   record plus one non-circular manifest that verifies all five historical
   identities.
2. Run the central correction checker once and retain its output in the same
   stop-evidence directory.
3. In the live `00_preflight_ba_m6.R`, replace only the historical mistyped
   hash literal with the correct controlling token. No other code or expected
   identity may change.
4. Require an exact reverse substitution to reproduce the historical script
   SHA-256 `32fd4ea1b84b49a8b96665fe6d09eeaaaa0c3c0536a7b182bddadf75a89a65a7`.
5. Parse and Air-check the corrected script without executing its body.
6. Execute that corrected source-only preflight exactly once under R 4.6.1
   with the already established existing project `renv` library access.
7. Require every preflight check to pass and seal the corrected script,
   execution record, all preflight tables, the preserved failed evidence, and
   exact before-and-after identities.

This recovery does not authorize a preliminary contrast calculation. If the
corrected preflight passes, the existing single-production-derivation
authority in `BA-015` remains active and may continue without another central
transition. If any other gate fails, stop and return one sealed state. Do not
apply another correction or retry automatically.

## Preserved boundaries

The following remain prohibited during the recovery:

- any `BA-M6` estimate, standard error, interval, p-value, or FDR calculation;
- model fitting, refitting, live prediction, TMB compilation, resampling,
  bootstrap, simulation, or sample change;
- any edit to an existing Stage 2 or Stage 3 scientific artifact or manifest;
- any QMD, HTML, figure, source-data, package, lockfile, ledger, or shared-file
  edit;
- Quarto rendering, browser QA, Stage 4, or writer notification; and
- deletion or rewriting of the first failed preflight evidence.

The mandatory final author stop remains `BA-CS-G3-INTEGRATED-REVIEW`, with
the exact post-result wording required by `BA-015`.
