# BA-015-DISPLAY-001 stopped-state verification

Date: 2026-08-20
Status: PASS
Scope: read-only verification of the `BA-015` result package and failed visual
QA state before authorizing a display-only recovery

## Environment

- R: 4.6.1 (2026-06-24)
- Platform: current project macOS arm64 runtime
- `digest`: 0.6.39
- `png`: 0.1.9
- Checker:
  `scripts/report_harmonization/check_brown_ba015_internal_plot_note_clipping_stop.R`
- Central project root:
  `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026`
- Continuing Brown worktree:
  `/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`

The checker used the existing project R 4.6 library. It did not load a model,
fit or refit anything, construct a contrast, calculate a new inferential
quantity, change a file in the Brown worktree, run Quarto, or open a browser.

## Command

```text
Rscript --vanilla scripts/report_harmonization/check_brown_ba015_internal_plot_note_clipping_stop.R /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

## Result

The final checker execution returned exit status zero and:

```text
BA-015-DISPLAY-001 stopped-state verification PASS: 48/48 Stage 2 members; 18/18 derivation checks; 31/31 verification checks; 3 primary BA-M6 FDR localizations; 17/17 display checks; 26/26 source checks; 28/28 render checks; one isolated internal-note clipping failure; teardown exact.
```

The audit verified:

1. all ten controlling `BA-015`, `BA-015-CORR-001`, and
   `BA-015-CORR-002` central records at their exact identities;
2. unique current `BA-015` and `CHG-154` ledger rows;
3. the complete 48-member non-circular Stage 2 manifest;
4. 18 of 18 derivation checks and 31 of 31 independent verification checks;
5. exactly 27 primary and 27 support-sample `BA-M6` rows;
6. exactly the three reported primary FDR localizations and their frozen
   estimates and adjusted p-values;
7. retained sensitivity direction and complete estimability for all three;
8. the 27-row anonymous paired display source, five `BA-M4` markers, and three
   `BA-M6` markers;
9. all 17 display, 26 source, and 28 render checks;
10. the exact QMD, first-render HTML, builder, paired source, PNG, SVG, failed
    visual record, lifecycle record, and handoff identities;
11. PNG dimensions of 2640 by 3360 pixels;
12. the exact current unwrapped final internal-note source string;
13. the sole `BA_M6_internal_caption` failure, with the full reader-facing
    caption and deterministic 390-pixel structural checks passing; and
14. the recorded listener teardown, temporary-copy removal, and post-QA hash
    stability.

An additional read-only system check returned no listener on
`127.0.0.1:60600`. Direct intended-size inspection of the frozen PNG confirmed
that only the second internal note line is clipped at the right boundary.

## Quality controls

- R parse: PASS
- Air formatting check: PASS
- em-dash scan of the new central files: PASS
- trailing-whitespace scan of the new central files: PASS
- Brown author files modified by this audit: zero
- model fits, predictions, new contrasts, p-values, intervals, or FDR
  calculations: zero
- Quarto renders: zero
- browser or server sessions: zero

## Disposition

The evidence supports `BA-015-DISPLAY-001` as a display-only recovery. The
authorized repair is limited to wrapping the plot-internal qualification,
rebuilding and validating the figure from the exact frozen paired source, one
replacement target render, and repeated bounded QA. All inference, QMD text,
paired source, and earlier seals remain frozen. Stage 4 and writer notification
remain blocked at `BA-CS-G3-INTEGRATED-REVIEW`.
