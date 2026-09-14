# Brown adherence Stage 4 language-harmonization render release

Date: 2026-08-21

Workflow: `REPORT-018`

Controlling decision: `BA-016`

Controlling change: `CHG-155`

Status: **STAGE 4 RESULT-ONLY RENDER AUTHORIZED**

## Gate basis

The paired Stage 3 and Stage 4 language sources were independently accepted,
and the harmonized Stage 3 reader page is now independently accepted under
`audit/decisions/brown_adherence_stage3_order50_independent_acceptance.md`,
SHA-256
`cc5f751f7f86ce2ec1cd930f60bea19cca8e6bdfd2b33113c978694a6357a7be`.
Its 26-member non-circular acceptance manifest passes completely under R
4.6.1. The serial Stage 4 gate is therefore open.

This release creates no new Brown scientific decision or change identifier.
`BA-016 / CHG-155` remains controlling.

## Exact render pins

The owner must reproduce these identities in the isolated Brown worktree
before invoking Quarto:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Accepted Stage 3 QMD, held | 55,426 | `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43` |
| Accepted Stage 3 HTML, held | 4,825,090 | `3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d` |
| Harmonized Stage 4 QMD | 24,416 | `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475` |
| Historical semantic Stage 4 HTML | 4,340,432 | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| Paired source-only 19-member seal | 3,659 | `bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46` |
| Historical Stage 4 113-member manifest | 54,203 | `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2` |
| Historical Stage 4 manifest verification | 29,804 | `60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38` |
| Stage 3 owner 80-member manifest | 16,282 | `37b728618d875a16939c382c243dea7ff29d8dc72fd945ac16a16082c755e8f4` |
| `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The historical Stage 4 manifest must have exactly one live transition before
render: its historical QMD identity
`642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29`
at 24,147 bytes to the accepted harmonized QMD above. The other 112 members
must remain live-exact.

The accepted semantic engine remains
`scripts/report_harmonization/repair_gt_html_semantics.R`, 17,747 bytes,
SHA-256
`7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.

## Authorized command

From the isolated Brown worktree, the owner may invoke exactly one targeted
Stage 4 render:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
BROWN_ADHERENCE_PROJECT_ROOT=/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 \
BROWN_ADHERENCE_AUTHOR_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
quarto render audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd --to html
```

This uses the accepted R 4.6.1 project library with the renv autoloader
disabled to avoid the documented cache-startup loop. It does not authorize a
restore, install, update, profile bypass, or alternate library. If startup
fails before QMD execution, stop and return one environment record without a
retry.

## Authorized writes

The owner may replace only:

- `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html`;
  and
- new, non-circular render, semantic, verification, link, privacy, responsive,
  visual-QA, lifecycle, and acceptance evidence under
  `audit/analyses/brown_adherence/language_harmonization/stage4_render/`.

The Stage 4 QMD is an immutable input. Existing Stage 3 and Stage 4 evidence,
source data, figures, table sources, models, final manifests, handoffs, author
gates, and `renv.lock` must remain byte-identical.

## Semantic candidate contract

After a successful render, the owner must first preserve the exact raw HTML
identity. The owner must apply the accepted semantic repair through a
temporary candidate and promote that candidate once only after all checks
pass.

The fresh HTML may contain the historically documented entity-encoded
at-least-80-percent ID and its matching header references. If present, the
owner may normalize only the exact one generated `id` attribute and its exact
three matching `headers` attributes in temporary bytes before invoking the
unchanged accepted engine. Any normalization must have its own byte ledger and
must compose with the engine ledger to reverse exactly to the fresh raw HTML.

The repair may otherwise change only generated `id` and `headers` attribute
values. It must preserve visible text, rows, cells, headers, captions, notes,
links, CSS, element order, and every other DOM attribute and node. A direct
rewrite of canonical HTML before candidate acceptance is prohibited.

## Required checks

The final Stage 4 page must pass all of these checks:

1. Exactly one `main#quarto-document-content`, 17 native `gt` tables, and one
   top-down Mermaid diagram occur in accepted source order.
2. Document IDs are unique. Every `headers` and internal IDREF token resolves
   exactly once to its intended element, and composed reversal reproduces the
   fresh raw HTML byte-for-byte.
3. The source retains 18 R chunks, 17 unique table endpoints, the single
   Mermaid endpoint, and the complete accepted Stage 4 executable core.
4. All three reciprocal links to the accepted Stage 3 result source and their
   exact anchors resolve. Every reader and source-data target remains relative,
   non-identifying, and available.
5. All 34 paired language actions, 41 protected scientific tokens, accepted
   formulas, estimates, intervals, p-values, multiplicity and FDR decisions,
   diagnostics, R-squared and Shapley values, privacy exclusions, and
   limitations remain exact.
6. The main-versus-exploratory hierarchy, withheld day-level claim,
   non-causal participant-level interpretation, chest context, provenance
   boundaries, captions, country-coded sites, and reader vocabulary remain
   intact.
7. The accepted Stage 3 QMD and HTML, all historical manifests and repair
   evidence, all scientific and display artifacts, and `renv.lock` remain
   exact.
8. The HTML contains no embedded execution error, unresolved cross-reference,
   broken resource, duplicate endpoint, or page-attributable console error.

## Visual QA and stop rule

The owner must serve only a temporary copy on `127.0.0.1`, inspect the complete
page at the available native browser size, and perform deterministic responsive
checks at 390 CSS pixels. All 17 tables, the Mermaid diagram, disclosures,
captions, source links, scrollers, navigation, headings, and final provenance
sections must be exercised. The checks must cover clipping, overlap, page
overflow, missing content, legibility, and console state. Browser viewport
emulation is not required when the active browser API does not support it, but
that limitation must be recorded.

The loopback listener must be stopped, the temporary served tree removed, and
all source, HTML, semantic, protected, and evidence identities rehashed after
QA.

If any genuine page, semantic, link, privacy, or visual defect remains, stop
once and return one consolidated defect list. Do not patch or rerender under
this release. Do not open a new language or cosmetic cleanup loop.

## Prohibitions and next stop

No Stage 3 render, combined render, full-project render, model fit, prediction,
inference, resampling, scientific artifact regeneration, source patch,
package or lock change, manuscript edit, commit, push, or upload is authorized.

The mandatory next stop is independent acceptance of the harmonized Stage 4
HTML package. The provenance-only writer authority already issued under
`BA-016 / CHG-155` is unchanged; this render adds no new scientific claim.

