# REPORT-014/017 order 37a: H06 consolidated source and verifier correction

Date: 2026-08-15

Owner: main hourly H06 task `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: authorized source-only follow-up; every H06 render remains held

## Purpose

Resolve all 17 order-37 stopped assertions in one coherent follow-up. The
complete independent classification is
`audit/report_harmonization/report017_h06_order37_defect_disposition.md`.
Sixteen failures are verifier classifications. One source repair restores the
already accepted value `0.298` that order 37 required to preserve.

Do not enter a piecemeal loop. Assemble the complete source and verifier
correction, then run the new follow-up source-only suite once. If startup or
any assertion fails, seal that complete state and stop without patching or
rerunning.

## Exact preflight pins

- `notebooks/hypotheses/H06.qmd`:
  `938f1a253bffefa99947783dc1ae4c739f92ad82fb224a4d8626d91bcebea061`,
  60,541 bytes.
- `audit/hypotheses/H06/H06_analysis_preparation.qmd`:
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`,
  59,613 bytes.
- `audit/handoffs/H06_worker_handoff.md`:
  `5bf8dc5a5ee0a27f15edeceef1aaac7d10fd3d0bbf1895517fea8451cdea99a3`,
  10,408 bytes.
- stopped order-37 verifier:
  `310ed0ad584746d9961565d3eaa0f974feb103a8e4ff808d7c612233744027a7`.
- stopped defect list:
  `77fc09318e3ac59925ccf78d82b4124c72666d8122db5c61a7b01c3e16d5cba1`.
- stopped execution record:
  `8b9c3d8fd99b003e58bfdc332ab898d607db48ff228d4f8022b90beb247f9cec`.
- stopped 93-row manifest:
  `0e23747f117c303be4ad72caa81276c6129b1e3a24ef4f20e9d566c1a3ef72d0`.
- order-37 exact source diff:
  `a4f676fe588fdd72f76081244129ba032908ca7d37683776fa2411f8ae1c485a`.
- order-37 protected inventory:
  `20fc307e6513da8fea7296e0e97fe968d39ac2d76b0618101e167eba2ada9d23`.
- order-37 editorial allow-list:
  `1d87a8eabe7b8e7e2e90decc8897438310f5ed6224a200ac39489ccc1abbe266`.

Recheck every pin before editing. Stop on drift. The coordination-matrix hash
is dispatch evidence only and is not an owner execution pin.

## Authorized mutable paths

Edit or create only:

1. `notebooks/hypotheses/H06.qmd`;
2. `audit/handoffs/H06_worker_handoff.md`;
3. new
   `tests/hypotheses/H06/test_h06_report017_source_harmonization_37a.R`;
4. new bounded evidence under
   `audit/hypotheses/H06/report017_order37a/**`.

Keep the companion QMD byte-identical. Keep the stopped order-37 verifier and
every file under `audit/hypotheses/H06/report017_order37/` byte-identical as
historical evidence. Do not edit an existing H06 test or manifest.

## Single reader-source correction

In the visible `Site dependence` section of
`notebooks/hypotheses/H06.qmd`, restore one sentence with this exact scientific
content:

> The interaction model's site-average day-type association did not meet the
> adjusted threshold (three-predictor FDR-adjusted p = 0.298).

Place it after the visible site-average work/free estimate and before the
working-variance result. Preserve all surrounding prose, every other numeric
token, every R chunk, endpoint, inline expression, formula, object reference,
link, caption, and alt text. This is restoration of an accepted result, not a
new calculation or claim.

## New follow-up verifier

Create the new order-37a verifier from the stopped verifier logic, with only
the following consolidated corrections:

1. Write all new execution, defect, diff, reverse, inventory, and manifest
   evidence under `audit/hypotheses/H06/report017_order37a/`. Never overwrite
   the order-37 stopped evidence.
2. Preserve the exact count, uniqueness, order, and first-endpoint checks, but
   remove incidental names before comparing the five observed label vectors
   with their approved unnamed vectors.
3. Require exact pre/post equality for the result numeric-token inventory. The
   restored `0.298` must make the inventory exact, with no allow-list exception.
4. For companion prepared-object references, require no removal and exactly
   these two additions, with exact set equality and no third difference:
   `.data$\`All additive fits converged\`` and
   `.data$\`All interaction fits converged\``. Also require the existing
   `tbl-h06-prep-influence` Yes/No mapping row in the sealed order-37
   editorial allow-list.
5. Repair Markdown target extraction structurally so a link label may wrap
   across source lines. Continue to require the exact category-cell target,
   every other relative target, and all prohibited-link checks.
6. Treat only the exact technical method strings as permitted visible boolean
   tokens: result `discrete = TRUE` exactly once; companion
   `discrete = TRUE` exactly once and `discrete = FALSE` exactly once. Remove
   those exact occurrences before the general reader scan, which must still
   fail on any other visible TRUE or FALSE.
7. Collapse runs of source whitespace to one space for the required-language
   checks only. Preserve every required phrase and every other vocabulary,
   site, link, and forbidden-term gate.
8. Retain every other order-37 verifier check. Do not weaken protected-file,
   historical-manifest mismatch-set, scientific-call, parse, formula,
   assignment, artifact, source-data, stale-HTML, profile, H06 daily, CSS,
   figure, package, whitespace, or scoped-diff checks.
9. Pin the complete stopped order-37 verifier and evidence as historical
   context, plus the final result, unchanged companion, final handoff, new
   verifier, and all protected inputs in a new non-circular order-37a manifest.

The new verifier must itself record the earlier sandboxed startup loop, the
authorized environment-startup retry, the order-37 17-defect stop, the exact
order-37a command, R and package versions, startup and verifier timings, exit
status, and pre/post identities.

## Handoff update

Refresh the H06 handoff only after assembling the complete follow-up source.
Record the final result identity, unchanged companion identity, the restored
`0.298` sentence, the historical order-37 stop, and the order-37a source-only
outcome. Preserve the scientific hierarchy and every existing scientific
value. Continue to state that the HTML files are stale and that figure repair
and rendering remain held.

## One authorized execution

Before execution, record fresh hashes and byte counts for every mutable source
and all protected paths. Then run exactly once under R 4.6.1 with the normal
project profile and narrowly elevated read/write access only to the existing
user-owned `renv` cache:

```sh
Rscript tests/hypotheses/H06/test_h06_report017_source_harmonization_37a.R
```

No preliminary project test is permitted. This is a source-only structural
verifier. It must not execute either QMD or calculate a scientific result.
If project startup loops or any check fails, stop once, seal the complete
state, and return the combined defect list without another retry.

## Prohibitions

Do not edit or execute the companion QMD. Do not edit the stopped order-37
test or evidence. Do not run Quarto, render a page, fit or deserialize a model,
predict, simulate, bootstrap, resample, recalculate a p-value or FDR result,
rerun a sensitivity or model check, regenerate a figure, rewrite source data,
or modify a scientific artifact. Do not edit any existing H06 test or
manifest, H06 daily file, profile, hook, build output, central record,
harmonizer-wide file, manuscript file, package, or lockfile. Do not commit or
push.

Stop after the single source-only seal for independent harmonizer acceptance.
The four baked-label figure repairs and both H06 renders remain separate and
held.
