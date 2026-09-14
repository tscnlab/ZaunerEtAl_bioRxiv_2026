# REPORT-018 H05 order 45 provenance-stop independent acceptance

Date: 2026-08-20

Disposition: **accepted stopped state; provenance-only continuation required**

## Independent conclusion

Order 45 ran its sole H05 preparation-companion render once. Normal R 4.6.1
and renv startup completed, but knitr stopped at the first input-identity table
before producing rendered content. The exact assertion was
`all(verified_inputs$Verification_code == "PASS") is not TRUE`.

The owner stopped record is
`audit/hypotheses/H05/report018_order45_companion_render/order45_stopped_state.md`,
SHA-256
`fd3b6e7ba094d5f1db162670b7de2ad752adab04a5f421a73727a0e549d5fe12`.
Its 15-row non-circular evidence manifest is SHA-256
`de55ec8c8d268c4211ce551b196e956b92a82a55365cda32ecd6340b39ff4ec6`
and passes 15/15 exact, unique rows under R 4.6.1.

The read-only R replay independently reproduces exactly one mismatch among 17
named result inputs:

- historical H05 producer pin for `scripts/hypotheses/H01/h01_contract.R`:
  `9151f2ca8ef549d16df1465768ed5b33c0aa33b37dc315a13e06d795ba20de2e`;
- accepted current source:
  `dfa35f7c8a1ca8a1f2132c6930a8ac219c461ffac769a7423bf85522430da81a`;
- current size: 10,553 bytes.

The H01 METRIC-011 gate and production tests explicitly classify these as the
historical and current contract identities. The other 16 H05 input identities
remain exact. The H05 authoring QMD, stale companion HTML and website QMD,
accepted result HTML, profile, semantic tools, helper, preparation test,
preparation manifest, and scientific artifacts remain unchanged.

The pre-render and post-failure build inventories are byte-identical at
SHA-256
`9fbb5e75e5f0d6d361e6aa402d92721457dd2bfb83d9b0fa13556081e2931cb9`,
836 files and zero symlinks. The pre-render and post-failure protected
inventories are byte-identical at SHA-256
`31fe584aeefd13698453a4ecb2e4eb420b2ef184844b8ad634c8787dcd37e8d0`,
146 paths. The semantic-audit directory is empty.

## Accepted classification

The gate applies current-file equality to a truthful historical producer pin.
That is a provenance-classification mismatch, not evidence that an H05 input,
model, result, or claim changed. The historical producer identity must remain
preserved. It must not be overwritten to imply that the current H01 contract
produced the frozen H05 outputs.

The smallest safe continuation is source-only display and verification logic
that accepts exactly this one historical-to-current transition after an R
4.6.1 check that the H05-relevant metric registry remains identical. It must
continue to fail on any other input mismatch. No H05 input-audit row,
scientific artifact, model, result, source data, profile, package, or lockfile
may change.

After that bounded correction passes source checks, exactly one fresh H05
companion render may run, followed by the unchanged helper, preparation test,
semantic verification, and secure-loopback QA. Every later render remains
held until the H05 companion is accepted.

