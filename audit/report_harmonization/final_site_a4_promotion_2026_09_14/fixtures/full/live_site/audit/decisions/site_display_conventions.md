# Site display conventions

Decision ID: `DISPLAY-001`
Date: 2026-07-31
Status: approved for all hypothesis, descriptive and manuscript outputs

## Decision

All reader-facing tables, figures and prose use the site names, order and
colours from the submitted manuscript. The shared machine-readable registry
is `config/site_display_registry.csv`.

| Order | Data code | Reader-facing name | Colour |
|---:|---|---|---|
| 1 | `RISE` | Borås (SE) | `#88CCEE` |
| 2 | `THUAS` | Delft (NL) | `#117733` |
| 3 | `BAUA` | Dortmund (DE) | `#DDCC77` |
| 4 | `MPI` | Tübingen (DE) | `#DDCC77` |
| 5 | `TUM` | Munich (DE) | `#DDCC77` |
| 6 | `FUSPCEU` | Madrid (ES) | `#CC6677` |
| 7 | `IZTECH` | Izmir (TR) | `#332288` |
| 8 | `UCR` | San José (CR) | `#44AA99` |
| 9 | `KNUST` | Kumasi (GH) | `#AA4499` |

The three German sites intentionally share the submitted manuscript colour.
When colour alone would not distinguish them, add direct labels, shapes or
line types without changing the registered colours.

## Application rules

- Preserve the registry order in prose enumerations, table rows or columns,
  facets, legends and multi-panel displays. A discrete vertical axis may use
  reversed factor levels only when that is necessary to show Borås at the top;
  the visible order remains the table above.
- If a placement or model lacks a site, omit that site without reassigning
  colours or reordering the remaining sites.
- Put `Overall` before the site sequence when it is displayed and use a
  neutral colour for it.
- Use the reader-facing names in visible output. Retain short site codes in
  data keys, formulas, filenames and technical provenance where needed.
- Do not order manuscript-facing sites by effect size, latitude, sample size,
  alphabetical order or statistical significance. Such an alternative may
  appear only as a clearly labelled audit diagnostic and cannot replace the
  registered presentation.
- This is a display rule. It does not change model reference coding,
  contrasts, samples, estimates or inferential families.

## Evidence

The mapping reproduces `melidos_order`, `melidos_sites` and `melidos_colors`
used by the submitted descriptive and hypothesis documents in
`scripts/helpers.R` and `scripts/site_names.R`, with colour values supplied by
melidosData 1.0.6.

## Reopening condition

Reopen only if the author approves a changed reader-facing site name, order or
colour, or a journal accessibility requirement makes the submitted palette
unusable. Accessibility additions such as shapes or direct labels do not
reopen the decision when the registered colours remain unchanged.
