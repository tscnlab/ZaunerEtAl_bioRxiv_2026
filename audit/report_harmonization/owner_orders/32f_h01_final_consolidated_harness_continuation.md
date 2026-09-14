# REPORT-017 order 32f: H01 final consolidated harness continuation

Date: 2026-08-15

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released as one final continuation. Do not split it. The H01
companion and every later REPORT-017 target remain held.**

## Authority and current stopped state

The controlling parent work is order 32d plus continuation 32e. The accepted
order-32e stop is:

- independent acceptance
  `audit/report_harmonization/report017_h01_order32e_stopped_state_independent_acceptance.md`,
  SHA-256
  `ac511cc9676d8568096300e4684f3fd1a9e47e7621349eed33a78d69969da693`;
- 41-row independent seal
  `audit/report_harmonization/report017_h01_order32e_stopped_state_independent_manifest.csv`,
  SHA-256
  `59f31326da6e7166a85eed37a1b26a0b5d9d5fb7eb67373dde9c7abcfa8f8be8`;
- current refresh implementation
  `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`, SHA-256
  `999637d9d84ec3544db95d423b6c363d4d0c4ccfe588a76139bf6062e674638f`;
  and
- stopped coordination state
  `audit/report_harmonization/coordination_matrix.csv`, dispatch-time SHA-256
  `862ec88ff79dfb8a45ba8158b15135170dab4cdeca38d65be3270fc4c41cfaa9`.

The matrix identity is coordination evidence, not a mutable owner execution
pin. Hard-pin the owner-scoped files and stable shared inputs in the order-32f
dispatch seal.

Before mutation, require all 41 stopped-state rows exact. In particular,
require the accepted result QMD, frozen companion QMD, stopped result HTML,
frozen companion HTML, builder, profile, six durable figures, three frozen
display-source CSVs, semantic hook, tests, manifests, and owner handoff at
their current sealed identities.

Require all 12 stopped candidate files at
`/private/tmp/H01-order32e-candidates.hltKEs` to remain exact. Require all
three recovery files at `/private/tmp/H01-order32d-quarantine.Xc28uF` to
remain exact, regular, and nonsymlink files, with their original duplicate
paths absent. Require the old order-32d failed candidate directory to remain
empty. Stop before mutation on any drift.

## Part A: three exact harness corrections

Change only `scripts/hypotheses/H01/refresh_h01_order32d_figures.R` in this
part.

### A1. Output-inventory path selection

Inside `path_rows()`, replace the data-mask-dependent indexing with a distinct
closure scalar and a vector selected before `tibble()`:

1. use a scalar such as `current_figure_id` as the `lapply()` argument;
2. bind `current_paths <- paths[[current_figure_id]]` before calling
   `tibble()`; and
3. derive `figure_id`, `format`, `path`, SHA-256, and bytes only from
   `current_figure_id` and `current_paths`.

Do not evaluate `paths[[figure_id]]` inside `tibble()` and do not rely on tidy
data-mask lookup. Do not change any plot, file path, hash function, or output
inventory field.

### A2. SVG `textLength` parsing

Inside `label_boxes()`:

1. collect the raw `textLength` attributes;
2. require every value to match numeric-plus-terminal-`px` exactly, using a
   fail-closed pattern equivalent to `^[0-9]+(?:\.[0-9]+)?px$` with
   `perl = TRUE`;
3. strip only the terminal `px`;
4. convert to numeric; and
5. stop before box calculations on a missing, duplicate, malformed, or
   nonfinite width.

Retain the existing exact-label set check and collision clearance. Do not
change any label, font, point, segment, or collision threshold.

### A3. Figure 1 baseline-provenance classifier

Add one bounded, fail-closed Figure 1 baseline classifier with two distinct
comparisons.

First, compare the sealed Figure 1 to the full source-derived baseline. It must
match all of these values exactly:

- full source-derived baseline PNG SHA-256
  `2e3b1ddb7954584a70ff9d434cc862f9d1769dc45be607d2ca34840cbc9c1760`;
- full source-derived baseline SVG SHA-256
  `12e4cf421a844da11844444e41601dec5e559e28b4ad77ac0081bd9ef2cfddcd`;
- sealed PNG SHA-256
  `2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b`;
- sealed SVG SHA-256
  `602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966`;
- exactly 9,477 changed pixels;
- one-based raster bounds exactly x = 1927 to 2496 and y = 2256 to 2325;
- exactly SVG lines 366, 367, 368, and 369 of 372; and
- those four lines must contain only the documented three-point horizontal
  shift of the two legend keys and their two labels.

No other changed pixel, line, element, style, text, or value may be admitted
under this transition. Do not normalize, splice, or rewrite the sealed Figure
1 before candidate acceptance.

Second, compare the Figure 1 candidate to the full source-derived baseline.
Permit only the previously authorized text and status-symbol sizing changes.
Preserve all 136 source rows, keys, tiles, statuses, symbols, facets, colours,
labels, order, dimensions, and DPI.

Figures 5 and 6 retain exact source-derived-to-sealed PNG/SVG baseline
requirements. Figure 5 candidate differences remain restricted to the
authorized deterministic direct-label layout. Figure 6 candidate differences
remain restricted to the authorized text and status-symbol sizing.

### A4. Formatting and exact source evidence

Run Air 0.4.1 formatting only on the refresh implementation. Record the
pre-change, post-correction/pre-Air, and post-Air identities. Require:

- R 4.6.1 parsing before and after;
- AST equality before and after Air;
- an exact diff proving only A1 through A3 plus Air layout changed; and
- `air format --check` PASS.

Do not format or edit another file.

## Part B: one non-mutating R 4.6.1 preflight

Before creating a fresh candidate directory, run one complete non-mutating
preflight that exercises all three corrected contracts together:

1. call the corrected `path_rows()` logic on a synthetic named list containing
   at least two figures and two formats per figure; require exact rows, paths,
   hashes, bytes, and no data-mask collision;
2. parse the stopped Figure 5 candidate SVG and require all 30 expected labels
   exactly once, all 30 raw `textLength` attributes matching the terminal-`px`
   contract, all converted widths finite, and zero label collisions;
3. reproduce the exact sealed-to-full-baseline Figure 1 9,477-pixel,
   four-line transition and exact baseline hashes;
4. reproduce the exact Figure 5 and Figure 6 baseline PNG/SVG hashes;
5. recheck the two observed-category sets, broader unused plotting levels,
   all 30 matched-sample flags, row counts, source keys, source hashes,
   quarantine identities, empty old failed directory, and the two relative
   path bases; and
6. prove that `/private/tmp/H01-order32e-candidates.hltKEs` remains byte-exact
   and untouched.

The preflight may not create a candidate, replace an artifact, or edit a
project file. If it fails, complete the safely executable checks and return
one stopped state without patching or retrying.

## Part C: complete candidate and artifact package

Only after Part B passes, create one fresh candidate directory under
`/private/tmp`. Do not reuse or modify either earlier candidate directory.

Resume every accepted order-32d/32e candidate and validation requirement:

- construct all three candidates only from the three exact frozen display
  CSVs and the minimum accepted display registries/constants;
- reproduce the full source-derived baselines and apply the classifier in
  Part A3;
- retain the authorized Figure 5 direct-label layout only;
- retain the authorized Figure 1 and Figure 6 text/status-symbol sizing only;
- require at least 7 pt text at the accepted 708-pixel final display;
- require all 30 paired labels once and zero label collisions using the
  corrected parser;
- require exact source-row, key, value, mapped-aesthetic, layer, label, tile,
  status, symbol, facet, scale, order, dimension, DPI, and normalized-SVG
  checks;
- inspect original size, intended final size, 1440 pixels, 708 pixels, and
  200 percent; and
- replace the six durable PNG/SVG targets once only after the complete set
  passes.

Update only the already authorized display literals in the accepted builder.
Do not run the full builder. Use the corrected evidence semantic checker.
Reseal only directly dependent current manifest, test, and bounded evidence
rows from leaves upward. Preserve every historical record and prior stopped
state byte-for-byte.

Run the complete display, reporting, REPORT-016, semantic, manifest,
protected-inventory, source-data, parsing, Air, and scoped diff checks. Finish
the complete safely executable check set before stopping on any failure.

## Part D: exactly one result render and complete QA

Only after Parts A through C pass, create fresh pre-render inventories and run
exactly once:

```sh
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

Use normal R 4.6.1 project startup and only the established narrow access to
the user-owned renv cache if required. Do not bypass the profile or semantic
hook and do not use `--no-execute`.

Complete the full native-gt, endpoint-order, semantic-ID, link,
deviation-anchor, source-data, navigation, country-code, error-node,
protected-science, and build-delta checks. Require 36 native gt tables, ten
figures, all 40 links to 36 deviation anchors, and no duplicate or dangling
semantic ID. The three quarantined duplicate paths must not reappear.

Run one secure read-only loopback server rooted exactly at
`_build/nathealth`, bound only to `127.0.0.1`. Inspect the complete H01 result
page at 1440 by 1000 and 708 by 1000, all ten figures at final display size,
Figures 1, 5, and 6 at intended final size and 200 percent, and the principal
table at desktop, narrow, and 200 percent. Apply the accepted contained
narrow-scroller table policy. Stop the server, prove no listener remains, and
prove no post-QA drift.

Return one non-circular evidence manifest and either one complete accepted
result or one complete stopped-state defect list.

## Prohibited work

Do not fit, refit, infer, predict, simulate, bootstrap, resample, rerun Shapley,
change source data, run the full builder, alter a scientific table or claim,
edit either QMD, render the companion or a later target, change the profile,
ledger, package, or lockfile, delete any stopped candidate or recovery file,
commit, push, upload, or run a full-project render.

The H01 companion and every later REPORT-017 target remain held pending
independent acceptance of this one continuation.
