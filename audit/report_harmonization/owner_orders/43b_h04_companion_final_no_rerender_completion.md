# REPORT-018 owner order 43b: H04 companion final no-rerender completion

Date: 2026-08-20

Owner: H04 worker `019febf4-4868-72f3-bd97-31a85e86f8f0`

Status: **released for one corrected static run and visual QA only**

## Authority and count classification

The H04 companion was rendered exactly once under order 43 and remains
preserved at SHA-256
`e5f0861ef1b1e4accf4e6a924155c6ec5ce77a9c9865d6dc7bf5427e3de860ea`,
1,226,014 bytes. Its semantic hook, helper integration, 276-row preparation
manifest, and full preparation test passed.

Order 43a corrected only the two Ruby 2.6 compatibility constructs and then
stopped on a count-definition mismatch. Independent acceptance is
`audit/report_harmonization/report018_h04_order43a_header_count_stop_independent_acceptance.md`,
SHA-256
`42251c04f29edd4f994ae487fd2686de1081f84433cf6e28d7d21c7e91d4f020`.
The structured count audit is SHA-256
`6b72f66c90a78a25559968e578c563b3479525512e7f6222e6ac8fecfa75c48f`.

The semantic hook records 1,146 `headers` attribute mutations. The final DOM
contains those 1,146 attributes and 1,968 whitespace-separated header-ID
tokens. All 1,968 tokens resolve exactly once to a `th` inside their own native
gt table. The verifier's `header_tokens == 1146` assertion is therefore a
checker count-definition error, not a semantic or accessibility defect.

H04 remains the sole integration path. H05 and every later render remain held.

## Hard preflight

Require the full order-43b dispatch manifest exact. In particular, preserve:

- the order-43a evidence directory
  `/private/tmp/H04-order43a-evidence.ik3RcV` and its eight-entry
  non-circular manifest;
- the accepted Ruby 2.6 verifier at SHA-256
  `1280d1f6b0bd2298cf439e71656050c8ce9c2d81b9efda93694899c19ee27256`,
  15,870 bytes;
- the original order-43 evidence and semantic directories;
- both pre-render inventories;
- companion and result HTML identities
  `e5f0861ef1b1e4accf4e6a924155c6ec5ce77a9c9865d6dc7bf5427e3de860ea`
  and
  `da5f7f7195da843e46014d4796d35381f74d223ba79c37bb78fb8ce6dfa67c9f`;
- result and companion QMD identities
  `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`
  and
  `efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474`;
- the source-identical website companion QMD;
- the 276-row live-exact preparation manifest at
  `f2d251b50e9fa61caa978d7ce155a6743f09f2667b0f827ffcbfc281b2ac706e`;
  and
- profile SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

Require zero build symlinks. Stop before mutation on any unexpected drift.

## Exact final verifier classification

Create one fresh mode-0700 evidence directory under `/private/tmp`. Copy the
two order-43 pre-render inventory CSVs into it byte-for-byte. Create one new
temporary copy of the accepted order-43a Ruby 2.6 verifier. Preserve every
earlier verifier and evidence file.

Make exactly these three output/checker substitutions in the new temporary
copy:

1. At the `headers token count` assertion, change only the required token
   count from `1146` to `1968`.
2. In the `static_acceptance_summary.csv` `headers_tokens` row, change only
   the required value from `1146` to `1968`.
3. In the final `static PASS` status text, replace the ambiguous
   `headers=1146` with
   `header_attributes=1146 header_tokens=1968`.

The separate `semantic headers` assertion must continue to require exactly
1,146. Change no path, classification, selector, resolution rule, accepted
count, output filename, or other assertion. Require an exact diff and reverse
proof to the order-43a verifier, then confirm Ruby 2.6.10 syntax.

Run the final corrected verifier exactly once:

`ruby <final-temporary-verifier> <project-root> <fresh-evidence-directory>`

Do not run any preliminary verifier, helper, R test, semantic hook, or Quarto
command. Stop once without patching or retrying if any assertion fails.

## Required static and visual acceptance

The one verifier run must pass the complete order-43 static contract: 37 native
gt tables, four figures, one top-down Mermaid, source order, captions, alt
text, zero duplicate IDs, 1,146 header attributes, 1,968 resolving header-ID
tokens, zero unsupported ID references, the participant-random-intercept
anchor and reciprocal links, five deviation anchors, source-data links, active
navigation, all nine country-coded sites, zero embedded problem nodes, 276
live-exact manifest rows, classified build deltas, zero unclassified protected
drift, and zero symlinks.

Only after that pass, use the active `$quarto-authoring` bounded loopback
procedure. Serve exactly `_build/nathealth` read-only on `127.0.0.1`, and
inspect only the H04 companion route at 1440 by 1000, 708 by 1000, and a
200-percent-equivalent viewport. Inspect all 37 tables, four figures, the
top-down Mermaid, callouts, disclosures, headings, captions, alt text, links,
and navigation. Apply the accepted desktop-first and contained narrow-scroll
table policy. Stored PNGs control exported final-size figure acceptance.

Stop the server, prove no listener remains, reset the viewport, close QA tabs,
and prove post-QA source, profile, protected, and complete build stability.

## Return and prohibitions

Return one final H04 companion acceptance package or one consolidated genuinely
new defect. Preserve the final temporary verifier, exact diff and reverse
proof, static outputs, screenshots, server lifecycle, and a non-circular
evidence manifest through independent acceptance.

No render, source or HTML edit, helper or R test execution, scientific
computation, artifact regeneration, profile, package, lockfile, ledger,
manuscript, broad-manifest, commit, push, upload, deletion, publication, or
later-target action is authorized.
