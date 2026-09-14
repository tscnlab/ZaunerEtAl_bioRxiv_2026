# REPORT-017 H01 order 32h combined stopped state

Date: 2026-08-15  
Owner order: `audit/report_harmonization/owner_orders/32h_h01_historical_recovery_direct_reseal_and_result_completion.md`  
Order SHA-256: `2f3ed3658f026ab509db47761ca6c101243e1d08770f23d5b546af8e739aa5de`

## Disposition

The historical recovery, two bounded test classifications, direct manifest reseals, complete pre-render suite, exactly one H01 result render, semantic repair, structural checks, and all safely executable visual checks completed. The rendered result cannot yet be accepted because secure-loopback review found one new blocking display defect. No patch or second render was attempted after the defect appeared.

## Blocking visual defect

`H01-REPORT017-32H-VIS-001`: the representative diagnostic tabset extends 1,044.3 px below the `Model checks` section and overlaps the following `Sensitivity analyses` section by 595 px. At the centre of the second tab, `document.elementFromPoint()` returns `section#sensitivity-analyses`, not the tab. The second tab remains unselected and three non-active diagnostic plots cannot be reached through the reader interface.

Primary evidence:

- `order32h_visual_diagnostic_tab_overlap.json`
- `order32h_visual_desktop_diagnostic_tab_controls_positioned.png`
- `order32h_visual_qa.json`

The four diagnostic PNGs themselves were inspected from their durable sources and are readable. A focused crop also confirms that the full title of the sleep-environment diagnostic PNG is present. The defect is page layout and interaction, not a scientific-output or source-image defect.

## Completed gates

- Immutable historical display-test recovery is byte-exact at SHA-256 `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`, 6,747 bytes.
- The display-refresh and REPORT-016 test edits have exact reverse proofs to their accepted pre-order identities.
- Reporting manifest: 49/49 exact.
- Stage 3 manifest: 118/118 exact.
- Preparation manifest: 59 live-exact rows plus exactly three mandated preserved historical rows.
- Worker manifest: 1,657 live-exact rows plus exactly two established historical rows.
- Dispatch protected identities: 26/26 exact.
- Non-circular leaf paths: 10/10.
- Pre-render focused H01 tests, R parse, and the approved Air 0.4.1 check passed under R 4.6.1.
- The render used Quarto 1.9.37 and R 4.6.1 and exited successfully.
- The semantic hook returned `REPAIRED`: 36 native `gt` tables, 783 namespaced IDs, 4,798 `headers` values, and 5,581 reversible substitutions.
- The result contains 36 tables, 10 intended figures, 40 links to 36 unique preregistration-deviation anchors, unique document IDs, resolved table headers and ID references, complete alt text, and no raw error, warning, unresolved-reference, or stderr nodes.
- `fig-h01-model-support` and `tbl-h01-primary-publication-summary` are the first principal figure and table.
- Principal output uses FDR language and contains no visible `BH-adjusted` shorthand.
- Protected content and mtimes remain exact for 1,689/1,689 inventoried paths.
- Build content changes are exactly the five classified allowed outputs. There are no build symlinks.
- The companion HTML remains frozen at SHA-256 `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

The global country-code corpus test also reported two pre-existing, out-of-scope H04 source labels at `notebooks/hypotheses/H04.qmd:886` and `audit/hypotheses/H04/H04_analysis_preparation.qmd:914`. Both H01-owned sources passed the focused country-code contract. No H04 file was edited.

## Single render and retained semantic audit

Exactly one command was run:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H01-order32h-semantic-audit.LHzeUC quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

The audit directory was created empty with mode `drwx------` and is retained at `/private/tmp/H01-order32h-semantic-audit.LHzeUC`. Its summary SHA-256 is `e5ac3c6ff47cfb5be2c00fc09515e8cce792054c4a15d2908ebb29774c48ab0b`; its 5,581-row ledger SHA-256 is `20de7cedefb5f2d35501dbb49ca4b387d6c819c304c0ce3ef0a485afe4d78af5`.

The fresh result HTML is:

- path: `_build/nathealth/notebooks/hypotheses/H01.html`
- SHA-256: `df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007`
- bytes: 1,643,915

## Visual and server QA

The full reader page was inspected section by section at 1440 x 1000 and 708 x 1000. The principal table and figure were reviewed in focused desktop and 708 px views, and the principal figure source was inspected at 3,360 px natural width versus 1,148.5 px final desktop width, which exceeds a 200% final-size inspection. All ten durable figure PNGs were inspected at source or final display size. Apart from `H01-REPORT017-32H-VIS-001`, typography, labels, legends, callouts, figure clipping, page overflow, principal-table readability, navigation, and source links passed.

The server was bound only to `127.0.0.1:48173`, then interrupted after QA. A final `lsof` check returned no listener. See `order32h_server_lifecycle.csv`.

## Frozen boundaries

No QMD, scientific value, source CSV, figure, model output, profile, semantic hook, package, lockfile, ledger, manuscript, companion HTML, or other hypothesis file was changed. No model, fit, prediction, bootstrap, resampling, or other scientific computation ran. The companion and all later REPORT-017 targets remain held. No commit, push, upload, companion render, later-target render, full-project render, patch after failure, or rerender occurred.

