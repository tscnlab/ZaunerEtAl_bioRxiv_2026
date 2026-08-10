# H03 shared change request

- Date: 2026-08-10
- Requested owner: Nature Health coordinator
- Blocking boundary: H03 analysis-preparation/provenance companion

## Finding

The coordinator-owned `_quarto-nathealth.yml` currently lists
`notebooks/hypotheses/H03.qmd` in the render sequence and navigation, but it
does not list the H03 preparation companion. The accepted shared contract in
`scripts/pipeline/hypothesis_preparation_provenance_contract.R` requires each
preparation page to be immediately adjacent to its result page in both places.

The H03 worker did not modify the shared Quarto profile.

## Requested shared change

The source now exists. Please make the following coordinator-owned additions
to `_quarto-nathealth.yml`:

1. In the render list, immediately after
   `notebooks/hypotheses/H03.qmd`, add:

   ```yaml
   - audit/hypotheses/H03/H03_analysis_preparation.qmd
   ```

2. In the hypothesis navigation, immediately after the H03 results entry,
   add:

   ```yaml
   - href: audit/hypotheses/H03/H03_analysis_preparation.qmd
     text: "H03 preparation and provenance"
   ```

## Why this is required

Without these entries, the shared preparation-companion verifier fails its
adjacent render/navigation contract, the result and provenance page are not a
discoverable pair, and a profile render will not include the H03 preparation
page. The source is now available, so the entries can be added without making
the shared profile point to a missing file.

## Current H03 status

Stage 3 is author-approved. The final requested Figure 2 and Figure 8 colour
changes and the common Figure 2 scale are implemented, rendered, and verified.
The focused R 4.6.1 Stage 3 test passes.

The H03-owned Stage 4 source now exists at
`audit/hypotheses/H03/H03_analysis_preparation.qmd`. Its bounded direct render,
seven preparation source-data CSVs, four empirical figures, figure-readability
QA, and 319-file preparation manifest are complete. The source and copied
website source are byte-identical. No model was fitted, predicted, simulated,
or bootstrapped during the companion render.

`tests/hypotheses/H03/test_h03_preparation_report.R` completes all H03-owned
content, sample, source-data, rendered-output, figure, accessibility,
readability, and manifest assertions. It stops only when the shared verifier
checks `_quarto-nathealth.yml`, with:

```text
The preparation page is not immediately after its result in the render list.
```

After adding both entries above, please render the adjacent H03 result and
preparation pages with the Nature Health profile and rerun that focused test.
The H03 worker did not modify any shared file.
