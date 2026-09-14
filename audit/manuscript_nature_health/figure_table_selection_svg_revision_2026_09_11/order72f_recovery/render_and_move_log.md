# Order 72f render and move log

- Working directory: `audit/manuscript_nature_health`
- Quarto version: `1.9.37`
- Source: `manuscript_figure_table_selection.qmd`
- Source SHA-256 before and after render: `9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3`
- Frozen canonical HTML SHA-256 before and after render: `82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6`
- Environment: `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`; R checks use `/Users/zauner/Library/R/arm64/4.6/library`; the Quarto render used the existing narrowly approved user cache.
- Render command: `quarto render manuscript_figure_table_selection.qmd --to html --output manuscript_figure_table_selection_order72f_candidate.html`
- Render start: `2026-09-11T12:53:55Z`
- Render end: `2026-09-11T12:54:52Z`
- Render exit: `0`
- Created output: `audit/manuscript_nature_health/manuscript_figure_table_selection_order72f_candidate.html`
- Candidate SHA-256: `7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4`
- Candidate bytes: `29370696`
- Persistent support sidecar: none
- First move command: `mv manuscript_figure_table_selection_order72f_candidate.html figure_table_selection_svg_revision_2026_09_11/rendered/manuscript_figure_table_selection.html`
- First move exit: `1`
- First move diagnostic: the exact `rendered/` destination directory did not exist.
- Post-failure state: the candidate remains intact at the temporary sibling, the intended destination is absent, the source is unchanged, and the canonical old HTML is unchanged. No second render or move has been attempted.
