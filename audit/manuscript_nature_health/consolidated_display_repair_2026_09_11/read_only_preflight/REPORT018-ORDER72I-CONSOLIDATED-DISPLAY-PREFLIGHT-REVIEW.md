# REPORT018 Order72i consolidated display preflight review

Date: 2026-09-11

Executor: Harmonizer task `019ff52e-48ac-77b3-9a0e-9a87749a3bba`

## Result

The read-only preflight is complete. Fifty-one prospective source and structural checks pass against 62 pinned inputs. No accepted source, figure, table, Quarto document, Word document, or production output was modified or rendered.

The requested SVG-only repair route is feasible:

- S5 can become one real left-right figure as a flat native SVG with zero nested image nodes. Final construction must wait for accepted BA-017 replacement panels.
- S7 panel A already has an accepted genuine SVG. H07 must provide one bounded frozen-source native SVG export for panel B.
- H09 must provide two bounded frozen-source native SVG exports for S15 A and B.
- S7 and S15 then become two independent stacked image blocks each, while retaining one numbered figure and one shared caption per display.
- S17 can receive one optional reversible SVG-only compatibility trial for LibreOffice. Native Word already passes.
- S12 remains the accepted SVG and contains no MDER legend.

The table route is also fully specified:

- Supplementary Table S2 keeps all 14 columns in one horizontal set, permits vertical continuation only, preserves all 17 distribution plots, and uses a dedicated A3 landscape Word section.
- Supplementary Tables S5, S6, and S10 receive an explicit, computed-style-verified Arial capture contract.
- Main Table 3 remains byte-identical and retains the accepted Descriptives metric order.

## Missing authoritative components

1. Final S5 A/B panels from BA-017.
2. H07 native SVG for S7 B.
3. H09 native SVGs for S15 A and B.

The S5 caption also has an unresolved measurement-authority conflict recorded in `authority_flags.md`.

## Next gate

No user-side action is required. The Coordinator must review and seal the proposed candidate roots, owner allocations, serial order, trial limits, and acceptance boundary. Only then may the Harmonizer dispatch SVG work or tell the Writer to integrate and regenerate the manuscript.

Mandatory stop: `REPORT018-ORDER72I-CONSOLIDATED-DISPLAY-PREFLIGHT-REVIEW`.
