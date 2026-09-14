# Brown adherence Stage 3 language-harmonization render release

Date: 2026-08-21

Workflow: `REPORT-018`

Controlling decision: `BA-016`

Controlling change: `CHG-155`

Status: **STAGE 3 RESULT-ONLY RENDER AUTHORIZED; STAGE 4 HELD**

## Gate basis

The paired Stage 3 and Stage 4 source-language pass has received both required
independent source acceptances:

- central acceptance
  `audit/decisions/brown_adherence_stage3_stage4_language_harmonization_source_independent_acceptance.md`,
  SHA-256
  `eb7da424f42cc7e2e953c45a4e559fcff8c1375ec6e64f000520c4753580d6ca`;
  and
- harmonizer acceptance
  `audit/report_harmonization/report018_brown_stage3_stage4_source_independent_acceptance.md`,
  SHA-256
  `1a41eff44049194072dfcdaa58fc67a9a91802b31adf14bc31a1d9ae2bc4185f`.

Their non-circular manifests pass 32 of 32 and 27 of 27 identities,
respectively. Both independent R 4.6.1 source checkers pass. The language
source gate is closed.

## Exact render pins

The Stage 3 render owner must reproduce these Brown-worktree identities before
any command:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Harmonized Stage 3 QMD | 55,426 | `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43` |
| Harmonized Stage 4 QMD, held | 24,416 | `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475` |
| Historical Stage 3 HTML | 4,808,772 | `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0` |
| Historical Stage 4 semantic HTML, held | 4,340,432 | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| Owner 19-row source seal | 3,659 | `bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46` |
| Historical 76-member Stage 3 manifest | 44,950 | `69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21` |
| Historical 113-member Stage 4 manifest | 54,203 | `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2` |
| `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The accepted semantic repair engine is
`scripts/report_harmonization/repair_gt_html_semantics.R`, 17,747 bytes,
SHA-256
`7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.

## Authorized command

Working from the isolated Brown worktree, the owner may invoke exactly one
targeted Stage 3 render:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
BROWN_ADHERENCE_PROJECT_ROOT=/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 \
BROWN_ADHERENCE_AUTHOR_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

This uses the accepted R 4.6.1 project library while avoiding the documented
renv autoloader cache loop. It is not permission to install, restore, update,
or bypass the accepted library. If startup fails before QMD execution, the
owner must stop and return the environment evidence without retrying.

## Authorized writes

The owner may replace only:

- `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html`;
  and
- new, non-circular render, semantic, verification, link, privacy, visual-QA,
  lifecycle, and acceptance evidence under
  `audit/analyses/brown_adherence/language_harmonization/stage3_render/`.

The Stage 3 QMD is an immutable input to this order. No existing Stage 3 or
Stage 4 evidence, source-data file, figure, table source, model output,
manifest, handoff, author gate, or lockfile may be edited or regenerated.

## Semantic repair and post-render checks

After a successful Quarto render, the owner must preserve the raw rendered
HTML identity in its evidence, apply the accepted semantic engine through a
temporary candidate, verify the complete reversible substitution ledger, and
replace the canonical Stage 3 HTML once with the verified semantic candidate.
The repair may change only `id` and `headers` attributes.

The final page must pass all of these checks:

1. Exactly one `main#quarto-document-content`, 16 native `gt` tables, and five
   figure endpoints occur in the accepted source order.
2. Document IDs are unique. Every explicit table-header and internal IDREF
   token resolves exactly once to its intended element, and semantic reversal
   reproduces the raw rendered HTML exactly.
3. All 34 language actions, 41 protected scientific tokens, 38 inline R
   expressions, analytical chunk structure, table and figure endpoints, and
   scientific artifacts remain exact.
4. The complete relative target multiset remains within the accepted source
   contract. `07_results.qmd` occurs exactly once, the reciprocal Stage 4 link
   resolves to `#sec-purpose`, source-data links resolve, and no local absolute,
   worktree, build, or hard-coded HTML source link is introduced.
5. Captions, alt text, country-coded sites, privacy exclusions, main-versus-
   exploratory hierarchy, withheld day-level claim, and non-causal limits are
   present. No participant identifier appears in reader output.
6. The HTML contains no embedded execution error, unresolved cross-reference,
   missing resource, duplicate endpoint, or page-attributable console error.
7. The Stage 4 QMD, Stage 4 HTML, all historical manifests, all 189 protected
   members, `renv.lock`, and every scientific/display artifact remain exact.

## Visual QA and stop rule

The owner must serve only a temporary copy on a secure `127.0.0.1` loopback
listener and inspect the complete page at the available native browser size.
It must additionally perform deterministic narrow-layout checks at 390 CSS
pixels, inspect all five figures at their intended final size, exercise every
table scroller and disclosure, and check headings, captions, legends, labels,
links, clipping, overlap, page overflow, and console state. Browser viewport
emulation or another browser surface is not required when the active browser
API does not support it. That limitation must be recorded truthfully.

The listener must be stopped, the temporary served copy removed, and the
source, final HTML, semantic evidence, and protected inventory rehashed after
QA.

If any genuine page, semantic, link, privacy, or visual defect remains, stop
once and return one consolidated defect list. Do not patch or rerender under
this order. No new language or cosmetic cleanup loop is authorized.

## Held work

The Stage 4 QMD and HTML remain held. No Stage 4 render, combined render,
full-project render, model fit, prediction, inference, resampling, scientific
artifact regeneration, package or lock change, manuscript edit, commit, push,
or upload is authorized.

The mandatory next stop is independent acceptance of the harmonized Stage 3
HTML. Only after that acceptance may a separate Stage 4-only render order be
considered.
