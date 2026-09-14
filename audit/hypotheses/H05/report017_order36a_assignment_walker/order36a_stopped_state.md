# H05 REPORT-014/017 order-36a stopped state

Date: 2026-08-20

Status: **STOPPED**. The prospective PASS sentence in the H05 handoff remains
provisional and is not accepted.

## Authorized continuation completed before the stop

- All 26 dispatch identities and 106 protected H05 artifact or script
  identities matched before any project write.
- The durable seven-file snapshot was created and verified 7 of 7 before the
  verifier edit.
- Only `assignment_records()` in the new order-36 verifier changed. The
  repaired verifier is SHA-256
  `a39c924b5ed35eb7ed20093574b766d23ab5e7abd001e32b6792f452bde080da`,
  60,058 bytes.
- The verifier change has one diff hunk. Reverse application reproduced the
  stopped verifier identity
  `67550b6e1cb810ae4850a8f14157d000d619b2bd13e830e007233c8f2d02f43e`,
  59,836 bytes.
- R 4.6.1 parsed the repaired verifier into 250 expressions. The scalar
  operator check returned `<-` for an ordinary assignment and `NA` for the
  namespaced non-assignment `tibble::tibble()`.

Two read-only shell inspections initially used zsh-reserved variable names
(`path` and `status`). Each stopped before its intended metadata assertion and
was repeated with a neutral variable name. Neither changed a reader source,
handoff, verifier logic, scientific artifact, or shared file. They were not
project tests or verifier invocations.

## Single complete verifier invocation

Exactly one complete order-36 verifier invocation ran:

```sh
H05_ORDER36_PRE_DIR=/private/tmp/h05-report017-order36.pdKad8 Rscript --vanilla tests/hypotheses/H05/test_h05_report017_source_harmonization.R
```

The command ran under R 4.6.1 and exited 1. Tool wall time was 2.035 seconds;
the verifier recorded 1.606 seconds before sealing its evidence. It evaluated
54 gates: 48 passed and six failed. It still completed the authorized
order-36 evidence write and produced a unique, non-circular, live-exact
135-row source manifest:

- `audit/hypotheses/H05/report017_order36/H05_report017_order36_source_manifest.csv`
- SHA-256
  `70ed24b61d942b4e5d8e97539fb40ce5cf93fcb21b3d06323cb53c435b619b60`
- 25,002 bytes

## Combined verifier defect list

Five endpoint gates failed even though each observed endpoint list printed in
the exact expected order and with the exact expected members:

1. `result_table_endpoints`
2. `result_figure_endpoints`
3. `result_first_endpoints`
4. `companion_table_endpoints`
5. `companion_figure_endpoints`

The shared cause is verifier-only vector metadata. `chunk_labels()` returns a
named vector because the chunk list is named. Subsetting preserves those
names, while the expected endpoint vectors are unnamed. `identical()` therefore
returns false despite identical displayed values and order. This is not an
endpoint discrepancy in either QMD.

The sixth gate, `unfit_scope_and_suppression`, failed because its first phrase
is checked against whitespace-compacted prose while its second phrase is
checked against un-compacted prose. The source contains the exact required
sentence, but a source line break occurs between `confidence` and `intervals`.
The broader `scientific_boundaries_preserved` gate passed. This is not an H05
scientific or reader-wording discrepancy.

The exact generated six-row defect record is:

- `audit/hypotheses/H05/report017_order36/defect_list.csv`
- SHA-256
  `29c44fc01304f3a92fb6cb32f8e578f3721b45a1106ba15bf79a97af36ab4952`
- 2,303 bytes

## Preservation and prohibition record

The result QMD, companion QMD, and H05 handoff remain byte-identical to the
accepted stopped state. No existing H05 test or manifest, build output,
profile, shared file, catalog, central record, scientific artifact, package,
or lockfile changed. No Quarto command, QMD execution, render, model fit or
refit, prediction, simulation, bootstrap, resampling, FDR calculation,
diagnostic rerun, leave-one-site-out rerun, artifact regeneration, commit, or
push occurred.

Per order 36a, no verifier patch or retry followed this new failure. H05 stays
on render hold pending a separately authorized continuation.
