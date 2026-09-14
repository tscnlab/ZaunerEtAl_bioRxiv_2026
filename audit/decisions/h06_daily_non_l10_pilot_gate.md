# H06_daily remaining non-L10 pilot gate

Decision ID: `H06-D-008`  
Change ID: `CHG-118`  
Date: 2026-08-12  
Status: independently verified; awaiting author decision

## Decision requested

Accept the bounded `H06-D-G2P-NONL10` pilot as complete evidence, keep the
unchanged 13-slot production grid stopped, and authorize only a separate
bounded repair pilot for the four timing outcomes whose current models fail
the prespecified diagnostic contract:

- midpoint of the brightest 10 hours;
- midpoint of the darkest 10 hours;
- first timing above 250 lx melEDI; and
- last timing above 250 lx melEDI.

This is the recommended option. It does not authorize full production,
multiplicity updates, deletion production, Stage 3, Stage 4, or any change to
the main hourly H06 analysis.

The alternative is to release production for the eight non-timing outcomes
and mean timing above 250 lx while holding the four failed timing outcomes.
That option is not recommended because it would split the prespecified
15-slot families before the timing estimands have a defensible model route.

## Independent verification

Fresh R 4.6.1 verification reproduced the supplied gate and passed the focused
test. The coordinator additionally reverified all three manifests and their
file identities and audited the scientific summaries directly from the sealed
CSV and RDS outputs:

- all 26 controlling input pins pass;
- the 468 candidate frames comprise 13 non-L10 metrics, three predictors, and
  12 authorized scenario roles;
- current-source and historical wide/long inputs have identical missingness
  and estimability, with a largest scaled decimal-representation difference of
  `2.22e-16`, below the `1e-12` tolerance;
- all three historical representative analytical objects meet the exact reuse
  contract;
- all 99 attempted components across the 15 primary near-eye timing cells fit;
- three mean-timing-above-250 cells are acceptable and the other 12 timing
  cells are not acceptable under the existing diagnostic contract;
- nine actual-date AR counterparts were triggered and fitted, none met the
  post-AR site residual threshold, and one was singular;
- all 50 serial deletion refits completed with no failure, warning, or
  direction reversal; four usable classes stayed below one standard error,
  while the already failed strict-clock representative shifted by 1.10
  standard errors;
- 535 protected pre-existing H06_daily files remain byte-identical; and
- no BH adjustment, full grid, report stage, or shared/main-H06 result was run
  or changed.

The projected base grid is 113.064 seconds. The projected complete deletion
battery is 66,664 refits and 1,829.692 seconds, before AR diagnostics and
rendering. Runtime is therefore bounded; model adequacy, not compute time, is
the reason for the stop.

## Accepted gate identities

| Item | SHA-256 |
|---|---|
| Gate HTML | `5376bdbc4de565a514386190f8ccf0c224b685e90bb50fe6a42e998cd8351c15` |
| Transition | `3d45732606480de6db14fe81cd66ea501928718a63300a7238f6f2b748318e97` |
| Report manifest (18 identities) | `08672fa8911c62c9f399b8c3853f204dd4d477d2f0bff0b3a5fd72029189c716` |
| Output manifest (24 identities) | `cdb39a93ef7fc48ab9bf5bc3919b7b777de36a830a5326ce1e803fa0a8f0c10e` |
| Focused test | `e279817cc0eeed6847358849370d16fc2d61f6335004ae38a843aed5a31a172c` |

## Frozen boundary while awaiting the author

No full remaining-grid production, BH update, deletion battery, Stage 2 merge,
Stage 3 or Stage 4 report, shared-file edit, L10 or MDER amendment, main-H06
change, or final publication integration is authorized. The previously
accepted L10, MDER, pre-sleep, temporal, and main-H06 records remain frozen.

## Reopening condition

Reopen if a controlling identity or verifier fails, a timing estimand or
candidate repair changes, a frozen result changes, or the author selects one
of the two production dispositions above.
