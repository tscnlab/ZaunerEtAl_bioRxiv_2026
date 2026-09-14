# REPORT-017 / REPORT-018 order 33g: H02 result no-rerender completion

Date: 2026-08-20

Owner: H02 task `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Status: **AUTHORIZED ONCE**

This is the sole final cleanup exception under REPORT-018. It completes the
already rendered H02 result page without running Quarto. After independent
acceptance, no new cleanup loop may open. The shared sequence moves directly
to reader-page render completion.

## Controlling authority

- REPORT-018 decision:
  `audit/decisions/report_harmonization_render_completion_priority.md`,
  SHA-256
  `0cb7c62806b40c1702c7fdde994d98090f0fc820abfa32205a8e58e392681ecf`;
- scheduling addendum:
  `audit/report_harmonization/report017_render_completion_scheduling_override.md`,
  SHA-256
  `117dfedc650dc035b74978a7621cac8ef7bf14c8caf4533d0a94f7fecb1b52e0`;
- stopped-state acceptance:
  `audit/report_harmonization/report017_h02_order33f_stopped_independent_acceptance.md`,
  SHA-256
  `835a74d5a42204324a6e34e467b842b8b455c86342d58008a48ad9684aa5cb3c`;
- complete reader-contract audit:
  `audit/report_harmonization/report017_h02_order33f_reader_contract_audit.csv`,
  SHA-256
  `23285479db1ac83b0c83569ef2ce80906e8bb9232be847ebb21e3f7e34a20db9`;
- 18-row stopped acceptance manifest, SHA-256
  `1bf2e52d158a2cdf14a8bd05311fb660c9f3d5e525b3437dc589aacec155a2cc`.

## Hard preflight

Reproduce every row in the dispatch manifest before mutation. In particular:

- result QMD:
  `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`;
- held companion QMD:
  `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`;
- current reader test:
  `0b044d2995645f6cfa50e28e2bdf330b8801002761a84520b169a1a3eb6771db`,
  16,044 bytes;
- paired-placement test:
  `873c43f0d863c78c22e3e0635d054f09bc521a24d618afcda134a831ac7e7d8a`;
- preserved and unexecuted preparation test:
  `ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`;
- fresh result HTML:
  `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`,
  296,427 bytes;
- held companion HTML:
  `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

Stop before mutation on any unexplained owner-scoped drift. The REPORT-018
central decision and ledger additions are the accepted pre-dispatch baseline,
not H02 drift.

## Exact authorized test edit

Edit only `tests/hypotheses/H02/test_h02_reader_report.R`. Apply the complete
pre-audited set in one pass:

1. Add only `_build/nathealth/notebooks/hypotheses/H02.html` to the expected
   preparation-manifest mismatch set.
2. Add only that same path to the expected worker-manifest mismatch set.
3. Replace only the stale result-HTML SHA-256 with
   `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`.
4. Require the exact rendered phrase
   `false-discovery-rate (FDR)-adjusted p = <0.001`.
5. Replace only the four stale `diagnostic p` literals with `check p` at
   0.435, 0.455, 0.130, and 0.115.
6. Replace the arbitrary 160-character caption ceiling with structural checks
   that require exactly one nonempty caption for each of the 15 accepted table
   endpoints and five accepted figure endpoints.

The expected post-edit test is SHA-256
`479a702e7c5c52cf85e8591300a30c759da945f4c65ecb28cad67bb2e6752d3f`,
16,545 bytes. Require an exact bounded diff and reverse substitution to the
pre-edit SHA-256 and byte count. Preserve every other test byte and gate.

Create new completion evidence only under
`audit/hypotheses/H02/report017_order33g_result_completion/`. Do not rewrite
any order-33f evidence or historical manifest.

## Exact nonvisual verification

Use R 4.6.1. Run only these two project tests:

```text
Rscript --vanilla tests/hypotheses/H02/test_h02_reader_report.R
Rscript --vanilla tests/hypotheses/H02/test_h02_paired_placement_display.R
```

Both must exit 0. Do not execute
`tests/hypotheses/H02/test_h02_preparation_report.R` in any mode. Preserve it
byte-identical and cite its accepted pre-render source-only PASS. Its next
execution belongs to the later H02 companion render.

Independently rerun or verify against the unchanged fresh result HTML:

- the retained semantic ledger reverses the final HTML to pre-hook SHA-256
  `9c3d2c9fe062756cd2a3454522bf440cc12153999621557a61eb19fa073a8e84`;
- normalized DOM and visible text are identical across the semantic repair;
- exactly 15 native gt tables and five figure endpoints occur in accepted
  order;
- document IDs are unique, all 530 table-header references resolve, and all
  552 document ID references resolve;
- 22 preregistration links resolve to 18 unique accepted anchors;
- all nine country-coded site labels pass;
- captions, alt text, source-data links, image files, navigation, disclosures,
  endpoint order, and no-error or warning checks pass;
- all 210 protected identities remain exact;
- the order-33f post-render and post-QA build inventories remain identical;
- no source, profile, HTML, artifact, or build member changes during this
  no-rerender completion.

For reader links, classify by scheme and origin first. Require every internal
reader link to resolve except exactly this accepted shared hold:

```text
../../supplementary_information.html
```

Require exactly one unresolved row with that href and link label
`Supplementary information`. This is DOC-001, not an H02 defect. Fail on any
second unresolved link, different href, forbidden local target, unsupported
scheme, or unresolved fragment. External HTTPS links are not internal-link
defects.

Record the held companion state without changing it. The preparation manifest
has exactly four expected current mismatches: the accepted companion QMD,
result QMD, profile, and fresh result HTML. The stale build-side companion QMD
and these four classifications are deferred to the later companion render.

## Secure loopback visual QA

Use the active `$quarto-authoring` bounded local-inspection procedure. Do not
render or use `quarto preview`.

1. Rehash source, profile, result HTML, held companion, and the scoped build
   inventory.
2. Preflight `_build/nathealth` for symlinks. Stop if any symlink resolves
   outside that root.
3. Start one read-only static HTTP server rooted exactly at
   `_build/nathealth`, bound only to `127.0.0.1` on one unused high or
   operating-system-selected port. Record command, PID, address, port,
   document root, start time, and exact H02 URL.
4. Navigate only to the exact H02 result route in the in-app Browser.
5. Inspect at 1440 x 1000 and 708 x 1000, plus 200-percent-equivalent and
   intended final-display sizes. Inspect all five figures, all 15 native
   tables, the principal figure and table, captions, alt text, axes, labels,
   legends, symbols, panels, disclosures, navigation, links, wrapping,
   clipping, overlap, and page overflow.
6. Apply the accepted table policy. HTML tables must be usable at ordinary
   desktop and laptop widths. Narrow tables may use a contained, usable
   horizontal scroller without breaking the page. For exported figures, the
   stored PNG presentation at its intended output size is the controlling
   final-size check.
7. Stop the server immediately after QA. Prove process exit and no remaining
   listener on the port. Reset the viewport and rehash all preflight
   identities and the complete scoped build inventory.

Stop once with one consolidated return only for a genuinely new
render-blocking, semantic, link, protection, or visual defect. Do not patch or
rerender.

## Completion seal

Return one combined completion record, exact test transition evidence,
nonvisual checks, visual-QA measurements and screenshots, loopback lifecycle,
post-QA stability evidence, and a unique non-circular manifest. State the
exact R version and commands. Preserve the retained external semantic audit
directory until independent acceptance.

## Prohibitions

No QMD, HTML, profile, source data, scientific artifact, historical manifest,
shared page, package, lockfile, manuscript, central ledger, or configuration
edit. No Quarto command, model fit or refit, prediction, bootstrap,
simulation, resampling, Shapley or dominance recomputation, broad builder,
companion integration, commit, push, upload, or publication.

After independent H02 result acceptance, stop. The next shared target is
`supplementary_information.qmd`, followed by the H02 companion under a
separate REPORT-018 order.
