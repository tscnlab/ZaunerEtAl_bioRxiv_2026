# H03 manuscript Supplementary Figure S7 acceptance

Date: 2026-08-31
Status: **PASS, SEALED FOR INDEPENDENT ACCEPTANCE**

## Scope

The bounded production task revised one durable four-panel H03 manuscript
figure from frozen stored outputs. Panels A-C preserve the accepted near-eye
time-of-day display, with a shorter unclipped panel-B y-axis title and a
restored separate panel-C tag. Panel D presents the accepted site-average estimates and
site-specific deviation ratios from the light-source-by-site interaction
model.

No model or inferential RDS was loaded. No model, prediction, simulation,
bootstrap, scientific summary, source-data artifact, existing accepted
figure, QMD, HTML, Quarto target, manuscript-selection source, package,
lockfile, ledger, commit, push, or upload was changed or executed.

## Candidate-first QA

The isolated candidate root was:

`/private/tmp/h03_s7_revision2_candidate.VwVYD0`

The candidate was inspected at its original 4,725 by 7,375 pixel resolution
and at the intended 170 mm manuscript width. The complete figure, panel-D
header and site-average row, all nine site rows, inline confidence intervals,
non-estimable cells, notes, and panel joins were inspected. The vertical
panel-B title is fully visible at the same horizontal offset as the A and C
axis titles, and the C tag is distinct. The panel-D tag is left-positioned and the
table begins at the 67.89-point plot-content edge. No clipping, collision,
truncation, missing cell, or material imbalance was found.

The 170 mm preview has SHA-256
`b99476c6e663fe494581dba1efbbef79bb9ffd676c9e5feb3628fd0bd0e87f04`.
The panel-D 170 mm preview has SHA-256
`39b0564628507c777902ed8bb7b26269579f1d9c2e79ad4c992c02182fdc9d8e`.

The canonical PNG and SVG are byte-identical to the inspected candidate. The
accepted temporal raster differs only in 16,700 decoded pixels inside the
bounded panel-B axis-title and panel-C tag repair tile. No temporal pixel
outside that tile changed.

## Preservation results

- All seven site-average estimates, intervals, and indoor-reference ratios
  reproduce the accepted factorization table.
- All 63 site-category records reproduce their accepted ratios, intervals,
  FDR emphasis decisions, support values, and reporting states.
- All ten unsupported site-category cells remain `Not estimable`.
- Adjusted p-values are displayed to the accepted three-decimal grammar, with
  values below 0.001 printed as `<0.001`.
- Category support retains participant-hours, participants, participant-days,
  and sites for every category.
- The accepted overall statement is unchanged: 17,935 participant-hours, 140
  participants, 801 participant-days, and nine sites.
- Each accepted H03 participant-hour has one mutually exclusive primary
  light-source category. The figure explicitly records that 1/k multi-label
  weighting does not apply.
- The temporal source-model flag remains `site_effects_excluded = TRUE`.
- Panel D remains tied to stored `full_literal` interaction-model estimands.
- Site markers reproduce `config/site_display_registry.csv`. The three German
  sites intentionally share the accepted `#DDCC77`; country-coded labels,
  fixed row order, and alternating fills provide non-colour cues. Site markers
  have no outline.
- The light-source and site colour sets have no shared hexadecimal value.
- Visible text uses “site-average estimate” and “light-source-by-site
  interaction model”. It does not use “heterogeneity model”.
- Bold uppercase panel tags A, B, C, and D are present exactly once and are
  positioned at the left.
- Site-specific ratios and their 95% confidence intervals share one line,
  with the interval in parentheses. The header uses a single P/D/H support
  line, omits the repeated site count, and has no site-column heading.

## Output identities

| Output | SHA-256 |
|---|---|
| `artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.png` | `ae5174afa8d9b57b5d9a635dfe2320482105d72007882db7513e29380271f52d` |
| `artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.pdf` | `05803b374f55908e99e77e8161082ccceb57ec80899c82f4c8fd78c3685b53dd` |
| `artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.svg` | `a510c6bc356bba1ed748d4f0f4a308669b218af36af0b06e0fc18f82014674b3` |
| `artifacts/12_manifests/H03/H03_manuscript_supplementary_figure_S7_manifest.csv` | `adde8d8027096d3895a85f38c8401d81c28e92c032e67d8667b3108a23d960e5` |
| `artifacts/08_diagnostics/H03/H03_manuscript_supplementary_figure_S7_display_qa.csv` | `99c7e405c9bd27aea6b371840338734b94933b946dc418533b5027a2698a43e5` |
| `scripts/hypotheses/H03/build_h03_manuscript_supplementary_figure_s7.R` | `5e662069c2d6412334d2ace2d9989aca90f329a25171d97601be021edb46c6e4` |

The PNG is 4,725 by 7,375 pixels at 300 dpi. The SVG is 1,134 by 1,770
points. The PDF contains one 1,134 by 1,770 point page and rasterizes to the
same pixel dimensions at 300 dpi.

## Author-facing caption

**Near-eye light exposure by reported light source across time of day and
study site.** **A**, Expected one-hour melanopic EDI by local time, with
pointwise 95% confidence intervals; the dashed line is the global cyclic
smooth. **B**, Each light-source curve relative to the global time-of-day
mean, with 1 as the reference. **C**, Available participant-hours; open
circles indicate locally sparse support and grey gaps indicate no
observations. **D**, Site-average category estimates and site-specific
deviation ratios from the light-source-by-site interaction model. Parentheses
after site-specific factors show 95% confidence intervals. Bold site cells
pass the complete near-eye FDR adjustment; participant, participant-day, and
participant-hour support is shown in the header. The analysis includes 17,935 participant-hours from 140 participants,
covering 801 participant-days and nine sites. Panels **A-C** and **D** answer
different questions and are not numerically interchangeable. Estimates are
observational. During reported sleep, measurements describe the bedside
sleep environment.
