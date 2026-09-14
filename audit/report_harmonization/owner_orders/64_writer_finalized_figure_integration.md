# Owner order 64: integrate finalized figures into the Nature Health manuscript

Status: post-send transcription and scope seal

This order truthfully records the author-authorized instruction sent to the
Writer task before a central owner-order packet had been sealed. It is not
pre-dispatch evidence and is not backdated. The Writer message was delivered
to task `019ffb39-372e-7262-bfac-192751fd0e63`, whose resulting turn is
`01a05956-0464-7f63-9b9d-17aab1dc6437`.

## Author authorization

After Table 3 metric order was harmonized to the descriptive table, the author
instructed the Harmonizer to tell the Writer to integrate the figures into the
manuscript. This releases the earlier manuscript figure-implementation gate.

## Controlling finalized selection pins

- Selection QMD: `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`
  - SHA-256: `462e1610233185cf3655443cafdc1fd8009ec17646187cae806636815b06e441`
- Selection HTML: `audit/manuscript_nature_health/manuscript_figure_table_selection.html`
  - SHA-256: `ad1b29613f2e418e3d61b995993891f0804d523140b5e590bee059c08e92c509`

The selection HTML was rendered without Quarto or Pandoc warnings after the
Table 3 order harmonization. Its main figure order and roles control.

## Main-figure integration order

Integrate these figures in the exact order, role, panel structure, caption,
terminology, and source identity defined by the controlling selection QMD:

1. Figure 1: study protocol, sites, collection windows, civil photoperiod,
   and daily near-eye exposure.
2. Figure 2: multiscale daily pattern of near-eye melanopic EDI.
3. Figure 3: activity category and local-clock pattern of near-eye melanopic
   EDI.

Light-source category remains supplementary. Activity category remains main.
Use uppercase panel tags positioned at the left side of panels. Use near-eye
terminology without redundant `primary` wording where the selection source
does so. Do not reconstruct a multi-panel figure through Quarto when a sealed
single-file composite exists.

## Supplementary-figure integration

Integrate the selected supplementary figures in the exact Supplementary
Information sequence in the controlling selection QMD. Preserve finalized
asset paths, panel order, captions, alt text, terminology, and
main-versus-supplementary roles.

For H06_daily Supplementary Figure S12, use the independently accepted
selection candidates rather than replacing or using the unchanged canonical
H06_daily FDR figure:

- PNG: `audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12/H06_daily_supplementary_figure_s12.png`
  - SHA-256: `8b66509d8fee47521f6179c793a612d1ec707a330a7a45a2715c449d0136e75f`
- SVG: `audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12/H06_daily_supplementary_figure_s12.svg`
  - SHA-256: `4d95b3f1160a310baa6152f2ec7acecdd03da16c835ddcfbada6676cafd56d0d`
- Independent acceptance:
  `audit/report_harmonization/report018_h06_daily_order63_supplementary_figure_s12_independent_acceptance.md`
  - SHA-256: `a9c62b39c8940d3c6164146dc023ece2b91d80fdc9ce858d87a5c2d834e08ab8`

This S12 candidate preserves the frozen 90-row science. Six estimable MDER
cells use the ordinary FDR-not-supported encoding, L10 remains non-estimable,
and the redundant MDER-specific legend class is absent.

## Table 3 reconciliation note

Table 3 is not part of the figure-edit instruction, but its final identity is
provided so manuscript cross-references are reconciled against the same
selection state:

- Fragment:
  `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html`
- SHA-256: `2f7f6f475d9fe55ee37da3c73aa12474e347ec4619889278fbca0aeab2f40e1c`
- Order: Duration, Dynamics, Exposure history, Level, Spectrum, Timing.
- Within Timing: First light and Last light precede Mean timing.
- R 4.6.1 Table 3 audit: PASS 14 of 14.
- R 4.6.1 all-`gt` endpoint audit: PASS 13 of 13.

## Scientific and ownership boundary

The Writer may edit only its existing owned manuscript implementation paths:

- `manuscript/R0_NatHealth/**`
- task-owned manuscript records under `audit/manuscript_nature_health/**`,
  `scripts/manuscript_nature_health/**`, and
  `tests/manuscript_nature_health/**`
- `audit/handoffs/nature_health_manuscript_worker_handoff.md`

Do not edit `manuscript/R0_NatMed/**`, accepted analysis/report sources,
central ledgers, shared configuration, scientific artifacts, or canonical
H06_daily figures. Do not rerun analyses or change data, models, estimates,
samples, intervals, p-values, FDR decisions, diagnostics, or claims.

## Render and return boundary

Run only manuscript-targeted Quarto renders under `manuscript/R0_NatHealth/`.
Do not run a full-project render. Verify figure paths, numbering,
cross-references, captions, alt text, panel tags, responsive containment, and
protected scientific tokens. Return edited file paths, render identities,
visual-QA evidence, and any genuine remaining figure dependency.

