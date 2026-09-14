# REPORT-018 Order 72 H06 candidate-only independent acceptance

Date: 2026-09-11

Status: **INDEPENDENTLY ACCEPTED AS CANDIDATE SVG; HELD FROM WRITER**

Gate closed: `REPORT018-ORDER72-SVG-REVIEW`

## Scope and authority

This read-only review covers the two H06 SVG candidates released by Order 72:

| Current display | Candidate SVG | SHA-256 | Bytes | Native canvas |
|---|---|---|---:|---|
| Supplementary Figure S9 | `audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_paired_placement_effects.svg` | `e9d44034ace69fc82f67079fdabb266827cc06e053f948bd47e90d6ce1a47e14` | 7,423 | 170 x 120 mm |
| Supplementary Figure S12 | `audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_stage3_site_specific_significance_screen.svg` | `2b955196ce35eae1c973201a00523e538a6535ac59c8abe240160611a74c8b83` | 29,707 | 170 x 135 mm |

The review used the released Order 72 scope at SHA-256
`d14575d7c262b01fe58ba85d343f966d5953601a0fb41cc0f61c25279eb4071c`
and its non-circular 71-row release manifest at SHA-256
`8e25aa779f0115a3a5da9ffcdc3913b81cd6fb06df0c17c9f6d5825356263526`.
No file in the H06 owner package or any accepted source was modified.

## Independent verification

R 4.6.1 reproduced all 31 rows of the H06 completion manifest by SHA-256
and byte size, with unique paths. It also reproduced all 71 released paths by
SHA-256 and byte size.

An independent XML parse found 51 vector or text drawing elements in S9 and
224 in S12. Both files had zero `image`, `script`, and `foreignObject` nodes,
and zero attributes containing a data URI, JavaScript URI, or external HTTP
resource. The owner privacy and visible-token checks also passed.

The full-size and 170-mm comparison proofs were inspected independently. In
each proof, the accepted PNG is on the left and the candidate SVG raster is on
the right.

- S9 preserves the three effect rows, near-eye and chest estimates and
  intervals, null line, axes, colour and mark mapping, legend order, and
  whitespace. No label, layer, or interval is clipped.
- S12 preserves the three facets, nine-site order, site-specific estimates
  and intervals, null and site-average lines, retained and open marks, axes,
  title, subtitle, caption, colours, and whitespace. No label, layer, or
  interval is clipped.
- Visible differences are limited to rendering-device antialiasing.

The owner completion record, source-pin checks, native-vector checks, font
resolution, and visual QA are consistent with this independent review.

## Disposition

Both H06 SVGs are accepted as candidate endpoints. This is not manuscript
promotion. They remain held from the Writer until all seven Order 72 SVGs have
independent acceptance and the Coordinator issues one exact seven-row path and
SHA-256 authority. H06_daily remains excluded.

No owner retry, QMD or HTML edit, canonical promotion, manuscript edit,
scientific computation, model operation, Quarto render, production action,
commit, push, or upload is authorized or performed by this acceptance.

