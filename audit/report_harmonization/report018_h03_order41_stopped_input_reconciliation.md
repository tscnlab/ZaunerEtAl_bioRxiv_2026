# REPORT-018 H03 order 41 stopped-state and input reconciliation

Date: 2026-08-20

Disposition: **accepted provenance-only stop; bounded two-pin continuation authorized**

## Stopped render

Order 41 passed its complete preflight and consumed its sole render attempt.
The render reached R chunk `tbl-h03-prep-input-identities` and stopped before
producing a new HTML page because two historical H03 input identities no
longer match the accepted current Preparation 06 base bundle.

The owner stopped record is
`/private/tmp/H03-order41-evidence.B7czTa/order41_stopped_record.md`, SHA-256
`fa767cbb9d174e218c3c6b21359ef1b97d71c3826e4fb23d71cb6c33ee8f9bb8`.
Its exact six-row reconciliation is SHA-256
`3fb9a835fff4b386403cc14f55da75720c35c40a55466dc806919e18aae63cf9`.

The two transitions are:

- near-eye one-hour context: `cee864bb0e329b98444088b777c7245250be68111ec9f24db7c0e3f395ed6445`
  to `7591bcfaae4b49fdde2053160848e170895092b223f96108e538066ce210a951`;
- chest one-hour context: `50f50ca5d39d621d06f2794037c4b769e01fc7329a70432e79a51203727ed209`
  to `18134eec529c36e5fd47c7b3bb1e3b909628b97986cd91eff8e59ee9b5343cbb`.

The four other verified inputs remain exact. The result HTML, held companion
HTML, complete build inventory, source QMDs, frozen H03 model frames, and all
scientific outputs remain byte-identical. The semantic hook and browser QA
were not reached.

## Current-input authority

`audit/decisions/preparation06_current_base_model_gate.md`, SHA-256
`63f17f1b9b3a91d437a5964cde063770d0fb4fac3f9c81e588fc374d9cc71f04`,
identifies the current Preparation 06 base-model bundle as approved for
downstream use. Its current base manifest is SHA-256
`8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce`.
That manifest pins the two current one-hour RDS files and verifies them under
R 4.6.1.

## Independent R reconciliation

The durable checker
`scripts/report_harmonization/check_report018_h03_input_transition.R`,
SHA-256
`ca746b915d2b7d7f23f2f28e19518a5590f252da7bb887e523a93d76f7755fa3`,
was run under R 4.6.1 with dplyr 1.2.1, readr 2.2.0, tidyr 1.3.2, purrr
1.2.2, and digest 0.6.39. It read the current accepted inputs, reconstructed
the H03 frames without fitting a model, and compared them with the frozen
`H03_model_frames.rds` identity
`1356a0cbf0cd0487ef5bd3d756b0b6701b9507e354fdb7c3ce90c9f785fed617`.

The checker passed:

- all ten main, paired, gap-timing-unaware, boundary-excluded, and
  supported-cell frame comparisons;
- all columns and every value in those frames at tolerance zero;
- the near-eye and chest responses plus the additive and site-interaction
  model matrices at tolerance zero;
- the category and site-by-category support summaries at tolerance zero;
- all exact-zero-hour counts; and
- both current RDS identities and byte counts against the current base
  manifest.

The structured 18-row result is
`audit/report_harmonization/report018_h03_input_transition_evidence.csv`.
No model was fit or refit, and no estimate, interval, p-value, diagnostic,
sample, scientific artifact, or claim changed.

## Authorized continuation

The mismatch is provenance-only for H03. One continuation may:

1. replace exactly the two historical SHA-256 literals in
   `scripts/hypotheses/H03/h03_contract.R` with the accepted current hashes;
2. replace exactly the expected and observed SHA-256 values for the same two
   rows in `artifacts/06_model_data/H03/H03_input_audit.csv`;
3. require exact reverse substitutions, R parsing, the complete unchanged H03
   Stage 2 test, the durable transition checker, the stored auxiliary-output
   test, and protected-identity checks;
4. perform exactly one fresh H03 companion render with the normal project
   profile and semantic hook; and
5. complete the existing order-41 semantic, link, build-delta, visual, and
   teardown acceptance.

The historical H03 manifests and order-41 evidence remain unchanged and are
classified as historical. No broad manifest reseal, source-language edit,
model computation, result rerender, profile change, later render, commit,
push, or upload is authorized.
