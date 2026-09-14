# REPORT-018 owner order 43a: H04 companion no-rerender static and visual completion

Date: 2026-08-20

Owner: H04 worker `019febf4-4868-72f3-bd97-31a85e86f8f0`

Status: **released for no-rerender static and visual completion only**

## Authority

Order 43 completed the sole H04 companion render, semantic repair, local
manifest integration, and full preparation test. The rendered companion is
preserved at SHA-256
`e5f0861ef1b1e4accf4e6a924155c6ec5ce77a9c9865d6dc7bf5427e3de860ea`,
1,226,014 bytes. The semantic hook recorded 37 tables, 288 IDs, 1,146
`headers` associations, and 1,434 substitutions. The synchronized website QMD
matches the authoring QMD exactly, and the current preparation manifest has
276 unique live-exact rows.

Independent acceptance of the stopped state is
`audit/report_harmonization/report018_h04_order43_static_verifier_stop_independent_acceptance.md`,
SHA-256
`6133e1f628c9f1ce332cffe0abefc21a5a8f70a15c731724d1357421aa2cb964`.
Its 18-row non-circular manifest is
`audit/report_harmonization/report018_h04_order43_static_verifier_stop_acceptance_manifest.csv`.

The only stop is a temporary QA-verifier incompatibility with system Ruby
2.6.10. The verifier uses `Array#tally` and `Enumerable#filter_map`, both
unavailable in Ruby 2.6. This is not a document or scientific defect.

H04 remains the sole integration path. H05 and every later render remain held.
Do not open a language, style, optional-link, historical-test, or cosmetic
cleanup loop.

## Hard preflight pins

Require all of the following exact identities before any temporary-file
mutation:

- original static verifier:
  `/private/tmp/h04_order43_static.rb`, SHA-256
  `acbc9a68152f8099f8a303ddd0f3ff577ed77c992bf2e0bdfb357340e2934acd`,
  15,785 bytes;
- order-43 owner stop:
  `/private/tmp/H04-order43-evidence.n8aqyn/report018_h04_order43_fail_closed.md`,
  SHA-256
  `00801fe4c9096c7143170258463127ba43243484e47b7b2aacec47f198c98c56`;
- order-43 owner manifest:
  `/private/tmp/H04-order43-evidence.n8aqyn/evidence_manifest.csv`, SHA-256
  `fa0e3361676614d11d3df820495e9f75be1db3339723a7d802d1c1b0e779a5b0`;
- pre-render build inventory:
  `/private/tmp/H04-order43-evidence.n8aqyn/build_inventory_prerender.csv`,
  SHA-256
  `3451d1905a85a5a7082669c04c1c46576eb58f39d18e9bf602a48e4725da225b`;
- pre-render protected inventory:
  `/private/tmp/H04-order43-evidence.n8aqyn/protected_inventory_prerender.csv`,
  SHA-256
  `738cb332734abc045289c3dd3a6401c555d037a361a1af9b81d531255ea5963c`;
- semantic summary:
  `/private/tmp/H04-order43-semantic.9Pplpd/gt_html_semantic_post_render_summary.csv`,
  SHA-256
  `e491aee781a8a15abf9798ba4818243f790a53449a86de3676369126fc693b4e`;
- semantic ledger:
  `/private/tmp/H04-order43-semantic.9Pplpd/001__build__nathealth__audit__hypotheses__H04__H04_analysis_preparation.html_gt_semantic_ledger.csv`,
  SHA-256
  `aa1e6b1c0981cec58a9308c8198a139e48d8b01e4122eba92196552871a1a7cc`;
- fresh companion HTML:
  `_build/nathealth/audit/hypotheses/H04/H04_analysis_preparation.html`,
  SHA-256
  `e5f0861ef1b1e4accf4e6a924155c6ec5ce77a9c9865d6dc7bf5427e3de860ea`;
- accepted result HTML:
  `_build/nathealth/notebooks/hypotheses/H04.html`, SHA-256
  `da5f7f7195da843e46014d4796d35381f74d223ba79c37bb78fb8ce6dfa67c9f`;
- authoring and website companion QMDs: both SHA-256
  `efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474`,
  91,202 bytes;
- result QMD: SHA-256
  `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`;
- preparation manifest: SHA-256
  `f2d251b50e9fa61caa978d7ce155a6743f09f2667b0f827ffcbfc281b2ac706e`,
  69,857 bytes, 276 unique live-exact rows;
- unchanged helper and preparation test: SHA-256
  `108842c73bf066fc33ae9f2ba3330893c332097572b5036a55f324e6947d5de7`
  and
  `8a862e0acece4d77392647a55df4f659410fbc94e2fc6ae40b642c47c2184935`;
  and
- profile: SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

Require the original order-43 evidence and semantic directories to remain
byte-identical throughout this continuation. Preflight `_build/nathealth` for
zero symlinks. Stop before mutation on any unexpected drift.

## Exact temporary verifier correction

Create one fresh mode-0700 evidence directory under `/private/tmp`. Copy only
the two order-43 pre-render inventory CSVs into it, preserving their exact
names and bytes. Create one new temporary copy of the original static verifier.
Do not edit the original verifier or the order-43 evidence directory.

Change exactly these two Ruby-runtime constructs in the temporary copy:

1. Replace the `all_ids.tally` duplicate-ID count with a Ruby 2.6-compatible
   `each_with_object(Hash.new(0))` count, preserving the same selected
   duplicate-ID map.
2. Replace the `all_build_paths.filter_map` build-delta block with a Ruby
   2.6-compatible `each_with_object([])` block that appends exactly the same
   non-nil delta rows and preserves their order.

Change no constant, path, assertion, threshold, expected count,
classification, output name, link rule, or acceptance logic. Require an exact
two-hunk diff and a reverse proof that restoring only those two constructs
reproduces the original verifier SHA-256 and bytes. Confirm the corrected file
parses under Ruby 2.6.10.

Run the corrected verifier exactly once:

`ruby <corrected-temporary-verifier> <project-root> <fresh-evidence-directory>`

Do not run a preliminary verifier, dry run, second verifier, helper, R test,
semantic hook, or Quarto command. If the corrected verifier fails any static
gate, stop once and return the complete failure without patching or retrying.

## Required static acceptance

The single corrected run must confirm:

- exactly 37 native gt tables, four figures, and one top-down Mermaid in the
  accepted source order, with all captions and figure alt text present;
- zero document duplicate IDs, exactly 1,146 `headers` tokens resolving once
  to `th` elements inside their own tables, and zero unsupported ID refs;
- the participant-random-intercept anchor present exactly once;
- the accepted result link resolving to that anchor;
- reciprocal result and companion links, all five deviation anchors, active
  navigation, country-coded sites, source-data links, and zero unresolved
  internal reader links;
- zero embedded error, warning, or stderr nodes;
- the semantic summary matching the accepted HTML;
- authoring and website QMD byte identity;
- 276 unique live-exact preparation-manifest rows;
- zero build symlinks and every content delta classified under the existing
  order-43 contract; and
- zero unclassified protected-input drift.

## Secure-loopback visual QA

Only after the corrected static verifier passes, use the active
`$quarto-authoring` bounded loopback procedure. Start one read-only static
server rooted exactly at `_build/nathealth`, bound only to `127.0.0.1` on one
unused high or ephemeral port. Record the command, PID, address, port, root,
start time, and exact companion URL.

Inspect only
`audit/hypotheses/H04/H04_analysis_preparation.html` at 1440 by 1000, 708 by
1000, and a 200-percent-equivalent viewport. Inspect all 37 native tables, all
four figures, the top-down Mermaid, callouts, disclosures, headings, captions,
alt text, links, and navigation. HTML tables must be usable at a typical
desktop or laptop width. Narrow tables may use contained horizontal scrolling.
Stored PNGs control exported final-size figure acceptance. Check typography,
labels, legends, axes, wrapping, clipping, overlap, and page overflow.

Stop the server immediately after QA. Prove no listener remains, reset the
viewport, close QA tabs, and prove post-QA source, profile, protected, and
complete build stability against the corrected verifier outputs.

## Return and prohibitions

Return one no-rerender companion acceptance package or one consolidated new
static or visual defect list. Preserve the corrected temporary verifier, exact
diff and reverse evidence, static outputs, screenshots, server lifecycle, and
one non-circular evidence manifest until independent acceptance.

No render, source or HTML edit, helper execution, R test execution, scientific
computation, artifact regeneration, profile, package, lockfile, ledger,
manuscript, broad-manifest, commit, push, upload, deletion, publication, or
later-target action is authorized.
