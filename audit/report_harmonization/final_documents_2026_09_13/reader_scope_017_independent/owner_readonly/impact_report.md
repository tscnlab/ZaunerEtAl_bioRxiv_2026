# Reader-scope correction: consolidated read-only impact audit

14 September 2026. Temporary audit only. No project source, build or historical evidence was modified. No candidate, render, browser session or scientific refit was created. The accepted Order016 live inventory remains exact at 914 files.

## Decision-ready scope

The narrow boundary confirmed by the Coordinator is **15 public retirements and 45 public replacements**. The replacements comprise 43 HTML files, search and sitemap. There are also two non-public integration dependencies: the Nature Health profile and current corpus manifest. The builder and navigation test require a separately authorized 36-route contract or historical classification, not blind execution.

This proposed boundary would leave **899 public files**, with 854 unchanged and 45 replaced, **36 reader-corpus/search routes**, and **938 search records**. The live sitemap currently contains 39 URLs, including two unregistered workflow pages. Removing only Sensitivity checks gives **38 sitemap URLs**, not 36. Those two extra workflow URLs and associated files are explicitly flagged below rather than silently included in the deletion scope.

The full exact path/byte/hash matrices are:

- `proposed_public_replacement_matrix.csv`: all 45 replacements, with current byte identities and per-path actions.
- `proposed_public_retirements.csv`: all 15 exact files, with identities and inbound-reference owners.
- `sensitivity_inbound_exact.csv`: all 47 relevant inbound HTML references across 43 surviving HTMLs.
- `passage_inbound_exact.csv`: the seven passage-change links, including the standalone TOC link.
- `preimage_manifest.csv`: 64 exact temporary preimages, 95,299,334 bytes. These cover all 60 potentially affected public files plus the profile, corpus, builder and navigation test. Copies are under `preimages/`, never in a candidate or public directory.
- `live_inventory_before.csv`: all 914 exact baseline members. `read_only_closure.json` confirms that they still match both the audit start and accepted Order016.

These counts are proposed infrastructure changes, not a claim that the changes have been implemented.

## Entry pages and editorial utilities

| Public path | Exact target | Proposed action | Preserve |
| --- | --- | --- | --- |
| `index.html` | `section[data-site-utility="true"][aria-labelledby="site-downloads-title"]`, starting at line 707 | Remove the entire download box, including all its 24 links | The separate Other Formats link `MS Word`; all manuscript/SI scientific content, images, tables and references |
| `supplementary_information.html` | Download section with `aria-labelledby="site-downloads-title"]`, starting at line 608; its paragraph containing the three passage links at line 633 | Remove that paragraph only | Complete Word link, all 19 editable-table links and return-to-manuscript link, leaving 21 links in this utility |
| `supplementary_information.html` | `section[data-site-utility="true"][aria-labelledby="site-passage-changes"]`, starting at line 8632 | Remove the entire editorial section, including all 20 change rows | The preceding complete scientific Supplementary Information section |
| `supplementary_information.html` | TOC `li` containing `a[href="#site-passage-changes"]`, line 603 | Remove this TOC item, not merely the anchor text | The scientific TOC, including all sensitivity/robustness sections |

The exact `data-site-utility` value is `true` on all three sections, not a semantic value such as `downloads` or `changes`. The `aria-labelledby` value disambiguates the two standalone utilities. The initial draft matrix's invented semantic values were corrected during this temporary audit before handoff. No candidate or public edit used them.

The manuscript's modest Other Formats Word link is outside these utilities at `/html/body/div[2]/div/nav/div[1]/ul/li/a`, with href `ZaunerEtAl2026_NatHealth_phase3_brown.docx`. Keep it.

The utility boxes and change table are static integration additions. They do not occur in current `index.qmd` or `supplementary_information.qmd`. Do not execute those historical sources to achieve this change. Existing utility CSS can remain byte-identical; the retained standalone download block still uses it. Removing unused change-table CSS is unnecessary scope expansion.

Retire only the public copies of the two editorial files, after durable recoverable archival:

| Path relative to public build | Bytes | SHA-256 |
| --- | ---: | --- |
| `manuscript_changes.csv` | 39396 | `abaa25cc7f25ecfc8a54895d6e375030ed08dbbd63fac8b7eccf68bd23b298d8` |
| `manuscript_changes.md` | 38124 | `341a8d7a92843c5d8188a433a628bc943eeae7572c54af248f5ce8559e58ff24` |

No manuscript Word, editable table or figure file should change. Their public download inventory becomes 20 retained files rather than the old 22-download contract that included the two editorial files.

## Withdrawn Sensitivity checks page

The exact page is `notebooks/sensitivity_battery.html`, 53,303 bytes, SHA-256 `977bc8dab6ee4b28ec506c0e1b4d4f1bd27339311ce78972cd6fefe08a2fc219`. The title is “Planned sensitivity checks”, with the subtitle “Change one analysis choice at a time”. R 4.6.1 extraction confirms a planning description, planned alternatives and classification rules; its only shown setup cell is unevaluated in the source. This is not the location of fitted sensitivity results.

Keep the author source `notebooks/sensitivity_battery.qmd` and all underlying analysis, audit and decision records. No physical copy of `notebooks/sensitivity_battery.qmd` exists in the public build. The HTML's embedded source disappears with that withdrawn HTML; no separate source-copy retirement is needed.

The page's 12 dedicated support files are all under `notebooks/sensitivity_battery_files/`. All exact leaf paths and hashes are in the retirement matrix. No other HTML references that support directory. The only internal CSS dependency found is `bootstrap-icons.css` to its same-directory `bootstrap-icons.woff`; both are among the 12 proposed retirements. Other pages' byte-identical library copies remain untouched. Do not delete shared library paths based on matching hashes or broad directory patterns.

The 47 inbound references from surviving pages comprise:

- 39 navbar entries.
- Four sidebar entries, in `audit/H01/02_implementation_and_v0_comparison.html`, `audit/hypotheses/H03-H11_gated_workflow.html`, `audit/hypotheses/implementation_result_comparison_contract.html`, and `notebooks/descriptives 2.html`.
- Two `head` links and two previous/next links, in `audit/hypotheses/H11/H11_analysis_preparation.html` and `audit/hypotheses/H03-H11_gated_workflow.html`.

Remove each exact navigation item's enclosing `li` or next-page wrapper as appropriate. Remove the corresponding exact `link[rel="next"]` in those two heads. Do not repoint a removed next link to an unrelated page. The Supporting material menu retains Supplementary Information. No surviving page has a scientific body link to the withdrawn planning HTML. The old unregistered pages are touched only for these exact withdrawn-navigation references, not as authority to rewrite or delete their content.

## Search, sitemap, corpus and profile

`search.json` has exactly four withdrawn-route records, the last four objects at zero-based indices 938 through 941:

1. `notebooks/sensitivity_battery.html`
2. `notebooks/sensitivity_battery.html#purpose`
3. `notebooks/sensitivity_battery.html#manuscript-prepared-data-sensitivity`
4. `notebooks/sensitivity_battery.html#what-this-notebook-uses-and-produces`

Remove only those four objects. The remaining 938 objects, their order, fields and text must remain identical. Manuscript downloads, passage changes and their utility text are already excluded from search; no scientific text regeneration is needed. There are no search records for the two old workflow pages.

`sitemap.xml` is 6,809 bytes, SHA-256 `a45815103a7aafca2de8782f6b84a5a48651c38585647482dc1f782ef7ebe74b`. Remove only the exact `<url>` whose location ends `/notebooks/sensitivity_battery.html`, retaining all other entries and their `lastmod` text. The separate workflow-only URLs are recorded in `sitemap_scope_items.csv` for a central scope decision.

The current corpus, `audit/report_harmonization/phase4_corpus_manifest.csv`, is 11,479 bytes, SHA-256 `642161dfc1ec18572b8b8c124546060c8f889683ebf7ceb8e5e43dc785f77669`. Remove logical row 37 for the planning page. Rows 1 through 36 retain their logical order and sidebar positions. Preserve all 36 historical source-hash cells, roles, source paths and titles. Update only affected current HTML hashes and the two render positions corresponding to the reduced profile: index 36 to 35, standalone SI 37 to 36. Other render positions remain 1 through 34. Preserve the known historical source-gap classifications rather than refreshing source hashes from the filesystem.

The exact profile `_quarto-nathealth.yml`, SHA-256 `e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7`, needs three narrow changes on a future explicit release:

- Remove the positive render entry for `notebooks/sensitivity_battery.qmd` at line 47.
- Remove the Supporting material menu item at lines 86 to 87.
- Remove the now-empty robustness sidebar group at lines 217 to 225, not merely its href.

Neither `_quarto.yml` nor `_quarto-website.yml` has this route. Do not alter those profiles. Do not use Quarto to merge, render or refresh the site during the static route.

## Scientific content that must remain

The 36 retained reader routes include the manuscript, standalone SI, seven preparation pages, placement decision, descriptive analysis, preregistration deviations, and hypothesis findings/methods companions. Genuine scientific sensitivities within those reports remain unchanged, including paired-position comparisons, coverage restrictions, gap-timing-unaware comparisons, model/diagnostic limitations, and site/influence/alternative-model checks.

In particular, do not remove manuscript Results `#measurement-position-and-robustness-constrain-interpretation`, Methods sensitivity/coverage statements, either entry's `#measurement-position-robustness-and-reproducibility`, visual-light-sensitivity results or preregistration-deviation reporting. “Sensitivity”, “approved”, “provenance” and “audit” are not deletion keywords.

`content_scope_extract_R.csv`, the extracted planning-page text and `retained_reader_scientific_content_fingerprints_R.csv` document this separation. The latter contains serialized-main, main-without-utilities, text and ordered-image-source fingerprints for every retained reader route, plus structural display counts. R 4.6.1 with xml2 1.6.0 and digest 0.6.39 was used, with the project R library and renv autoloader disabled. These checks extracted and fingerprinted existing content; they did not recompute estimates, denominators or models.

## Ambiguous or broader non-reader remnants

The public build has 45 HTML files but only 37 current reader routes. Eight old unregistered HTMLs remain. Two are clearly workflow-oriented and also occur in the sitemap:

- `audit/hypotheses/H03-H11_gated_workflow.html` and its public QMD copy. Its complete 14-file family includes 12 dedicated support files. Content describes task ownership, staged approval gates, computation approval and reopening rules.
- `audit/hypotheses/implementation_result_comparison_contract.html`. Its 13-file family includes 12 dedicated support files but no public QMD copy. Content describes submitted-versus-audited comparisons, approval requirements and internal ledgers.

Neither family has inbound support-file references from other HTML pages. Their HTML links are confined to the old unregistered workflow/analysis pages, including old `notebooks/descriptives 2.html`. Exact inbound paths are in `ambiguous_nonreader_inbound.csv`. Removing these 27 family files would require an explicit additional boundary, not be folded into the 15-file planning-page/changes retirement. Their underlying author and audit source must remain. The Coordinator has specifically restricted old unregistered HTML changes to the exact withdrawn Sensitivity navigation for now.

The mixed historical result-comparison page `audit/H01/02_implementation_and_v0_comparison.html` and five other old duplicate result/preparation HTMLs are not automatically internal editorial logs. Do not delete them through a generic filename or “audit” rule. Similarly, public decision records and linked comparison ledgers can contain scientific definitions or results. `manuscript_prepared_data_sensitivity.md` is linked from the withdrawn planning page and the surviving comparison contract; bootstrap policy and five comparison/status ledgers are linked from that contract. Preserve them pending exact central classification. No approval-named public file was found by filename inventory, but that is not a claim that all scientific uses of approval terminology are editorial logs.

## Historical tests and helper contracts

Do not rerun historical publication tests against the new reader scope without classification. In particular:

- `tests/report_harmonization/test_navigation_contract.R` is not read-only: it sources `build_phase4_corpus_manifest.R`, which writes the current corpus and refreshes source/HTML hashes. It also asserts 37 rows. Do not execute it in this audit or blindly after retirement.
- `scripts/report_harmonization/build_phase4_corpus_manifest.R` hard-codes the planning page as the final accepted reader source. A durable 36-route builder/test change needs an explicit additional source release or a new scoped validator. Its current version remains historical.
- Navigation integration and final-corpus checks bind 37 routes, old render/sidebar positions, exact output hashes and approved navigation shells. Examples are `check_report018_final_corpus_integration.R`, `navigation_integration_support.R`, the navigation candidate/postflight helpers and sensitivity Order62 checks. Their previous PASS records remain true for their historical state.
- Frozen Order011/015/016 helpers require 914 files, no removals, 908 unchanged files, 37 routes, 942 search records, 35 non-entry reports, both 19-link utilities, 20 change rows, a main revision link, and 22 downloads. Those membership/publication assertions are intentionally superseded by this future reader-scope change.
- Order016 `verify_content.R` contains valid scientific-content checks but also requires the public CSV and 20 rendered change rows. `verify_targeted.R` compares the full old navigation shell. Reuse the scientific predicates only in a newly scoped read-only checker; do not edit or rerun sealed historical helpers or their automatic rollback entry points against a different release.
- Keep gt semantics, table header/ARIA integrity, figure payload/order, content equality, local-reference closure and protected-source checks. Replace only scope-specific publication expectations with the explicit new matrix, not weaker broad exceptions.

## Proposed candidate-first, no-rerender execution path

This is a proposal, not current authority to execute.

1. Have the Coordinator freeze one exact release matrix and classify the workflow-only remnants. The minimum audited plan is the 15 retirements, 45 public replacements, profile and corpus changes above. Do not allow later additions through a broad content filter.
2. Snapshot the exact accepted Order016 live914 into a new isolated candidate and retain durable preimages for every proposed replacement/retirement. The temporary preimages here establish exact current identities but are not a substitute for the later sealed rollback package.
3. Implement surgical raw-byte deletions using the observed DOM targets to delimit spans. Do not reserialize whole HTML pages, regenerate scientific content, change CSS, rebuild Word/tables/artwork, or run Quarto. Every unexpected count, target, hash or inbound dependency is a stop.
4. Preserve the exact raw scientific section bytes in both entries and all main content in the other retained readers. After stripping only approved removed utilities, R fingerprints, ordered SVG/image payloads, all 19 native tables and complete Word identities must remain exact. Site shell differences must be limited to the enumerated menu/sidebar/next-link spans. Preserve inherited duplicate-ID multisets in non-entry reports and check entry header/ARIA references after utility removal.
5. Require exactly 899 candidate files for the minimum plan, 45 replacements, 15 retirements and 854 unchanged members. Preserve current historical source hashes. Validate 36 ordered corpus/search routes, 938 identical retained search objects, the deliberate 38-URL sitemap boundary, and no retained resolved link or raw route reference to retired paths. Retained Word/table GET/HEAD checks become 20; retired public paths should be absent/404 in later authorized serving.
6. Run new scoped structural and R preservation checks on the isolated candidate. Perform browser QA only after a separate browser/candidate release, retaining the accepted search/layout qualifications. Review the main page without its box, standalone downloads without editorial links, navigation endings and unavailable withdrawn route.
7. After independent acceptance, perform a recoverable exact-path local transaction with precondition hashes, explicit archival retirements and manifest last. Keep source scientific files and all prior seals untouched. Stop rather than overwriting unexpected concurrent changes. No remote publish or submission follows from this change.

## Audit closure

All ad hoc files are confined to `/private/tmp/reader-scope-audit-20260914.nnDbyu`. The project remains unmodified by this task. At 18:02:16 UTC, the entire current live914 matched the accepted Order016 and the audit-start inventory. The full downstream mapping, temporary preimages and R content fingerprints are ready for the Coordinator's boundary decision. No implementation, candidate, browser or production release has been assumed.
