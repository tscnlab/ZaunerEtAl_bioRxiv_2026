# Nature Health figure and table selection: render and structural QA

Date: 2026-08-24

## Runtime and boundary

- R 4.6.1
- Quarto 1.9.37
- Document execution disabled
- No hypothesis QMD, model, scientific input, accepted result HTML, or scientific artifact was executed or changed

The planning assets were generated with the dedicated R builder. It completed with 13 accepted report inventories, 21 table outputs, 13 catalogued hypothesis figures, 30 non-circular manifest rows, and 843 reversible `gt` semantic substitutions.

The first sandboxed Quarto attempt stopped before Pandoc because Quarto could not open its user-owned Sass cache. It produced no output. The identical standalone planning-page render then ran with the established narrow cache access:

```text
quarto render manuscript_figure_table_selection.qmd
```

The retry completed with exit status 0 in 8.813 seconds and created the standalone embedded-resource HTML beside the QMD.

## Structural acceptance

- Final HTML SHA-256: `718df013ca76ddc1c01ce552af30793887370926d923262390d2b5fb0d659394`
- Final HTML bytes: 28,208,256
- R structural checker: 30 of 30 checks passed
- Rendered tables: 24 total, including 16 accepted native `gt` previews and three custom planning tables
- Selected figure previews: 25; all 59 emitted images, including density thumbnails, have nonempty alt text and are embedded
- Table disclosures: 12
- Document IDs: unique
- Explicit table-header tokens: 2,438 of 2,438 resolve exactly once to a `th` inside their own table
- Relative planning-file links and document anchors: resolved
- Embedded error or warning nodes: zero

The checks also confirm:

- the author-approved four-display main sequence and unnumbered person-level preview;
- all scientific Descriptives outputs assigned to main Figure 1 or Supplementary Information, except the explicitly redundant long participant table;
- Daytime, Pre-sleep, and Sleep as the Brown manuscript-window contract;
- raw p-values omitted only from the H05, H08, H09, and H10 manuscript-selection table copies;
- the H06_daily table present and visible in the static document without the inherited page-width layout class;
- the exact H09 source-ready transition explicitly labelled rather than treated as accepted rendered output; and
- the unresolved MDER definition-alignment gate retained visibly in main Table 2.

## Author-review handoff

This artifact is an author-facing selection and caption document, not a final manuscript render acceptance. Responsive grids, embedded images, and contained table scrollers are implemented in the standalone HTML. Artifact-level repairs that still belong to the Brown, H03/H04, H06_daily, H09, and H10 owners are explicitly labelled and were queued separately. The page is opened in Codex for the author’s visual review; no hypothesis render is implied by this planning-page render.
