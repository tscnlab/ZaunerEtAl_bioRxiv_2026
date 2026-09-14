# REPORT-018 H07 result independent acceptance

Date: 2026-08-21

Status: **ACCEPTED**

## Disposition

The H07 result page is independently accepted after the one authorized Order
52 render. The result source, held companion source and HTML, profile, tests,
scientific artifacts, and lockfile remain exact. The H07 companion and every
later REPORT-018 render remain held pending a separate serial release.

## Accepted identities

- result QMD `notebooks/hypotheses/H07.qmd`, SHA-256
  `c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226`,
  45,440 bytes;
- accepted result HTML `_build/nathealth/notebooks/hypotheses/H07.html`,
  SHA-256
  `7814860467f71311c56e22960e757059524ccc3890b0721708eda7a5c661ab40`,
  265,730 bytes;
- held companion QMD
  `audit/hypotheses/H07/H07_analysis_preparation.qmd`, SHA-256
  `a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b`;
- held companion HTML
  `_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html`,
  SHA-256
  `53c261b88b5d10238e18e33323ad705c61c92215c040fc84880385cdc434fd2f`;
- owner completion record, SHA-256
  `27c341dd1ed2bae0e260f4f804a5b41e6f30f39fd0c4c615494400fe7e3b90c8`;
  and
- owner 108-row non-circular evidence manifest, SHA-256
  `5a5a7c2e898080cf21cafaa6d088ae92b147c7fd6be160c3cfe9925d79f79221`.

## Independent replay

The independent R 4.6.1 checker at
`scripts/report_harmonization/check_h07_order52_result_acceptance.R`,
SHA-256
`25ac074d3df8a8a90a915dd05bfa05302d87a4796fff382f37d4cb7112161ba4`,
passed 35 of 35 checks. Its verification output is SHA-256
`dae28bcd435ff65e738602cb31dfcc594cf6bb5ef86f3463b95c2dd453e3469d`.

The replay independently verified:

- all 108 owner-manifest members are present, exact, unique, and the manifest
  excludes itself;
- exactly 11 native `gt` tables and two H07 figure endpoints;
- zero duplicate document IDs and exactly one
  `main#quarto-document-content`;
- all 965 table-header tokens resolve exactly once to a `th` inside their own
  table;
- semantic disposition `REPAIRED`, with 154 ID substitutions, 361 `headers`
  substitutions, and 515 total reversible substitutions;
- exact reverse to pre-hook SHA-256
  `1bc9844571dccba9e69285a0bbe6e6783a84fae310469735542fe7fced9b5a32`
  and exact forward reproduction of the accepted HTML;
- 11 of 11 table endpoints, two of two figure endpoints, every nonvisual
  contract, and all three visual QA modes;
- byte-identical post-render and post-QA inventories for 850 build files and
  1,244 protected files;
- the unchanged result reader test passes, while the held preparation test
  remains byte-identical and unexecuted; and
- the loopback server was restricted to `127.0.0.1`, stopped, and left no
  listener. The browser viewport was reset and the QA tab was closed.

The QA pass covered 1440 by 1000 desktop, 708 by 1000 narrow 170 mm, and 720
by 500 200-percent-equivalent views. The single diagnostic-table horizontal
scroller remained contained, was exercised to its end, and was reset. No page
overflow, clipping, overlap, missing content, or report-attributable browser
warning or error was found.

## Boundary

This acceptance covers only the H07 result page. It authorizes no source edit,
scientific recomputation, companion render, later render, full-project render,
package or lockfile change, commit, push, or upload. The stale hard-coded HTML
assertion in the held preparation test remains deferred to the companion
integration gate.
