# H06 Order 66 result render: fail-closed record

Date: 2026-09-02 15:24:10 CEST

Disposition: `FAIL_CLOSED_NO_RETRY`

## Scope and authority

REPORT-018 H06 Order 66 authorized exactly one render of
`notebooks/hypotheses/H06.qmd`. The preparation page, H06 daily analysis, and
all later targets remained held. The controlling order was
`audit/report_harmonization/owner_orders/66_h06_employment_eligibility_result_render.md`,
SHA-256
`5b32f25938356cdfb59de312b8116cf69c84c2bdaf73cf9882e94b27bd582848`.

## Completed preflight

Before Quarto started:

- all 23 unique, non-circular dispatch-manifest members reproduced by exact
  SHA-256 and byte count;
- the durable H06 employment reader-source checker passed 46 of 46 accepted
  sensitivity-manifest identities, 31 of 31 report checks, two reader sources,
  three effects, three heterogeneity tests, and the focused source test;
- the result source was
  `5f8ec988d680e1a3e3dbf2410f0d4e6a49ded80a9990b3a09661aebdc98cbd4e`
  and the held preparation source was
  `5b128499a1f1a9312089ec47dfd1ba30cebb2a31059608659c0aa464753abfa0`;
- all 21 result R chunks parsed without execution, and source order contained
  exactly 14 unique `tbl-*` endpoints and six unique `fig-*` endpoints;
- the complete Nature Health build contained 889 regular files totalling
  373,232,508 bytes and zero symlinks;
- no competing H06, Quarto, Pandoc, semantic-hook, or loopback process was
  running; and
- the external semantic-audit directory was fresh and empty.

The accepted runtime was R 4.6.1, Quarto 1.9.37, knitr 1.51, gt 1.3.0,
dplyr 1.2.1, readr 2.2.0, and digest 0.6.39.

Two assistant-authored read-only endpoint-audit one-liners stopped on shell-to-R
escape quoting before reading or parsing the source. The corrected
fixed-string invocation then passed the required 21-chunk, 14-table, and
six-figure gate. These preliminary invocation errors changed no file and did
not start Quarto.

## Single authorized render attempt

The exact command was run once from the project root:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order66_semantic.0f3pF8 \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

All 43 knitr progress steps completed, including the new
`tbl-h06-employment-eligibility-sensitivity` chunk. Quarto then exited with
status 1 before Pandoc and HTML production. The exact leading error was:

```text
ERROR: unable to open database file

Stack trace:
at Object.openKv
at sassCache
at compileWithCache
at compileSass
```

The elapsed command time was approximately 11.7 seconds. No retry was made,
as required by Order 66.

## Preserved state

Post-failure verification established:

- the pre-render and post-failure complete build inventories are byte-for-byte
  identical, each with SHA-256
  `f5ee9498acab7b2eaf9500afdf9d38c9b638a3b07dc6e8ff737c073ec8210eed`;
- the build delta contains zero paths;
- all 23 protected dispatch members still reproduce exactly;
- the historical result HTML remains
  `bf3f70118afca9264aba77f9483a1cdd783e3c43996c9049fce67780ceca539b`;
- the held preparation HTML remains
  `ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683`;
- the result source, held preparation source, navigation profile
  `e54c7179...`, and lockfile `3bf99c63...` remain exact;
- the semantic-audit directory remains empty because the semantic hook did not
  run;
- no `H06.knit.md` remained in the source tree;
- `_build/nathealth` still contains zero symlinks; and
- no H06, Quarto, Pandoc, semantic-hook, or loopback process remained after
  the stop.

Secure-loopback QA was not started because no new canonical HTML was produced
and the post-render semantic gate could not be entered.

No source, test, helper, historical manifest, handoff, scientific artifact,
figure, preparation page, H06 daily file, shared configuration, ledger,
manuscript, profile, package, or lockfile was changed by the render attempt.
This record is the only durable file added for the fail-closed return.
