# REPORT-017 owner order 28: Preparation 07 Mermaid TB repair and repeat render

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Target source: `notebooks/preparation/07_example_days.qmd`

Target output: `_build/nathealth/notebooks/preparation/07_example_days.html`

## Authority and accepted starting state

The coordinator approved `RH-VIS-002` as a bounded display-only repair after
independently reproducing the stopped-render evidence. The accepted starting
identities are:

| Path | SHA-256 |
|---|---|
| `notebooks/preparation/07_example_days.qmd` | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` |
| `tests/test_preparation07_report.R` | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| stopped HTML | `9c05cd46796d853dad10e5f3058231946f0c1df3a4678d6272d6aa8141fe47db` |
| owner stopped-render record | `aea0899ecfc8c5325b4015f7f2e2c6c282928f7e4b1067852a265cb3004bed13` |
| owner 45-entry manifest | `88c1bbf4159caec07c0b60359bbd5aa241cf21dbae811c7efe6d0ec2f0066c0b` |
| independent stopped-render acceptance | `37d0584c98ed9f9ec28c0ff8f7a423b83222f9a3578c98e791c77a88d4647219` |
| independent 15-entry acceptance manifest | `485f3310df55fa9a7d1d876838c94de07b5fbfee02ed071658469c69e7bb3c3c` |

The owner manifest has been independently verified at 45/45 entries and the
independent acceptance manifest at 15/15 entries. The protected inventories
are byte-identical before render, after render, and after browser QA. The sole
failure is the unchanged LR Mermaid, whose eight important labels retain
9.001 pt at 1,440 pixels but only 5.031 pt at 708 pixels. Seven native HTML
tables retain at least 8.25 pt and are not part of the defect.

## Exact authorized source repair

After rechecking every starting identity, edit only line 664 of
`notebooks/preparation/07_example_days.qmd`:

```diff
-flowchart LR
+flowchart TB
```

Preserve every node, edge, label, caption, alt text, surrounding prose,
scientific statement, code chunk, table endpoint, figure endpoint, source-data
link, artifact reference, test, configuration file, and scientific identity.
Do not make any other source or test change.

Before rendering, prove that replacing only the new `flowchart TB` token with
`flowchart LR` reconstructs the accepted source SHA-256
`ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae`.
Run `git diff --check` on the target source and confirm that the exact source
delta is one removed line and one added line.

## Single render boundary

Recheck the repaired source identity, unchanged focused test, unchanged
profile, all 38 protected paths, and build-root symlink preflight. Stop on any
unexplained drift.

Run exactly one command with the established narrowly elevated access to the
existing user-owned renv cache:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
```

Use normal `.Rprofile` and `renv/activate.R` startup. Do not bypass the project
profile, install or update packages, edit `renv.lock`, run another target,
render the full project, or execute any builder, strict showcase verifier,
selection routine, model, prediction, resampling, simulation, or artifact
regeneration workflow.

## Required post-render verification

Repeat the complete order 27 contract:

1. Run the focused Preparation 07 source/HTML test under R 4.6.1.
2. Confirm all protected identities except the single authorized QMD token are
   exact, including the fixed selection, historical manifest, current
   site-context inputs, provenance-equivalence seal, durable PNG, durable SVG,
   paired source-data CSV, test, profile, and `renv.lock`.
3. Verify exactly seven native `gt` table endpoints, each with one
   Quarto-owned caption, substantive headers and rows, and its intended source
   note.
4. Verify all three example-day figures, captions, alt text, source-data link,
   country-coded sites, approved historical/current provenance wording,
   internal links, navigation, active sidebar state, and absence of rendered
   warnings, errors, unresolved cross-references, or internal workflow terms.
5. Confirm the durable PNG and SVG remain byte-identical. Any generated HTML
   figure files must retain their accepted scientific/display content.
6. Inventory the exact target-owned build delta. Do not infer that the known
   unreleased `supplementary_information.html` navigation target is a defect.

## Secure loopback visual QA

After the nonvisual checks pass, start one temporary read-only HTTP server
whose document root is exactly `_build/nathealth`, bound only to `127.0.0.1`
on an unused high or OS-selected port. Navigate only to the exact Preparation
07 route in the supported in-app Browser.

Inspect at 1,440 by 1,000 pixels and 708 by 1,000 pixels:

- overall typography, headings, callouts, navigation, wrapping, clipping, and
  page-level overflow;
- the repaired TB Mermaid, including every label, edge, clipping, overlap,
  harmful vertical expansion, and a minimum important-label size of 7 pt;
- all seven native HTML tables, which must be reasonably usable at desktop;
  at 708 pixels a contained, usable horizontal scroller is acceptable, but
  page-level overflow, clipped content, or unusably small table text is not;
- all three figures at final displayed size, including traces, points, axes,
  daylight context, legends, captions, alt text, and units.

The table visual gate applies to the HTML tables on typical screens. Any
exported table PNG would instead be checked at its intended export size, but
Preparation 07 has no exported table PNG in this order.

Stop immediately on any remaining or new defect. Do not infer or repair it.
Stop the loopback server immediately after QA, record its command, PID,
address, port, document root, target URL, start and stop evidence, and verify
that no listener remains.

## Return evidence

Return:

- repaired source pre/post SHA-256 identities and exact reverse-substitution
  proof;
- target HTML SHA-256 and byte count;
- exact render command, Quarto/R/package versions, runtime, and exit status;
- focused test, semantic, native-table, figure/source-data, navigation/link,
  country-code, no-error, and protected-identity results;
- desktop and 708-pixel screenshots and measured Mermaid/table typography;
- loopback lifecycle and teardown evidence;
- target build delta and post-QA inventory evidence; and
- a non-circular manifest covering the controlling order and returned
  evidence.

No hypothesis render is released by this order. Every hypothesis target
remains held until the repaired Preparation 07 page is independently accepted
and the coordinator separately releases the next serial target.

