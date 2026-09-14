# REPORT-018 order 50: Brown Stage 3 language-harmonization result render

Date: 2026-08-21

Owner: `019fffdf-66d4-7802-9091-09283ad27b7f`

Owner worktree:
`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`

Status: **SEALED FOR EXACTLY ONE STAGE 3 RESULT RENDER**

Stage 4 remains held. This order does not authorize a new language or cosmetic
cleanup pass.

## Controlling authority

The exact render authority is:

- `audit/decisions/brown_adherence_stage3_language_harmonization_render_release.md`;
- SHA-256
  `b607f852251f94dc8d27330849a1f921efe9341b5fef4fea0adc3799907f1eca`;
- 6,946 bytes.

Its verification, non-circular manifest, and checker are:

- verification SHA-256
  `10a5c4f23d6a43771120ecb23e8214720af032f253cd55e38e416d3b6807e53a`;
- 20-row manifest SHA-256
  `90a02ef1f00b7e6a406f8fd3a16f1197855ba085c358bd090d95d7cc5b7c612c`;
  and
- checker SHA-256
  `14dacfb35fd50dea9096b9d186fba6db130e3960df637f39c2e4e0dddabfa10f`.

The central and harmonizer source acceptances remain exact at
`eb7da424f42cc7e2e953c45a4e559fcff8c1375ec6e64f000520c4753580d6ca`
and
`1a41eff44049194072dfcdaa58fc67a9a91802b31adf14bc31a1d9ae2bc4185f`,
respectively. Reproduce the order-50 dispatch manifest completely before any
write or process start. Stop without mutation on any drift.

## Immutable render pins

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Harmonized Stage 3 QMD | 55,426 | `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43` |
| Harmonized Stage 4 QMD, held | 24,416 | `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475` |
| Historical Stage 3 HTML | 4,808,772 | `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0` |
| Historical Stage 4 HTML, held | 4,340,432 | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| Owner 19-row source seal | 3,659 | `bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46` |
| Historical 76-member Stage 3 manifest | 44,950 | `69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21` |
| Historical 113-member Stage 4 manifest | 54,203 | `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2` |
| Brown `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |
| Accepted semantic engine | 17,747 | `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1` |

The historical manifests remain immutable. Their QMD rows retain the accepted
historical source identities. Live reconciliation must classify only the
already accepted Stage 3 and Stage 4 QMD transitions plus the one fresh Stage
3 HTML transition produced by this order. Fail on any additional historical
member mismatch.

## Authorized writes

Only these project paths may change or be created:

1. the canonical Stage 3 HTML:
   `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html`;
   and
2. new, non-circular order-50 evidence under:
   `audit/analyses/brown_adherence/language_harmonization/stage3_render/`.

The Stage 3 QMD is an immutable input. The Stage 4 QMD and HTML, every existing
historical record, every source-data file, figure, table source, model output,
manifest, handoff, author gate, package, and lockfile are immutable.

## Preflight and inventories

Before the render:

1. Verify R 4.6.1, Quarto 1.9.37, the accepted library path, and all dispatch
   pins.
2. Confirm that no Quarto, Pandoc, Brown render, semantic-repair, or loopback
   process is active for this worktree.
3. Reverify the owner 19-row source seal, 34/34 actions, 22/22 source checks,
   189/189 historical identities under their accepted transition
   classification, and both exact reverse reconstructions.
4. Create a complete SHA-256 and byte inventory of the Brown source,
   scientific, display, manifest, HTML, package, and lockfile boundary before
   any render write. Record symlink state separately and fail on an unexpected
   symlink.
5. Create a fresh task evidence directory at the authorized Stage 3 render
   path. Preserve a byte-identical evidence copy of the historical Stage 3
   HTML before it is replaced.
6. Record the exact command, working directory, environment variables, process
   state, R and consequential package versions, and start time.

## Sole render command

From the isolated Brown worktree, execute this exact command once:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
BROWN_ADHERENCE_PROJECT_ROOT=/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 \
BROWN_ADHERENCE_AUTHOR_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

Do not add a profile, `--no-execute`, a second target, or another environment
override. Do not install, restore, update, or bypass the accepted library. If
startup fails before QMD execution, stop once with complete environment
evidence. Do not retry.

## Raw render and candidate-first semantic repair

After a successful render:

1. Require exit zero and preserve the raw rendered HTML byte-for-byte inside
   the new evidence directory. Record its SHA-256 and byte count before any
   semantic mutation.
2. Run the accepted engine from the central root with R 4.6.1 against the raw
   HTML copy, writing a temporary semantic candidate and reversible ledger
   under the new evidence directory. The engine takes exactly the raw input,
   candidate output, and ledger paths. It may change only native-`gt` `id` and
   `headers` attribute values.
3. Before replacing the canonical HTML, require exact raw reversal, identical
   normalized DOM and visible text, unchanged captions, notes, links, table and
   element order, and the complete semantic postconditions below.
4. Only after every candidate gate passes may the owner replace the canonical
   Stage 3 HTML once with the verified candidate. Preserve the raw copy,
   candidate identity, ledger, reversal record, and promotion identity.
5. On any engine, candidate, or promotion defect, stop without a second render
   or source patch.

## Complete source and rendered-page acceptance

Create and run one bounded R 4.6.1 render verifier under the new evidence path.
It must fail closed and prove all of the following:

1. Exactly one `main#quarto-document-content`, 16 native `gt` tables, and five
   figure endpoints occur in accepted source order.
2. Document IDs are unique. Every explicit `headers` token and every supported
   internal ID reference resolves exactly once to the intended element within
   its own table or document context. Semantic reversal reproduces the raw
   rendered HTML exactly.
3. All 34 language actions, 41 protected scientific tokens, 38 inline R
   expressions, 19 chunks, 110 parsed expressions, table and figure endpoints,
   and accepted scientific artifacts remain exact.
4. The complete relative target multiset remains within the accepted source
   contract. `07_results.qmd` occurs exactly once. The reciprocal Stage 4 link
   resolves to `#sec-purpose`. All implementation and source-data targets
   exist. No hard-coded `.html`, local absolute, `file:`, worktree-local, or
   build path is introduced in source.
5. All captions and alt text are present. Country-coded sites, the
   main-versus-exploratory hierarchy, the withheld day-level claim, and
   observational and non-causal limits remain visible.
6. The privacy boundary remains exact. No raw, site-linked, or ranked
   participant identifier is present in reader output. The 139-profile
   raincloud remains aggregate and unlabelled by participant.
7. No embedded execution error, unresolved cross-reference, missing resource,
   duplicate endpoint, or page-attributable console error exists.
8. The held Stage 4 QMD and HTML, historical manifest files, all historical
   member identities under the exact three-transition reconciliation, all
   scientific and display artifacts, and `renv.lock` remain exact.
9. The full post-render project delta contains only the authorized Stage 3
   HTML transition and new task evidence. Fail on any other content change.

The accepted source-only checker may be rerun read-only. Do not rerun the owner
source verifier in place because its evidence directory is intentionally
sealed and fail-closed against overwrite.

## Secure visual QA

Only after all nonvisual gates pass:

1. Build a fresh temporary served tree outside the project containing the
   final Stage 3 HTML and the exact relative reader and source-data targets
   needed for link checks. Copy files. Do not use symlinks.
2. Confirm the served tree contains no symlink, then start one read-only static
   server bound only to `127.0.0.1` on a fresh port. Serve only that temporary
   tree.
3. Inspect the exact Stage 3 route at the available native browser size. Also
   perform deterministic narrow-layout checks at 390 CSS pixels. Record
   truthfully if the active browser API cannot emulate a separate viewport.
4. Inspect all five figures at their intended final sizes. Exercise all 16
   native table scrollers and every disclosure. Check headings, captions, alt
   text, legends, axes, labels, links, navigation within the report, clipping,
   overlap, page overflow, missing content, and console state.
5. Confirm the main and exploratory sections remain visually distinct and that
   technical provenance is contained in its intended disclosure or late
   section.
6. Record screenshots, measurements, HTTP status, console output, and server
   lifecycle under the new evidence path.
7. Close the QA tab, reset any changed viewport, stop the server, prove no
   listener or child process remains, and remove the temporary served copy.
8. Rehash the source, final HTML, semantic evidence, Stage 4 hold, complete
   protected boundary, and project inventory after QA. Require post-QA
   stability.

## Completion and stop rule

Return one combined completion record and a non-circular manifest of every new
order-50 evidence member. The manifest must exclude itself and verify every
listed hash and byte count under R 4.6.1.

If a genuine render, semantic, link, privacy, or visual defect remains, finish
all safe read-only inspection and return one consolidated defect list. Do not
patch, rerender, or open another language or cosmetic cleanup loop under this
order.

## Prohibitions and held work

No Stage 3 or Stage 4 source edit, Stage 4 render, combined render,
full-project render, model fit, prediction, inference, resampling, scientific
artifact regeneration, package or lock change, manuscript edit, shared-profile
edit, ledger change, commit, push, upload, or publication is authorized.

The mandatory next stop is independent acceptance of the harmonized Stage 3
HTML. Stage 4 remains held until that acceptance is complete and a separate
Stage 4-only order is sealed.
