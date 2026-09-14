# REPORT-018 H09 order 57 stopped-state independent acceptance

Date: 2026-08-22

Disposition: **ACCEPTED_SCIENCE_INVARIANT_PROVENANCE_TRANSITION**

The sole order-57 H09 companion render stopped correctly before any rendered
output, semantic repair, helper execution, browser QA, or build mutation. The
stop exposed exactly three historical-to-current shared-input identities. It
did not expose an H09 scientific discrepancy.

## Reproduced stopped state

Fresh R 4.6.1 verification reproduced:

- the owner stop record at SHA-256
  `4ff6379f491e77cbf9861cddaf7d9bdb3c091f96b7d6b96cd9a755c59252d563`;
- the owner verifier at SHA-256
  `92226688ee3212469ae3b7aa3580fcc8686f2d62a42c1c189ab61944f1ebcb35`;
- the 14-check failure verification at SHA-256
  `f91c681e6393d5febf8d19c180b3ec744776fae7b12e7a61a900e28fd0477aae`,
  with 14 of 14 checks passing; and
- the owner 45-row seal at SHA-256
  `d8c6399a6c964ad96de7155e5a588809d5f7dd64638d206068782dc0906abc37`,
  with 45 of 45 paths exact, unique, and non-circular.

The accepted result source and HTML, companion source and held HTML, helper,
historical tests, preparation manifest, profile, semantic code, lockfile,
scientific artifacts, build tree, and historical source-side support remained
unchanged. No process from the failed render remains.

## Scientific-scope adjudication

The durable checker
`scripts/report_harmonization/check_report018_h09_order57_stop_and_scientific_scope.R`
ran under R 4.6.1 and passed all 20 adjudication domains. It establishes:

1. The repaired shared participant-day gap artifact changes only MDER. All
   25,620 non-MDER participant-day cells remain exact.
2. H09 uses five gap metrics only: M10 midpoint, L10 midpoint, first timing
   above 250 lx melEDI, last timing above 250 lx melEDI, and mean timing above
   250 lx melEDI. H09 never uses either MDER definition.
3. Rebuilding every stored H09 gap-sensitivity model frame from the current
   shared artifact reproduces 40 of 40 complete frame objects exactly. This
   covers 32,492 frame rows, both placements, both chronotype instruments,
   all five gap metrics, and both all-available and gap-common samples.
4. The shared metric display registry differs from its execution-time identity
   by exactly one row transition, from `mder_ratio_of_integrals` to
   `mder_mean_of_viable_ratios`. All five shared H09 display rows are exact.
5. The 65-row historical H09 scientific inventory has exactly 57 live-exact
   members and eight previously accepted order-56 display-only transitions.
   No model, table, source-data, estimate, interval, p-value, FDR decision,
   diagnostic, sensitivity result, or sample identity has drifted.

The exact order-57 transitions are therefore accepted as H09-equivalent
provenance transitions:

- gap participant-day RDS `28266064...` to `7561b5dd...`;
- gap manifest `af74cc9f...` to `4ed62fbe...`; and
- metric display registry `6c0adc3c...` to `c82db05a...`.

Historical execution identities remain preserved in the order-57 failed
record, `H09_METRIC-011_excluded_shared_drift.csv`, and the independent input
transition audit. They must not be rewritten as if the current files were the
literal execution-time bytes.

## Durable independent evidence

- stopped-manifest replay: SHA-256
  `7870571860e0553dcd144e730f59ac2f8682e4216082ffd4142c1d398e804d0d`;
- 40-frame identity audit: SHA-256
  `4160844ee97a1dae6b22f9aadeb69cde36b27f2be9afcca65bc924e1dde443f2`;
- registry transition audit: SHA-256
  `2c3c35ce4446290b4b2f13c64d48859b4869124c99ba5c721d12ee0ddf82696d`;
- three-transition audit: SHA-256
  `fe4903b825f90abc7d037f3e8745a4e378fe2468c06a8225f80a11dec0632fb8`;
- 65-row scientific-identity audit: SHA-256
  `32572f5b0509dcf761e01827ffd90b1f1055d4e5d565278963beeec8fcbfb453`;
  and
- 20-domain scope audit: SHA-256
  `7c1f13045eaa7d7067f3feb8ef995c85387500eb83c9a390205ab4823e1a00a9`.

## Bounded disposition

One consolidated continuation is eligible. It may update only the three
current input identities in the H09 contract, their three rows in the H09
input audit, and bounded companion provenance wording that distinguishes
execution-time identities from current reproducibility identities. It must
prove exact source reversals, rerun the complete scientific-scope audit, and
then make exactly one companion render retry under the existing order-57
integration, semantic, protected, and visual-QA contract.

No result rerender, model execution, scientific artifact regeneration,
historical-record rewrite, test edit, profile or lockfile change, another
target render, or further retry is authorized. The mandatory next stop remains
independent H09 companion acceptance.
