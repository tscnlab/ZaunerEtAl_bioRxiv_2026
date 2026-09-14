# Brown adherence BA-015 correction-checker directory-filter recovery

Correction ID: `BA-015-CORR-002`
Superseded checker execution: `BA-015-CORR-001`
Related decision: `BA-015`
Related change: `CHG-154`
Date: 2026-08-20
Status: checker defect verified and one bounded recovery authorized

## Finding

The continuing Brown task complied with `BA-015-CORR-001` by first copying the
five failed preflight files into the required
`preflight_clerical_stop/` directory. It then ran the central correction
checker once, before changing the live preflight.

The checker stopped at this assertion:

```text
identical(observed_top_level, expected_top_level)
```

The checker used:

```text
list.files(
  amendment_root,
  recursive = FALSE,
  include.dirs = FALSE
)
```

Under R 4.6.1, `include.dirs` applies only to recursive listing. The required
`preflight_clerical_stop` directory therefore remained in the returned
top-level names and made the exact file-vector assertion false.

This is a central checker implementation defect. It is not a failure of the
preservation, authority, frozen-input, model-interface, or scientific gates.
The task had not edited the live preflight and had not calculated `BA-M6`.

## Sealed stopped state

The stopped state is exact:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `preflight_clerical_stop/preflight_clerical_stop_manifest.csv` | 1,982 | `ca910103f50e64e2742abe2c51005b47e3b1cebe82f5209ac66c9ced554559f6` |
| `preflight_clerical_stop/clerical_recovery_stop_record.csv` | 741 | `15c4dbaa4c1335f68f347d39c70b1fd4eb959a130d8d8c6335b58d753236b4ad` |
| `preflight_clerical_stop/central_correction_checker_output.txt` | 101 | `9d55897346a8b85681fee1c8e674856afb490023e4d2af17554a51582f333b1e` |

R 4.6.1 independently verifies all seven non-circular stop-manifest members,
including the five original failed-preflight files. The stop record confirms:

- one checker attempt and exit status one;
- no live preflight edit;
- zero `BA-M6` calculations;
- zero model fits, live predictions, or TMB compilations;
- zero QMD changes or renders; and
- no automatic retry.

The live `00_preflight_ba_m6.R` remains exactly 20,661 bytes with SHA-256
`32fd4ea1b84b49a8b96665fe6d09eeaaaa0c3c0536a7b182bddadf75a89a65a7`.

## Corrected directory contract

The versioned checker must enumerate top-level entries with full paths,
classify them with `file.info()$isdir`, and compare only entries proven not to
be directories with the five expected live files. It must separately require
the `preflight_clerical_stop` directory and verify its sealed manifest.

Equivalent bounded logic is:

```text
top_level_entries <- list.files(
  amendment_root,
  recursive = FALSE,
  full.names = TRUE,
  all.files = FALSE
)
top_level_is_directory <- file.info(top_level_entries)$isdir
observed_top_level_files <- sort(basename(
  top_level_entries[!top_level_is_directory]
))
observed_top_level_directories <- sort(basename(
  top_level_entries[top_level_is_directory]
))
```

Fail closed on a missing or indeterminate `isdir` value, any unexpected live
file, a missing stop directory, a stop-manifest mismatch, or any forbidden
scientific output.

## Authorized recovery

The continuing Brown task may perform exactly this sequence:

1. Verify the `BA-015-CORR-002` decision, versioned checker, and non-circular
   central manifest at their returned exact identities.
2. Create a new evidence-only directory named
   `site_free_work_vs_equal_site_amendment/preflight_checker_recovery/`.
3. Run the versioned central checker exactly once. Retain its complete output,
   exit status, command, R version, package versions, and a non-circular
   recovery manifest in that directory.
4. Stop if the versioned checker does not pass. Do not patch or rerun it.
5. If it passes, change only the one mistyped hash literal in the live
   `00_preflight_ba_m6.R` from the historical token to the correct token
   authorized by `BA-015-CORR-001`.
6. Require exact reverse substitution to reproduce the live historical script
   SHA-256
   `32fd4ea1b84b49a8b96665fe6d09eeaaaa0c3c0536a7b182bddadf75a89a65a7`.
7. Parse and Air-check the corrected preflight without executing its body.
8. Execute the corrected source-only preflight exactly once under R 4.6.1
   with the established existing project `renv` library access.
9. Require every preflight gate to pass and seal the corrected preflight and
   all recovery evidence non-circularly.

This is the only versioned checker run and the only corrected source-only
preflight run authorized by this recovery. The already failed checker attempt
is retained as execution history and is not counted as the versioned run.

If the corrected preflight passes, the existing single-production-derivation
authority in `BA-015` remains active and may continue without another central
transition. Any different failure returns one sealed state with no automatic
retry.

## Unchanged boundaries

No part of this recovery authorizes:

- a `BA-M6` estimate, uncertainty measure, p-value, or FDR calculation before
  the corrected preflight passes;
- a model fit or refit, live prediction, TMB compilation, bootstrap,
  simulation, resampling, sample change, or package installation;
- an edit to any accepted Stage 2 or Stage 3 artifact, manifest, QMD, HTML,
  figure, source-data file, ledger, lockfile, or shared file;
- Quarto rendering or browser QA; or
- Stage 4 or writer notification.

The `BA-CS-G3-INTEGRATED-REVIEW` author stop and all `BA-015` scientific and
display contracts remain unchanged.
