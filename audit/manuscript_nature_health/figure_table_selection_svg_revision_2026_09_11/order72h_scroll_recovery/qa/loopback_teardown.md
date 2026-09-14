# Order72h loopback teardown

Date: 2026-09-11

- The in-app browser QA tab was closed after the 1440, 708 and 390 CSS-pixel
  reviews.
- The three temporary viewport wrapper files were deleted with `apply_patch`.
- The single loopback server session was stopped with Ctrl-C and exited with
  status 0.
- `lsof -nP -iTCP:8765 -sTCP:LISTEN` returned no listener after teardown.
- The served staging directory contains only the immutable rendered candidate
  `manuscript_figure_table_selection.html`.
