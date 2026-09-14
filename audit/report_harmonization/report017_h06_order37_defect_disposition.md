# REPORT-017 H06 order-37 defect disposition

Date: 2026-08-15

Status: complete independent disposition for one consolidated follow-up

## Controlling stopped state

The order-37 source rewrite stopped after its one authorized source-only
verifier run. The verifier ran under R 4.6.1 after the separately authorized
environment-startup retry. It evaluated 171 checks and sealed 17 failures.
No Quarto document was rendered or executed, and no scientific artifact was
recomputed or regenerated.

Controlling identities:

- result QMD: `938f1a253bffefa99947783dc1ae4c739f92ad82fb224a4d8626d91bcebea061`;
- companion QMD: `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`;
- handoff: `5bf8dc5a5ee0a27f15edeceef1aaac7d10fd3d0bbf1895517fea8451cdea99a3`;
- stopped verifier: `310ed0ad584746d9961565d3eaa0f974feb103a8e4ff808d7c612233744027a7`;
- defect list: `77fc09318e3ac59925ccf78d82b4124c72666d8122db5c61a7b01c3e16d5cba1`;
- execution record: `8b9c3d8fd99b003e58bfdc332ab898d607db48ff228d4f8022b90beb247f9cec`;
- 93-row non-circular manifest:
  `0e23747f117c303be4ad72caa81276c6129b1e3a24ef4f20e9d566c1a3ef72d0`.

The initial sandboxed R process never entered the verifier. A read-only process
and stack inspection found the already documented `renv` transient-cache
startup loop. The coordinator authorized terminating that process and running
the unchanged verifier once with narrowly elevated access to the existing
user-owned `renv` cache. The real verifier then started and sealed in about two
seconds. This startup event is infrastructure provenance, not an analytical or
document failure.

## Complete classification

| Sealed failure(s) | Count | Disposition | Required consolidated correction |
|---|---:|---|---|
| Result chunk order; companion chunk order; result table order; result figure order; companion figure order | 5 | Test-only classification defect | The observed labels and order equal the approved vectors. `vapply()` retained names, while the expected vectors were unnamed, so `identical()` failed on attributes. Compare the un-named vectors while retaining exact order, uniqueness, counts, and first-endpoint gates. |
| Result numeric-token inventory | 1 | Confirmed reader-source preservation defect | The only set difference is removal of accepted value `0.298`. Restore one visible sentence stating that the interaction model's site-average day-type association did not meet the adjusted threshold, with three-predictor FDR-adjusted p = 0.298. No other numeric token or claim may change. |
| Companion prepared-object reference inventory | 1 | Test-only allow-list omission | No reference was removed. The only additions are `.data$\`All additive fits converged\`` and `.data$\`All interaction fits converged\`` in the already approved display-only Yes/No mapping inside `tbl-h06-prep-influence`. Require this exact two-reference addition and no other difference. |
| Result category-cell registry link target | 1 | Test-only link-parser defect | The relative target exists. The link label wraps across a source line, while the parser's final `.*` did not match newlines and therefore returned the whole Markdown link. Extract the capture across line breaks or use a structural capture. Preserve the source link and exact target. |
| Reader-facing TRUE; reader-facing FALSE | 2 | Test-only over-classification | The remaining occurrences are exact technical method arguments: one `discrete = TRUE` in the result, and one `discrete = TRUE` plus one `discrete = FALSE` in the companion. These are not raw status cells. Require those exact technical occurrences, remove them before the general raw-boolean scan, and continue to fail on every other visible TRUE/FALSE occurrence. |
| Four required result explanations | 4 | Test-only whitespace classification | Every phrase is present with approved wording but wraps across source lines. Normalize whitespace before the fixed semantic checks. |
| Three required companion explanations | 3 | Test-only whitespace classification | Every phrase is present with approved wording but wraps across source lines. Normalize whitespace before the fixed semantic checks. |

Total: 17 sealed failures, comprising 16 verifier-classification defects and
one bounded source-preservation defect.

## Scientific disposition

No new scientific discrepancy is present. The accepted sample, formulas,
models, estimates, intervals, p-values, FDR decisions, diagnostics,
sensitivities, figures, source data, and claims remain controlling. Restoring
the `0.298` sentence preserves an accepted result that the order required to
retain. It does not calculate or change a result.

The companion QMD requires no correction. The four deferred baked-label
figure repairs remain separate. Both H06 renders remain held.

