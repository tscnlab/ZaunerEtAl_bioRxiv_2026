# Supplementary Information Brown wording source seal

Date: 2026-09-01

Status: source-only integration complete; no render run

## Scope

This seal covers only the coordinator-authorized Brown recommendation-window
wording changes in
`manuscript/R0_NatHealth/supplementary_information_outline.qmd`:

1. Supplementary Figure S4 alternative text.
2. Supplementary Figure S4 caption after the existing bold figure number.
3. The Sleep interpretation clause in Supplementary Table S3.
4. The Sleep interpretation sentence in Supplementary Figure S5.

The accepted S4 asset path, the accepted S5 asset, the accepted S6 and S14
single-asset references, every other caption, and the separate Supplementary
Figure S7 wording were preserved.

## Authority

- Brown S4 caption and alternative-text contract:
  `audit/manuscript_nature_health/figure_table_selection_assets/brown_supplementary_figure_s4_caption_alt_text.md`
- Contract SHA-256:
  `fb5fc64b9d9a24e61d99a387d680acb38e547a1c16029a97ee046eed46ba0421`
- Accepted S4 SVG SHA-256:
  `65c262ff90dbf458549a417d722e625fba5d30ed892edabd34e81c37b55c1433`

## Source identities

- Superseded SI QMD preimage SHA-256:
  `141dd8db4ed2d2a2b58028f8083b24d23f22fe21412d3950f12582ee94c2103a`
- Current SI QMD postimage SHA-256:
  `d7e7ca45a833f573fce99798044599b6387eb04755106116c961a0326c0d130a`

## Verification

R 4.6.1 source-only verification passed:

- Exact in-memory reversal of the four authorized substitutions reproduced the
  superseded SI preimage SHA-256 exactly.
- The exact Supplementary Table S3 replacement occurs once.
- The exact Supplementary Figure S4 alternative text occurs once.
- The exact Supplementary Figure S4 caption occurs once.
- The exact Supplementary Figure S5 replacement occurs once.
- `bedside sleep environment` occurs zero times within the Supplementary Table
  S3 through Supplementary Figure S5 scope.
- The separate Supplementary Figure S7 bedside-environment sentence remains
  present exactly once.
- All three main figures and all 16 Supplementary figures have unique labels,
  exactly one image reference, and a resolving local asset path.
- `git diff --check` passed and the SI source contains no em dash.

No Quarto, knitr, Pandoc, model, analysis, figure, or table render was run.
