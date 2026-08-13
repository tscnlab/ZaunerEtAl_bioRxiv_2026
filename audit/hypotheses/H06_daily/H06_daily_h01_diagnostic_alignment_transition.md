# H06_daily H01-aligned diagnostic transition

- Date: 2026-08-12
- Controlling amendment: **H06-D-014 / CHG-127**
- Author stop gate: **H06-D-G2A**
- Status: **no-refit amendment complete; stopped for explicit author review**
- Scientific computation in this amendment: **none**

## Completed scope

This bounded amendment reapplies the H01 three-class diagnostic architecture
to frozen H06_daily evidence. It does not fit, refit, predict, simulate,
resample, update a p-value or FDR value, run a deletion analysis, or overwrite
the historical H06-D-G2 report.

Residual distribution was judged by direct visual inspection rather than by
automatic numerical thresholds. The complete review comprises 468 non-L10
production cells and the three stored shifted-log L10 pilot cells. Gaussian
and participant-cluster HC3 cells were reviewed with residual-versus-fitted,
Q-Q, and scale-location displays. Tweedie cells were reviewed with Pearson
residual-versus-fitted, observed zero-mass, and observed-versus-fitted support
displays; normal Pearson residuals were not required.

The required pre-visual implementation replay was reproduced exactly:

- all 468 non-L10 cells: 311 `PASS`, 157 `WARN_REVIEW`, and 0
  `FAIL_MAJOR_GATE`;
- primary near-eye/all-available cells: 26 `PASS`, 13 `WARN_REVIEW`, and 0
  `FAIL_MAJOR_GATE`.

These are cross-check counts only. The final classes use the complete manual
review and the hard-gate audit.

## Final post-visual disposition

Every one of the 471 reviewed residual displays has the manual verdict
`REVIEW_LIMITATION`; none is `FAIL_GROSS`. Numerical residual summaries were
used only for navigation and description and never set a visual verdict.

For the 468 non-L10 production cells, the final H01-aligned result is:

- 0 `PASS`;
- 378 `WARN_REVIEW` (acceptable with explicit limitations); and
- 90 `FAIL_MAJOR_GATE` (not acceptable).

AR, participant/site deletion, exact-period, and response-family evidence is
retained row-for-row as mandatory, nonblocking sidecars. These sidecars do not
set the overall class unless they expose a genuine construct or observed-
support failure.

## Hard clock-unit construct failure

The 90 failures are not residual or AR failures. They are exactly the five
gap-timing-unaware clock outcomes—M10 midpoint, L10 midpoint, mean timing above
250 lx melEDI, first timing above 250 lx melEDI, and last timing above 250 lx
melEDI—across two placements, three sample roles, and three predictors.

The pinned gap source stores these five metrics in clock hours. The H06_daily
adapter treated those values as clock minutes and applied a second division by
60. R 4.6.1 verification shows that every affected stored response equals its
gap-source value divided by 60. This is a hard unit/construct failure.

Consequences:

- exactly 90 stored gap timing cells are not interpretable;
- all six gap-timing-unaware BH families (three predictors by association and
  site heterogeneity) are blocked because their vectors include invalid raw
  timing tests;
- their frozen raw p-values, q-values, ranks, and decisions remain preserved
  for provenance but cannot support a claim;
- the other 378 non-L10 cells are unaffected: all 234 primary cells and the
  144 non-timing gap cells;
- primary, chest, paired/common, and all-available non-gap branches are not
  affected by this clock-unit defect.

The exact evidence and prospective bounded repair contract are recorded in
`audit/handoffs/H06_daily_shared_change_request.md`. No repair is authorized
or performed at this gate.

## Multiplicity and claim eligibility

No inferential quantity changed. For the primary dataset, 28 association and
10 site-heterogeneity tests are FDR-supported and have no hard H01 gate; 32 of
these become diagnostically claim-eligible under the H01 architecture because
AR and other sensitivity sidecars no longer act as automatic failures. Every
claim must retain its row-specific limitation, and timing site interactions
remain sensitivity-dependent.

No gap-timing-unaware FDR claim is eligible while the six families are
construct-invalid. The L10 named-NA slot remains unpopulated. The frozen MDER
models and raw tests are unchanged; its gap-family BH derivatives are not
interpretable until the gap families are repaired.

## Shifted-log L10 pilot

The three stored shifted-log L10 pilot fits pass the base numerical hard gates
and are reclassified as `WARN_REVIEW`. Their AR failures remain nonblocking
sidecars. This diagnostic reassessment does not accept a pilot p-value,
populate L10 slot 3, authorize full L10 production, or supersede the accepted
two-part non-estimability record.

## Preservation and mandatory stop

The final protected-identity audit covers the 987-entry H06-D-G2 output
manifest and 24 direct H06-D-014 inputs: 1,011 identities in total. All are
unchanged. The unrelated central CHG-128/CHG-129 change-log updates are not
scientific H06 inputs and were not consumed.

The task is stopped at **H06-D-G2A**. Author/coordinator approval is required
before any corrected gap frame rebuild, refit, or six-family FDR update. A
prospective minimal repair would convert the five gap clock-hour outcomes to
the registered scale exactly once, rebuild only the 90 affected task-owned
cells and dependent six BH families, repeat the bounded hard-gate/visual
review, and preserve the 378 unaffected cells byte-for-byte.

Stage 3 and Stage 4 remain unauthorized. Main H06 and all shared preparation,
central-ledger, manuscript, website, commit, and push operations remain out of
scope.
