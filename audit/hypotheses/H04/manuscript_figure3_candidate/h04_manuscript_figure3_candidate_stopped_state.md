# H04 manuscript Figure 3 candidate stopped state

Date: 2026-08-31  
Status: **STOPPED AFTER THE SOLE FOCUSED-TEST INVOCATION**

## Controlling scope

- Owner order: `audit/report_harmonization/owner_orders/h04_manuscript_main_figure3_candidate_only.md`
- Owner-order SHA-256: `841efaef5f49467d3e7938aded1d1496d450da53b7dd3ba95b794a4d9a1f63fa`
- Dispatch manifest: `audit/report_harmonization/owner_orders/h04_manuscript_main_figure3_candidate_only_dispatch_manifest.csv`
- Dispatch-manifest SHA-256: `8fe0f26e1f3252e578dd3b7d6048e84d82bc6bbf1ee6432fc7cff896255f5ea2`

## Candidate package

The isolated candidate remains at:

`/private/tmp/h04_manuscript_figure3_candidate.7bhj5n`

Its non-circular temporary output inventory is:

`/private/tmp/h04_manuscript_figure3_candidate.7bhj5n/H04_manuscript_figure3_candidate_outputs.csv`

That inventory has SHA-256
`3f3b29cde456b992cc12eca0e1483fe06374f90b9cf72f8a710f5df8e625dc22`
and contains 12 products. The candidate PNG, SVG, 170 mm raster and vector
previews, panel-d PNG and SVG, source CSVs, exact frame contract, input
identities, tag boxes, and caption were created only in this temporary
directory.

The candidate generation completed under R 4.6.1. Visual QA passed for the
original panel-d display and the 170 mm raster and vector composites. The
candidate contains lowercase panel tags a-d, all 45 panel-d site-category
cells, the sole San José (CR), Outdoors non-estimable token, and the approved
reader vocabulary. A separate read-only decoded-pixel check found 3,679 changed
pixels in panels a-c, all within the three authorized tag boxes and none
outside them.

## Sole test stop

The focused test was invoked exactly once. It exited with status 1 at the first
SVG cell-token extraction:

```text
Error in text_tokens[[1]] : subscript out of bounds
```

The new test had used `./text` against an SVG document with a default
namespace, so no child nodes were returned. This is a verifier-source defect,
not a candidate-generation or scientific-computation discrepancy. The
verifier source was corrected to use `local-name()='text'` and to suppress
parse-expression printing. Air and R parse pass for the corrected source.

The focused test was not rerun because the owner order authorized one focused
test invocation. Candidate acceptance is therefore withheld. A new central
release is required to run the corrected verifier and, if it passes, replace
this stopped state with a completion seal.

## Preservation boundary

No canonical H04 artifact, H04 QMD or HTML, Quarto target, manuscript,
selection document, shared manifest, configuration, ledger, model, prediction,
bootstrap, commit, push, upload, or canonical render was changed or executed.
