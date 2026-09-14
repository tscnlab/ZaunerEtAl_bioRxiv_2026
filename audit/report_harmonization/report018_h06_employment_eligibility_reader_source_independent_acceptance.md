# REPORT-018 H06 employment-eligibility reader-source independent acceptance

Date: 2026-09-02

Disposition: `ACCEPTED_SOURCE_ONLY_RESULT_RENDER_ELIGIBLE`

## Accepted transition

The accepted near-eye employment-eligibility sensitivity is now integrated
into both reader-facing H06 sources. The result source is
`notebooks/hypotheses/H06.qmd`, SHA-256
`5f8ec988d680e1a3e3dbf2410f0d4e6a49ded80a9990b3a09661aebdc98cbd4e`,
65,023 bytes. The preparation source is
`audit/hypotheses/H06/H06_analysis_preparation.qmd`, SHA-256
`5b128499a1f1a9312089ec47dfd1ba30cebb2a31059608659c0aa464753abfa0`,
63,867 bytes.

The integration is source-only. It reads the accepted stored sensitivity
outputs, adds the exact near-eye sample flow and three association summaries,
keeps predictor-by-site heterogeneity separate, retains the diagnostic
qualification, and states that the sensitivity was not repeated for chest.
The three public links point to stored CSV files. Neither source contains a
reader link to the unregistered standalone sensitivity QMD.

The accepted preimages remain recorded in the H06 handoff:

- result QMD `013496ae4ac5db1e069af98bea87af6c202714ed97d40cf1f7f64e6637239f5a`;
- preparation QMD `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`.

The focused source test is
`tests/hypotheses/H06/employment_eligibility_sensitivity/test_h06_employment_eligibility_reader_integration.R`,
SHA-256
`aa3031f939f0d4ac5f0621e60e18c32fbe5e9716a8fa577a94d2582a620892b0`,
6,014 bytes.

## Independent R 4.6.1 audit

The durable checker
`scripts/report_harmonization/check_h06_employment_eligibility_reader_source_acceptance.R`,
SHA-256
`d49fb9d53274a20f972054ffcd027c201c3cf31a170270895ce75f5e481d936e`,
7,545 bytes, passed under R 4.6.1 with digest 0.6.39. It verified:

- 46 of 46 unique, non-circular sensitivity-manifest members by SHA-256 and
  byte count;
- 31 of 31 accepted report-finalization checks;
- the primary sample of 16,596 supported hours, 715 participant-days, 137
  participants, and nine sites;
- the restricted sample of 15,871 supported hours, 684 participant-days, 131
  participants, and nine sites;
- all three stored ratios, confidence intervals, adjusted p-values, and stable
  classifications;
- all three stored predictor-by-site tests and their support decisions;
- both final QMD identities, the focused test, current historical HTML
  endpoints, profile, and lockfile;
- the required source text and exact stored-CSV link targets; and
- a complete execution of the focused source-only test.

Two acceptance-checker literals were corrected before this final pass. One
now uses the full stored heterogeneity values, and the source-text check now
normalizes whitespace and distinguishes a Markdown link from a provenance
string. These changes affect only the independent checker.

The checker returned:

`H06_EMPLOYMENT_READER_SOURCE_ACCEPTANCE=PASS manifest=46/46 report=31/31 sources=2 effects=3 heterogeneity=3 focused_test=PASS R=4.6.1 digest=0.6.39`

## Preservation and next gate

No model was fit or refit. No sample, estimate, interval, p-value, FDR
decision, diagnostic, source-data file, scientific artifact, display, profile,
package, lockfile, shared configuration, ledger, manuscript, H06_daily file,
or accepted HTML was changed during independent acceptance. The current
navigation-integrated result and preparation HTML endpoints remain historical
pre-render pins at `bf3f7011...` and `ae3dd53c...`.

Only the H06 result page is eligible for the next serial REPORT-018 target
render. The H06 preparation page and every later target remain held until
independent result-page acceptance.
