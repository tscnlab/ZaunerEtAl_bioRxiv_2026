# Confirmed reader-reporting defects

These findings concern inaccurate or internally inconsistent reader wording.
They do not authorize a scientific-analysis change. Each correction remains
subject to document ownership, source-only verification, independent
acceptance, and the REPORT-017 serial render queue.

## RH-REP-001: H10 incorrectly states that gender was not measured

Date confirmed: 2026-08-14  
Status: **confirmed; bounded source/test order prepared but not dispatched**  
Responsible owner: H10 task `019fdc1b-b77b-7972-aed0-784da328e115`  
Serial constraint: do not wake H10 or render it before its REPORT-017 turn

### Defect

The current H10 result and preparation sources state that gender identity was
“neither measured nor inferred” and that “No gender field” entered a model.
The first clause is false, and the second uses a false data-availability
premise. Biological sex and gender were recorded as separate variables. The
accepted H10 analyses used biological sex, coded Female or Male. Gender was
not analysed.

The valid H10 limitation remains unchanged: the fitted biological-sex
associations provide no inference about gender identity.

### Evidence and current planning identities

The coordinator supplied an R 4.6.1 read-only audit with these identities and
findings:

- `artifacts/06_model_data/normalized_inputs/demographics.rds`, SHA-256
  `a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf`,
  contains separate, nonidentical `sex` and `gender` columns for 191 records;
- `artifacts/06_model_data/H10/H10_model_frames.rds`, SHA-256
  `2d1c9119409c908f6890062c46827698aff19b12c3bcc93ce15cb37b28b8a6e7`,
  contains 68 frames with `biological_sex` and no `gender` model term;
- `artifacts/07_models/H10/H10_model_manifest.csv`, SHA-256
  `9ce9c4153d38122398c259ed9bec013ac91afd99a8f90b70a919390321c3baae`,
  contains biological-sex formulas and no gender term;
- `audit/hypotheses/H10/01_audit_and_plan.qmd`, SHA-256
  `cc3faa888ba932a7346e89463435b55608529045ad33111be6a5b57a6480cac4`,
  records the same construct boundary; and
- `notebooks/hypotheses/H11.qmd`, SHA-256
  `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`,
  correctly states that gender identity is a distinct construct and was not
  analysed.

The manuscript writer request is
`audit/handoffs/nature_health_manuscript_shared_change_request.md`, SHA-256
`202330fbc562a8012be449d1d16a2921beb52d8f5b4c0416e9a0bfc4fc332f1a`.

Planning-time reader-source identities are:

- `notebooks/hypotheses/H10.qmd`:
  `3c8d6891854a298e4fad69d1d7499c4d45a7d7c522f50e920b6b6aa1e4abac3f`;
- `audit/hypotheses/H10/H10_analysis_preparation.qmd`:
  `c46d6ae965daba94750220e6eeaf95aa01b5cff4bc929117848f72090b7583f1`;
- `tests/hypotheses/H10/test_h10_stage3_reader_report.R`:
  `9f683babf2fd036bf33acf71ce5ef694d4a78a2893b5c6d4b54df9b9c01a1c3c`;
- `tests/hypotheses/H10/test_h10_preparation_report.R`:
  `836a6b48250946375c512895d05a50c77e6472ccccf987510675a33235cdcb22`.

These are planning references, not dispatch seals. The H10 owner must recheck
all current source and test identities at its later serial safe point.

### Bounded disposition

The prepared correction is source/test wording only. It may update the
opening result paragraph, the biological-sex figure caption, the companion's
construct explanation and model-entry boundary, and only the dependent
source assertions in the two focused tests. It must preserve the exact H10
statement that the analysis provides no inference about gender identity.

No data, model frame, formula, fit, sample, estimate, interval, p-value,
diagnostic, multiplicity decision, figure data, scientific claim, artifact,
configuration, ledger, rendered HTML, commit, or push may change. H10 requires
R 4.6.1 source-only verification and independent acceptance before its later
REPORT-017 render.
