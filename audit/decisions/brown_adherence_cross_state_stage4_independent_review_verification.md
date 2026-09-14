# Brown adherence cross-state Stage 4 independent review verification

Date: 2026-08-21  
Status: pass with controlled semantic stop  
Gate: `BA-CS-G4-REVIEW`

## Command and environment

The durable checker is:

`scripts/report_harmonization/check_brown_stage4_independent_review.R`

It was executed from the central project with:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_stage4_independent_review.R /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026
```

Environment:

- R version 4.6.1 (2026-06-24)
- `gt` 1.3.0
- `xml2` 1.6.0
- `digest` 0.6.39
- no project profile or `renv` activation
- no QMD execution, Quarto render, browser server, model package, or
  scientific computation

## Reproduced output

```text
Brown Stage 4 independent review PASS with controlled semantic stop
R version: R version 4.6.1 (2026-06-24)
Stage 4 manifest: 79/79 exact, unique, non-circular
Stored gates: 25/25 finalization; 26/26 source; 28/28 render; 18/18 responsive; 18/18 native visual; 806/806 protected; 6/6 authority
Semantic defect: 17 tables; 15 duplicate ID names; 228/552 invalid headers attributes across 10 tables
Temporary repair proof: 100 IDs plus 552 headers rewritten; 683 tokens resolve once; exact composed reverse to accepted HTML
Disposition: independently verified, author gate remains open, no writer provenance follow-up
```

The independent checker rehashes the complete 79-member Stage 4 package,
audits every stored gate listed above, inspects the QMD execution boundary,
parses the rendered DOM, and reproduces the semantic repair only in an R
session temporary directory. It writes no project file.

The accepted Stage 4 QMD, HTML, final manifest, handoff, and author gate were
unchanged by verification. Port 50370 had no listener, the Stage 4 temporary
served directory was absent, and all 18 retained native screenshots were
inspected separately at their stored 1265 by 712-pixel capture size.

## Conclusion

The package passes scientific, provenance, structural, responsive, visual,
privacy, and preservation review. `BA-CS-G4-SEM-001` remains a bounded HTML
accessibility blocker. The controlling review record authorizes one
no-rerender semantic continuation and retains `BA-CS-G4-REVIEW`, shared
integration, and the writer provenance follow-up as held.
