# Author decision on the Phase 2 harmonization package

Date: 2026-08-12  
Status: **items 1–3 and 5 approved; item 4 authorized for a first adjustment run and retained for final visual approval**

## Approved decisions

The author approved the shared structural templates and documented exceptions, the cross-link/navigation plan, and the proposed preregistration-deviation document structure and inclusion tiers.

The shared vocabulary is approved with these amendments:

- `GAM` may remain after a plain first-use explanation, for example “nonlinear GAM analysis.”
- `back-transformed` may remain after its meaning and resulting unit are explained.
- `AR(1)` may remain after autocorrelation and the AR(1) structure are explained.
- `95% CI` may be used after first defining a 95% confidence interval.
- `FDR` may be used in tight spaces and thereafter; use `FDR`, not the abbreviation `BH`, in reader-facing prose and displays. The full Benjamini–Hochberg method name may be retained where reproducibility requires it.
- `symlog`, `Shapley allocation`, and `derivative` may remain after their respective first-use explanations.
- Every reader-facing site name must carry its ISO alpha-2 country code, for example `Tübingen (DE)`. This applies to prose, tables, figures, legends, captions, and alt text.

The exact accepted wording and technical-term boundaries are recorded in `vocabulary_proposal.csv`.

## Preliminary output approval

The main and supplemental output proposal is approved for one display-only adjustment run. This authorizes owners to apply the approved small styling changes, native-`gt` conversions and table structure, site labels, captions, alt text, and display-only H05/H10/H11 consolidations using accepted stored inputs.

This is not final acceptance of the principal-output shortlist or adjusted appearance. After the first focused renders, the harmonization task must present the proposed main and supplemental figures/tables to the author for visual review. No output is finally accepted merely because it renders or passes structural tests.

## Scientific and execution boundary

The approval does not authorize any data change, model fit or refit, estimate or interval recalculation, p-value or FDR recalculation, prediction, simulation, bootstrap, Shapley rerun, shared-preparation rebuild, or full-project render. If an editorial or display change exposes a possible scientific discrepancy, that document stops and returns to its scientific owner.

H06 hourly remains the main H06 result. H06_daily remains deferred until accepted Stage 3/4 reader sources exist.

## Implementation consequence

The harmonization worker may now:

1. update the author-facing package to reflect this decision;
2. create the deviation document only after central deviation mappings and statuses are authoritative and reconciled;
3. coordinate with the central task, verify current owners and safe execution points, and issue one scoped instruction per owner;
4. review targeted first-adjustment renders and return the principal outputs for final author approval.

No permission is granted to edit owner-controlled reports directly.
