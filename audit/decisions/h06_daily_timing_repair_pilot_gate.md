# H06_daily timing-repair pilot author gate

Decision ID: `H06-D-010`  
Change ID: `CHG-120`  
Date: 2026-08-12  
Status: independently verified; awaiting author decision

## Decision requested

Accept the bounded `H06-D-G2P-TIMING-REPAIR` pilot and its constrained
recommendation:

1. permit participant-cluster HC3 covariance as the candidate production
   route for the overall associations of the four held timing outcomes;
2. carry the first-timing work/free Student-t shift and L10-midpoint activity
   no-nugget-AR shift as substantial limitations, and retain three
   nonconverged additive AR checks as unresolved rather than stable;
3. retain the prespecified robust predictor-by-site tests and their named
   multiplicity slots if production is later authorized, but describe timing
   predictor-by-site interactions as sensitivity-dependent and make no
   unqualified site-interaction or site-specific claim where a diagnostic
   sensitivity reverses a coefficient or does not converge; and
4. keep every pilot association and p-value nonconfirmatory until a separate
   author decision explicitly authorizes, completes, diagnoses, and adjusts
   the remaining non-L10 production grid.

This gate does not itself authorize production, Benjamini-Hochberg updates,
deletion batches, additional placements or samples, Stage 3, Stage 4, shared
changes, or any change to the selected main hourly H06 result.

## Independent verification

Fresh R 4.6.1 verification passed the focused task test and independently
audited the sealed scientific tables and manifests:

- all 34 controlling input pins pass;
- all 12 authorized primary near-eye participant-day frames retain their exact
  object hashes, samples, site counts, clock encodings, and contrasts;
- all 36 reduced, additive, and interaction candidate mean models are
  full-rank and numerically usable;
- all 36 unmodified participant-cluster HC3 covariance matrices are finite,
  symmetric, and positive semidefinite without `fix = TRUE` or a covariance
  warning;
- maximum observation leverage is 0.347 and the largest participant cluster
  contributes at most 3.94% of total fitted-model leverage;
- exactly 24 raw robust Wald tests are sealed as
  `PILOT_RAW_ONLY_NO_BH_UPDATE`, and all adjusted-p fields are missing;
- all 36 Student-t sensitivity fits converge; 11 of 12 additive association
  comparisons are stable and first timing above 250 lx melEDI for work/free
  day shifts by 1.23 HC3 standard errors;
- 26 of 36 no-nugget AR fits converge. Nonconvergence affects two reduced,
  three additive, and five interaction structures. Among additive
  comparisons, eight are stable, L10-midpoint activity shifts by 1.26 HC3
  standard errors, and three are unresolved because their AR fit does not
  converge;
- timing predictor-by-site sensitivity is weak: only two of 12 Student-t
  interaction comparisons are stable, while ten are unstable; among AR
  interaction comparisons, two are stable, five unstable, and five unresolved
  because of nonconvergence;
- no no-nugget AR structure meets the descriptive pooled-and-every-site
  residual-lag rule. This remains a disclosed temporal limitation, but it is
  not an independence requirement for the candidate cluster-robust covariance,
  which allows arbitrary dependence among a participant's retained days;
- all four outcomes therefore meet the candidate numerical gate while retaining
  the explicit status `AUTHOR_REVIEW_CANDIDATE_ACCEPTABLE_SENSITIVITY_UNRESOLVED`;
- all 571 protected earlier H06_daily identities remain byte-identical; and
- the serial pilot completed 108 fits in 6.46 seconds. Its mechanical
  timing-only projection across the 12 declared scenario roles is 77.5
  seconds, without deletion work or resampling.

The focused test reproduced: 34 pins, 12 frames, 108 fits, 36 PSD HC3
matrices, 24 raw-only tests, 48 sensitivity rows, four residual figures, 571
protected identities, and 43 report identities.

## Accepted evidence identities

| Item | SHA-256 |
|---|---|
| Report source | `ceb766312f5c2981cbed4106c16080d83942e47402ef23cc394ce8e35a408954` |
| Report HTML | `faa4efecd2a969284dfe399684eb7cf73a0bebdb0fb391227d85cc3b0112794e` |
| Transition | `edc9b5ef5a895ab27f7e350764b94a4bf40e93b129e42df66999f2f810984875` |
| Input manifest | `05d9fc2e99206ae293d24534f279fb835ad1062f683610701e770db73fbbc8e5` |
| Output manifest | `43e83b27e2261cadf9fc9a558c7cbd8b540799df761a51dd9fc1910582ccc90e` |
| Pipeline manifest | `f4f219bd850cb1186a0f5b3d683b514618e0769f87177e29f08f6b27219076b2` |
| Report manifest (43 identities) | `20a9f5ecdeac0e5e4c02b6f0ad48523be7f6bbf1619f79b479a67fad22ea6c71` |
| Software manifest | `3bf07903bff77c59c821921b73bc03ff89849cd5aac5192fac1ebdab88bce41c` |
| Model bundle | `769af576e4dd8ce2e5c059b49a57d7b7fa567b5b2bc5186cc5525fddbe6683ad` |
| Focused test | `6a7eb112ad93fef328ec81e4dad7851b5a5c57b9db45ed257c4e66d0cd634e33` |

## Scientific interpretation of the repair

The HC3 route changes how uncertainty is calculated, not the outcomes,
eligible participant-days, clock cutpoints, or predictor estimands. It is a
marginal participant-day analysis with fixed site adjustment. Clustering by
participant protects its standard errors and tests against heteroscedasticity
and arbitrary within-participant dependence.

This makes the overall association route statistically usable with 136–141
participant clusters. It does not resolve the scientific instability of the
timing predictor-by-site interactions. Those interactions may remain in the
prespecified multiplicity structure for transparency, but their interpretation
must be explicitly qualified by the sensitivity failures above.

## Frozen boundary pending author decision

No pilot p-value or estimate is accepted. No full remaining-grid production,
BH update, deletion battery, Stage 2 merge, Stage 3 or Stage 4 report, shared
edit, L10 or MDER change, temporal-GAMM change, pre-sleep change, or main-H06
change is authorized. All earlier H06_daily records remain frozen.

## Author choices

The author may either:

- accept the constrained recommendation and separately authorize the complete
  remaining non-L10 production grid under a new bounded production contract;
  or
- keep one or more timing outcomes on hold and specify a different scientific
  amendment.

## Reopening condition

Reopen if a sealed identity or verifier fails; a frame, outcome encoding,
predictor, formula, cluster unit, covariance, sensitivity, stability result,
multiplicity rule, protected artifact, or interpretation changes; or the
author selects a different route.
