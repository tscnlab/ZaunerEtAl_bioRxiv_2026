# REPORT-017 Preparation 07 stopped-render independent acceptance

Date: 2026-08-14

Harmonization coordinator task: `019ff52e-48ac-77b3-9a0e-9a87749a3bba`

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Outcome: **ACCEPTED AS A BOUNDED STOP.** The single authorized Preparation 07
target render completed successfully, and all nonvisual integration checks
passed. The page is not accepted for serial release because the unchanged
left-to-right Mermaid overview reduces its labels to approximately 5.03 pt at
the required 708-pixel viewport, below the controlling 7 pt minimum.

This is `RH-VIS-002`, a display-only defect. It is not a scientific,
provenance, table, figure, link, source, or render-execution discrepancy.
Preparation 07 and every hypothesis render remain held.

## Reproduced identities

The controlling owner order is
`audit/report_harmonization/owner_orders/27_preparation07_phase4_render.md`,
SHA-256
`0f0d5570f964d64cdd58897e4e45a5fb96c18f08486b2e29031bb5b1f69fd560`.
The released inputs remain exact:

- source QMD: `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae`;
- focused test: `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163`;
- Nature Health profile: `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- rendered HTML: `9c05cd46796d853dad10e5f3058231946f0c1df3a4678d6272d6aa8141fe47db`;
- owner stop record: `aea0899ecfc8c5325b4015f7f2e2c6c282928f7e4b1067852a265cb3004bed13`;
- 45-entry owner manifest: `88c1bbf4159caec07c0b60359bbd5aa241cf21dbae811c7efe6d0ec2f0066c0b`.

An independent checksum replay found all 45 manifest entries present with
their exact byte counts and SHA-256 identities. The pre-render, post-render,
and post-QA 38-path protected inventories are byte-identical at
`5b9cf24c75a593d0d7a46530904c965a92476333bd19dea619ad348538c94949`.
The source still contains exactly the unrepaired declaration `flowchart LR`
at line 664. No second render or source edit occurred.

## Independent structural and visual review

The semantic evidence contains 24 checks and zero failures. The DOM contains
exactly seven native `gt` tables, each with one Quarto-owned caption,
nonempty headers and body rows, and its intended source note. All three
figure endpoints, their captions, alt text, and source files pass. The
historical and current site-context identities are displayed distinctly with
the approved equivalence wording. Country-coded sites, navigation, reader
links, source-data links, the active sidebar state, and the absence of
reader-visible errors all pass.

The supplied screenshots were inspected independently:

- at 1,440 by 1,000 pixels, the Mermaid labels retain 9.001 pt and the page,
  seven tables, and three figures are readable without clipping or overflow;
- at 708 by 1,000 pixels, the seven HTML tables retain 8.25 pt text, fit their
  containers, and require no horizontal scrolling;
- the same narrow viewport scales the 1,531.16-pixel-wide LR Mermaid to 642
  pixels, giving eight important labels a minimum effective size of 5.031 pt;
- the diagram has no clipped or overlapping labels, but its typography is
  visibly too small and fails the explicit 7 pt gate.

The narrow screenshot is
`audit/preparation_reports/report017_preparation07_failed_narrow_viewport.png`,
SHA-256
`a01341a3232828298c462798ed0e96582bf745297d928d3543edd91d4cd6e87a`.
The measurement CSV is
`audit/preparation_reports/report017_preparation07_failed_visual_metrics.csv`,
SHA-256
`2658cc22046f42c42d58cc77560cd74b354848205cdac5f2af4fa5683b071360`.

## Loopback teardown and disposition

The temporary server was rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1:51011`, and used only for the exact Preparation 07 page. PID 8466
exited normally. The recorded post-stop `lsof` check returned the expected
empty no-match result, and an independent repeat also found no listener.

The smallest proposed repair is the already established display-only change
at the identified overview: replace only `flowchart LR` with `flowchart TB`.
Every node, edge, label, caption, alt text, surrounding prose, scientific
content, table endpoint, figure, artifact, test, and configuration identity
must remain unchanged. A separate coordinator authorization is required
before that source edit or another target render. After authorization, the
owner must prove exact reverse substitution, run one fresh Preparation 07
target render, repeat the focused, semantic, protected-input, desktop, and
708-pixel secure-loopback checks, and stop on any remaining defect.

