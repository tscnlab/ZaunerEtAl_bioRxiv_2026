# Order016 local integration complete

14 September 2026. Harmonizer task `019ff52e-48ac-77b3-9a0e-9a87749a3bba`.

Status: **LOCAL_INTEGRATION_COMPLETE_ACCEPTED_WITH_INHERITED_QUALIFICATIONS**.

The live local website now equals the independently accepted 914-file SVG candidate. Exactly six website files and the corpus manifest were replaced, once, with the corpus last. There were no website additions, source changes, artwork changes, new renders, model runs, uploads, or remote publication. The Writer and scientific owners were not woken.

## Authority and scope

The exact release is `audit/report_harmonization/final_documents_2026_09_13/site_a4_delta_promotion_order_016.md`, SHA-256 `93d5f8afd2579fbd93b3fb07bd906b7ca3cf9a9f7c64d96fd3b8fd9d022a0f5c`, and its 58-row dispatch manifest, SHA-256 `90d5759e5862ae86541a69bb3af129a1bc48d8983a8912afdd8d958fed192546`. The independent acceptance, the original stopped/failure package, and the historical owner pending package remain immutable. Their prior wording and negative observations were not rewritten as successful observations.

The additive Word author approval was received during the active smoke check and did not restart or expand Order016. Its central addendum is `audit/report_harmonization/final_documents_2026_09_13/order016_word_author_approval_addendum.md`, SHA-256 `9da946b6909d7274e172f1988420e929c3f7080092288ea17d79cdb3dca71378`. The 11-member addendum manifest, SHA-256 `206247e68d62fe63271de30a5fff929c2c434ef0a936d22eaf0dd0176eda4249`, was independently rehashed here in R 4.6.1 with digest 0.6.39: 11/11 exact. Results are in `evidence/word_author_approval_addendum_rehash.csv`.

That approval applies only to the already planned Word payload, SHA-256 `6f0ce7a50b608f91d24c31ae0b9b0edefe15828ed4f966732ea616c6e395a570`. The exact new Writer coordination record is `audit/manuscript_nature_health/a4_display_word_author_approval_2026_09_14.md`, SHA-256 `93b63ed97e02431e3365c2920dfeb1509ef24dad3a73599c4e5d9fe51bb8504d`, outside the sealed 318-member candidate. It is not a public payload, an approval of the separate table downloads or website, submission authority, or a change to visual qualifications.

## Transaction and safeguards

The isolated 914-file fixture exercised the same frozen helpers before the live write: all seven replacements, the full content checks, rejection of unexpected concurrent bytes, and restoration of all seven preimages. The fixture ended at the exact baseline. All 14 helper identities remain bound by `evidence/helper_manifest.csv`, SHA-256 `589d262324763c43e589e773a98596aaf81478f260d1b04103903ab687fe3885`.

The live transaction completed at 16:38:49 UTC. `transaction_journal.jsonl` records the seven replacements in sequence, corpus last, followed by `transaction_complete`. No live rollback was required. The final identity and backup mapping is `evidence/final_seven_identities.csv`, written by the finalizer. Every prior payload is retained at its exact path under this package's `preimages/` directory, as well as the applicable historical preimage. Guarded rollback is therefore available; no source or irreversible deletion occurred.

| Sequence | Replaced path | Final bytes | SHA-256 |
| --- | --- | ---: | --- |
| 1 | `_build/nathealth/index.html` | 25367739 | `af87852a1a5e2e5739eb87870fafcf0166e6c79e262c6e1f1f0eb9f3eed7e651` |
| 2 | `_build/nathealth/supplementary_information.html` | 15674831 | `0a1da925d6bb63d2be7139ddcf0c511fb2c5ba10eacf2d340cfed6e61ee8b286` |
| 3 | `_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx` | 14377373 | `6f0ce7a50b608f91d24c31ae0b9b0edefe15828ed4f966732ea616c6e395a570` |
| 4 | `_build/nathealth/editable_tables/Table_S4.docx` | 57084 | `3900fad5fe5bfc306d99f242b8b30f2d9297a9f2351b48d469ef1d3909896c4a` |
| 5 | `_build/nathealth/editable_tables/Table_S7.docx` | 59442 | `682fe317fb1a77b53483e203b05a1410e41816956fbca304b9bfd1e1878ec184` |
| 6 | `_build/nathealth/search.json` | 2350116 | `aef05e5b12417168a526ee35250cfc894fd3fb069769e4687b8a26bf477ef0cd` |
| 7 | `audit/report_harmonization/phase4_corpus_manifest.csv` | 11479 | `642161dfc1ec18572b8b8c124546060c8f889683ebf7ceb8e5e43dc785f77669` |

## Verification

All full production checks passed using the frozen, routed helpers without regenerating candidate or scientific outputs:

- 53,724 static checks.
- 75 R content checks and 15 targeted checks for each entry route. R 4.6.1, xml2 1.6.0, digest 0.6.39 and jsonlite 2.0.0 used the project's R 4.6 library with the renv autoloader disabled. Commands, input routes and evidence destinations are recorded in the three command logs.
- 22 exact HTTP HEAD/GET payload checks, including Word and editable-table endpoints.
- Final 7,763-check closure at 16:54:00 UTC, covering 4,617 protected rows and all bound historical packages. All 914 live files match the candidate; 908 website files are unchanged. The 46 classified historical transition rows resolve to exactly the seven authorized paths, not a broader substitution rule.
- All 23 SVG artwork payloads remain exact. The 35 report pages, 17 unaffected editable tables, 20 revision rows, 942 search records across 37 routes, and historical source hashes retain their specified identities or classifications. The 16 historical source gaps, four font-reference exceptions and five exact navbar controls are not silently repaired or reclassified.

`evidence/production_safe_point.json` records the completed transaction, exact final closure, stopped server, restored viewport and closed task-created tabs. The full candidate visual acceptance carries forward; the live pass was a bounded smoke check rather than another complete visual audit.

## Live browser check and teardown

One read-only GET/HEAD server served only `_build/nathealth` at `127.0.0.1:59586`, with zero symlinks. It ran from 16:40:14 to 16:51:57 UTC. Both `index.html` and `supplementary_information.html` were inspected at explicit desktop and narrow viewports, 1440 by 1000 and 708 by 1000.

The revised S4 and S7, their captions and footnotes, the single Table 2 and its rightmost columns, preserved S2, complete single-SVG S8, corrected S15 to S18 references, and editable links were checked. Narrow tables remained locally scrollable without page-wide overflow. All four ordinary Results links opened the matching live SVG destination in task-created tabs. S16 used focused-link Enter because its wrapped anchor's rectangular midpoint need not fall on link text. The new destination tabs were observed at 1331 by 1324, not assumed to inherit the explicit viewport. The capture identifier `D1440-S15-link` does not override that recorded actual size.

Twenty-two exact CUA JPEG screenshots and 17 tool-output records are archived in `evidence/browser_captures/`; `evidence/browser_capture_manifest.csv` and `evidence/browser_archival_provenance.json` retain their provenance. These are decoded original outputs, not edited or re-rendered screenshots. All temporary tabs were closed, viewport override reset to the observed default 1331 by 1324, and the final task tab inventory was empty.

PID 42385 was confirmed as the exact task server before SIGTERM. Its session completed with exit code 0. The permission-correct socket check at 16:51:59 UTC returned ECONNREFUSED 61; the final safe-point check repeated that closed-port result. No server was restarted.

## Qualifications retained

B1 remains the independently accepted inherited desktop search overflow. Search was not cosmetically repaired, reopened for reclassification, or given an unqualified PASS. B2 was resolved by independent actual-link verification and the live smoke also successfully reached all four destinations. The earlier negative candidate observations remain untouched. The generated Quarto new-tab handler is retained and is not browser injection.

The approved S2 secondary text, full S8 internal whitespace, dense small-screen artwork, and inherited Word S18 footnote/right-edge clipping remain qualified. No new Office rendering was performed or implied. This is a completed local integration with those inherited qualifications, not an error-free-site claim or remote deployment.

## Handoff

The completed entry point is `_build/nathealth/index.html`, with standalone Supplementary Information at `_build/nathealth/supplementary_information.html`. The complete manuscript Word and editable tables are linked within both pages. `completion_manifest.csv` and `completion_seal.json` seal this package non-circularly, excluding only themselves. The Coordinator may use this exact completed local state; no user-side trigger is required for Order016.
