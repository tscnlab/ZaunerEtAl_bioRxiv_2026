# H01 four-stage analysis closure

Decision ID: `H01-011`  
Date: 2026-08-01  
Status: verified

## Decision

Accept the H01 scientific analysis-preparation and provenance companion and
close the four-stage H01 workflow. The authoritative reader-facing result is
`notebooks/hypotheses/H01.qmd`; its adjacent provenance companion is
`audit/hypotheses/H01/H01_analysis_preparation.qmd`.

Stage 3 was explicitly approved by the author under `H01-010`. Stage 4 is a
bounded documentation and provenance step rather than a new scientific gate.
Its completion therefore closes H01 without another model fit, prediction,
`emmeans` calculation, simulation, response-family assessment, or bootstrap.

## Verified scientific disposition

- In the primary near-eye analysis, separate complete 17-test
  Benjamini--Hochberg families retain 8 metrics for overall site, 12 for
  photoperiod, 6 for latitude, and 8 for the same-frame comparison of full
  site with linear latitude.
- Relative to V0, the site, photoperiod, and latitude families each gain one
  supported metric and lose none. The fourth site-versus-latitude adequacy
  family is new and is not a residual site test after adjustment for latitude.
- The eight metrics with a supported overall-site test have 72 hierarchical
  site-versus-equally-weighted-overall-site contrasts with 95% confidence
  intervals and within-metric adjusted p-values.
- The sensitivity battery is qualitatively sensitive at the individual
  metric-family support level while retaining the broad site and photoperiod
  pattern. Near eye remains primary; chest is complementary and is neither
  pooled nor treated as an equivalence analysis.
- All 128 estimable production fits converged with positive-definite Hessians
  and were nonsingular. The complete 136-row diagnostic set contains 31 PASS,
  97 WARN_REVIEW, 8 predeclared NON_ESTIMABLE, and no FAIL_MAJOR_GATE rows.
  WARN_REVIEW limitations remain disclosed and do not authorize a silent
  response-family change.

## Evidence and verification

Final identities independently rechecked in the shared checkout are:

- H01 results source:
  `56d506d4f772ba11ef92353122b12f077adf83323946e434ea4b3d1024b9a7e5`;
- H01 results HTML:
  `c2536fccd665a2845ab0252c1a98990423f10ddb040a59df25c2b5d02756fba1`;
- preparation source and downloadable source:
  `c6afa418af2b833e44a7bfb68544f9c6e55c7218e8d6c3a9318cd0ecac72bf1c`;
- preparation HTML:
  `93bf0bad2763de3fe345b09f7f5867468e648a1c0ab682f65db5482e820b2fc8`;
- 53-identity preparation manifest:
  `9fbf278548796bb418708de5117ea94ca08d754d550f9919351d24f30c2aaaa4`;
- 1,279-identity worker inventory:
  `10f6abf7e1375a90cd00102e5ebaa9f3a38f8165ba09d3c36449dbf37002dc3e`;
- final handoff:
  `ca74ebf8cc31cdeadf4273a0780e0a623eca5873304f4309040df8dd5f6923e0`.

The results page contains 36 semantic `gt` tables and ten figures with alt
text. The preparation companion contains 20 semantic `gt` tables, two figures
with captions and alt text, reciprocal links, a byte-identical downloadable
QMD, two byte-identical downloadable source CSVs, and the bounded execution
note. The shared REPORT-007 verifier and H01 preparation, reporting, contract,
fit-output, response-family, and preserved 128-target bootstrap verifiers pass
under R 4.6.1.

Direct inspection of all exported figures at their original dimensions found
no clipping, overlap, unreadable labels, distorted text, or unit and colour
problems. Automated browser control could not reload a local `file://` URL
under its navigation policy. This is recorded as a verification-tool
limitation, not a preregistration or analytical deviation: HTML structure,
links, semantic tables, captions, alt text, source assets, and exported figures
were checked directly, and the author approved the result page.

## Ledger disposition

The final central records include:

- one closed H01 implementation record;
- one V0-versus-audited family-support comparison;
- one primary-versus-gap-timing-unaware sensitivity comparison;
- one concise result-difference record;
- six claim-provenance records; and
- the three report, figure-QA, and preparation-provenance findings.

The Stage 3 report intentionally contains no V0 or construction-history
language. The accepted Stage 2 comparison remains separately archived and is
the evidence source for before-versus-after claims.

## Reopen rule

Reopen H01 if a sealed scientific input or output changes, a focused verifier
fails, the accepted response package, estimand, model, multiplicity family,
placement role, or sensitivity definition changes, a WARN_REVIEW condition is
promoted or concealed inconsistently, or manuscript prose exceeds the verified
observational and multiplicity-qualified scope.
