# Working-render and hypothesis-comparison decisions

Date: 2026-07-30  
Status: approved by the author

## REPORT-002: HTML-first working renders

Quarto HTML is the authoritative working and audit format for preparation,
analysis, hypothesis, sensitivity, manuscript-development, and supplementary
documents. Intermediate Word and PDF renders are not required.

The only planned Word output is the final stable manuscript at the
submission-preparation stage. It is not used as the routine analytical
verification format.

Implementation:

- the `nathealth` profile declares HTML only;
- the main manuscript source declares HTML only during development;
- Preparation 06 is rendered and independently verified as HTML; and
- every hypothesis audit is delivered through its Quarto HTML notebook.

Reopen if the author asks for a different working format or the final
submission system requires an additional format-specific validation.

## AUDIT-001: Submitted-versus-audited hypothesis comparison

The primary audit comparison for H01--H11 is the submitted implementation,
result, and claim versus the audited implementation, result, and claim.

Preregistration alignment and deviations remain mandatory, but appear in a
separate later section. They do not substitute for the direct comparison with
the submitted implementation and results.

Implementation:

- retain separate implementation and result-comparison ledgers;
- identify the exact submitted and audited generating files, digital
  fingerprints, samples, estimates, uncertainty, inference, and claims;
- organize each H01--H11 HTML notebook in result-first comparison order; and
- classify practical changes only against a margin declared before comparison.

Reopen if the author changes the comparison target or a submitted result
cannot be recovered from the available files.

## REPORT-006: Manuscript-prepared-data sensitivity

The formal manuscript-prepared-data sensitivity does not rerun the submitted
model implementation. It applies the same new H01--H11 implementation to the
newly prepared data used in the main analysis and to the dataset prepared for
the manuscript, after correcting only objectively demonstrable data errors.
This isolates the effect of data preparation and metric calculation.

The complete rule is recorded in
[`manuscript_prepared_data_sensitivity.md`](manuscript_prepared_data_sensitivity.md).
Differences between the full submitted analysis chain and the main analysis
remain part of the audit discussion under AUDIT-001.

## Related model-reporting decisions

Plain-language output, 95% confidence intervals, and exact fitted-model sample
counts are specified in
[`model_reporting.md`](model_reporting.md). H01-specific multiplicity,
site-follow-up, variation, uncertainty, and sample decisions are specified in
[`h01_model_specification.md`](h01_model_specification.md).
