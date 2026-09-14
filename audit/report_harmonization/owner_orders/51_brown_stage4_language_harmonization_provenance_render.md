# REPORT-018 order 51: Brown Stage 4 language-harmonization provenance render

Date: 2026-08-21

Owner: `019fffdf-66d4-7802-9091-09283ad27b7f`

Owner worktree:
`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`

Status: **SEALED FOR EXACTLY ONE STAGE 4-ONLY RENDER**

The accepted Stage 3 page is immutable. This order does not authorize a new
language, scientific, or cosmetic pass.

## Controlling authority

The exact Stage 4 render authority is:

- `audit/decisions/brown_adherence_stage4_language_harmonization_render_release.md`;
- SHA-256
  `49c7a516100bc52b5b091de02e4245c8fe35fb2c74b31cf17ba5e9253d7387d2`;
- 7,973 bytes.

Its verification, checker, and non-circular manifest are:

- verification SHA-256
  `9bca270750d67b5de6378042f2e91bf557088c50c4c77aa796910f5b016920ad`;
- checker SHA-256
  `ec457f0f1cc33cfe632123a7b62fa18fcfd0c807bdc87bf06a2554e9f4c78d23`;
- 22-row release manifest SHA-256
  `5bf548f34753299db4d1dc6b5f99c14653699fba2cf6d72014a9db310263c39b`.

The Stage 3 independent acceptance is exact at SHA-256
`cc5f751f7f86ce2ec1cd930f60bea19cca8e6bdfd2b33113c978694a6357a7be`,
with 26-row non-circular manifest SHA-256
`7305e781e788376c326ef7894648bb2d90ba702056d4a5443abb6c9bb07bcc8a`.

Reproduce the order-51 dispatch manifest completely before any write or
process start. Stop without mutation on any drift.

## Immutable render pins

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Accepted Stage 3 QMD | 55,426 | `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43` |
| Accepted Stage 3 HTML | 4,825,090 | `3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d` |
| Harmonized Stage 4 QMD | 24,416 | `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475` |
| Historical semantic Stage 4 HTML | 4,340,432 | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| Owner 19-row paired source seal | 3,659 | `bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46` |
| Historical 113-member Stage 4 manifest | 54,203 | `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2` |
| Historical Stage 4 verification | 29,804 | `60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38` |
| Stage 3 owner 80-member manifest | 16,282 | `37b728618d875a16939c382c243dea7ff29d8dc72fd945ac16a16082c755e8f4` |
| Brown `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |
| Accepted semantic engine | 17,747 | `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1` |

The historical Stage 4 manifest remains immutable. Before rendering it must
have exactly one live transition: its historical Stage 4 QMD identity
`642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29`
at 24,147 bytes to the accepted harmonized QMD above. Its other 112 members
must be live-exact. After rendering, classify the fresh HTML transition
separately without editing the historical manifest.

## Authorized writes

Only these project paths may change or be created:

1. the canonical Stage 4 HTML:
   `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html`;
2. new, non-circular order-51 render, semantic, verification, link, privacy,
   responsive, visual-QA, lifecycle, and acceptance evidence under:
   `audit/analyses/brown_adherence/language_harmonization/stage4_render/`.

The Stage 4 QMD is an immutable input. The accepted Stage 3 QMD and HTML,
existing Stage 3 and Stage 4 evidence, source data, figures, table sources,
models, manifests, handoffs, author gates, packages, and lockfile are
immutable.

## Preflight and inventories

Before the render:

1. Verify R 4.6.1, Quarto 1.9.37, the accepted library path, and every dispatch
   pin.
2. Confirm no Quarto, Pandoc, Brown render, semantic-repair, or loopback
   process is active for this worktree.
3. Reverify the Stage 3 acceptance manifest 26/26, paired source manifest
   19/19, all 34 language actions, all 41 protected scientific tokens, and the
   historical Stage 4 manifest as exactly 112 live-exact plus the one accepted
   QMD transition.
4. Require 18 parsed R chunks, 17 unique native-table endpoints, one top-down
   Mermaid endpoint, and three relative links to the accepted Stage 3 result
   source and anchors.
5. Create complete SHA-256 and byte inventories of the Brown source,
   scientific, display, manifest, HTML, package, and lockfile boundaries.
   Record symlinks separately and fail on any unexpected symlink.
6. Create a fresh evidence directory under the authorized Stage 4 render path
   and preserve a byte-identical copy of the historical Stage 4 HTML before
   replacement.

## Sole render command

From the isolated Brown worktree, execute exactly once:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
BROWN_ADHERENCE_PROJECT_ROOT=/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 \
BROWN_ADHERENCE_AUTHOR_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
quarto render audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd --to html
```

Do not add a profile, `--no-execute`, another target, or another environment
override. Do not restore, install, update, or bypass the accepted library. If
startup fails before QMD execution, stop once with complete environment
evidence. Do not retry.

## Raw render and candidate-first semantic repair

After a successful render:

1. Require exit zero and preserve the raw rendered HTML byte-for-byte before
   semantic mutation.
2. Work only on temporary candidate bytes. The fresh raw HTML may contain the
   historically documented entity-encoded at-least-80-percent generated ID
   and its three matching `headers` references. If present, normalize only
   that exact generated `id` value and those exact three `headers` values,
   with a reversible byte ledger.
3. Invoke the unchanged accepted semantic engine with exactly the raw or
   reversibly normalized input, candidate output, and engine-ledger paths. It
   may change only native-`gt` `id` and `headers` values.
4. Require the composed ledgers to reverse the candidate exactly to the fresh
   raw HTML. Also require identical visible text and normalized DOM, unchanged
   rows, cells, headers, captions, notes, links, CSS, element order, and every
   other attribute and node.
5. Promote the candidate to the canonical Stage 4 HTML exactly once only
   after all candidate checks pass. On any defect, stop without another render
   or source patch.

## Complete source and page acceptance

Create and run one bounded R 4.6.1 verifier under the new evidence path. It
must fail closed and prove all of the following:

1. Exactly one `main#quarto-document-content`, 17 native `gt` tables, and one
   top-down Mermaid diagram occur in accepted source order.
2. Document IDs are unique. Every explicit `headers` token and supported
   internal ID reference resolves exactly once to its intended element.
3. The composed semantic reversal reproduces the fresh raw HTML byte-for-byte.
4. The source retains 18 R chunks, 17 unique table endpoints, one Mermaid
   endpoint, and the complete accepted executable core.
5. All three reciprocal links to the accepted Stage 3 source and exact anchors
   resolve. Every reader, implementation, and source-data target remains
   relative, non-identifying, and available. Reject `.html`, absolute,
   `file:`, worktree-local, and build paths in source.
6. All 34 language actions, 41 protected scientific tokens, accepted formulas,
   estimates, intervals, p-values, multiplicity and FDR decisions,
   diagnostics, R-squared and Shapley values, privacy exclusions, and
   limitations remain exact.
7. The main-versus-exploratory hierarchy, withheld day-level claim,
   non-causal participant-level interpretation, chest context, provenance
   boundaries, captions, country-coded sites, and shared vocabulary remain
   intact.
8. The accepted Stage 3 QMD and HTML, all historical manifests and repair
   evidence, all scientific and display artifacts, and `renv.lock` remain
   exact.
9. The HTML contains no embedded execution error, unresolved cross-reference,
   broken resource, duplicate endpoint, or page-attributable console error.
10. The post-render project delta contains only the authorized Stage 4 HTML
    transition and new order-51 evidence.

The sealed source-only verifier must not be rerun in place if it would mutate
its accepted evidence. Reuse its records read-only or run a bounded new
checker under the order-51 evidence path.

## Secure visual QA

Only after all nonvisual gates pass:

1. Build a fresh temporary served tree outside the project containing the
   final Stage 4 HTML and the exact relative targets needed for link checks.
   Copy files and prohibit symlinks.
2. Start one read-only static server bound only to `127.0.0.1` on a fresh
   port. Serve only the temporary tree.
3. Inspect the exact Stage 4 route at the available native browser size and
   perform deterministic responsive checks at 390 CSS pixels. Record any
   browser viewport limitation truthfully.
4. Exercise all 17 table scrollers, the Mermaid diagram, disclosures,
   headings, captions, source links, navigation, and final provenance
   sections. Check clipping, overlap, page overflow, missing content,
   legibility, and console state.
5. Close the QA tab, reset any changed viewport, stop the server, prove no
   listener or child process remains, and remove the temporary served tree.
6. Rehash source, final HTML, semantic evidence, accepted Stage 3, protected
   boundary, and project inventory after QA. Require complete post-QA
   stability.

## Completion and stop rule

Return one combined completion record and a non-circular manifest of every new
order-51 evidence member. The manifest must exclude itself and verify every
listed hash and byte count under R 4.6.1.

If a genuine render, semantic, link, privacy, or visual defect remains, finish
all safe read-only inspection and return one consolidated defect list. Do not
patch, rerender, or open another language or cosmetic cleanup loop under this
order.

## Prohibitions and next stop

No Stage 3 render or edit, Stage 4 source edit, combined render, full-project
render, model fit, prediction, inference, resampling, scientific artifact
regeneration, package or lock change, manuscript edit, commit, push, upload,
or publication is authorized.

The mandatory next stop is independent acceptance of the harmonized Stage 4
HTML package.
