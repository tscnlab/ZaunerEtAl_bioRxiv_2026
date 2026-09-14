# BA-015-DISPLAY-002 preferred-candidate stop verification

Date: 2026-08-20
Status: PASS
Scope: read-only verification of the preferred three-line candidate stop and
the two-line fallback boundary

## Environment and command

- R: 4.6.1 (2026-06-24)
- Packages: `digest` 0.6.39 and `png` 0.1.9
- Checker:
  `scripts/report_harmonization/check_brown_ba015_preferred_candidate_stop.R`
- Preferred candidate root:
  `/private/tmp/brown-ba015-candidate.3SU5jw`

```text
Rscript --vanilla scripts/report_harmonization/check_brown_ba015_preferred_candidate_stop.R /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 /private/tmp/brown-ba015-candidate.3SU5jw
```

The final execution returned exit status zero and:

```text
BA-015-DISPLAY-002 preferred-candidate stop verification PASS: 22/22 pre-recovery checks; 17/17 source checks; 15/15 build checks; 27 source rows exact; canonical endpoints unchanged; exactly two geometry-preservation failures from the third caption line; zero scientific execution.
```

## Verified evidence

The R audit independently verifies:

1. all four `BA-015-DISPLAY-001` central records at their exact identities;
2. the frozen 48-member Stage 2 manifest, paired source, canonical PNG and SVG,
   QMD, first-render HTML, and `renv.lock`;
3. all 13 durable preferred-candidate evidence files at their exact identities;
4. the current preferred builder and exact reverse reconstruction of the
   historical builder;
5. all 22 pre-recovery and 17 source-repair checks;
6. a 19-row non-circular pre-recovery manifest with exactly one expected live
   mismatch, the authorized builder transition;
7. exactly two failed candidate checks and no other failure;
8. the three temporary candidate members at their exact identities;
9. all 15 candidate build checks;
10. exact equality of all 27 paired-source rows and every column;
11. five `BA-M4` markers, three `BA-M6` markers, and retention of all three
    significant directions in the support sample;
12. PNG dimensions of 2640 by 3360 pixels;
13. the exact 809,522-pixel difference and its rows 343 through 3317 and
    columns 66 through 2640;
14. failure only of normalized non-note SVG equality, with both caption
    sentences present and complete; and
15. zero model fits, predictions, inference, or resampling.

Direct intended-size inspection confirms that the preferred three-line note is
complete. It also confirms the reason for rejection: the extra caption line
changes vertical layout rather than remaining confined to the internal-note
band.

The unchanged QMD SHA-256 is
`80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997`.
Its full Figure 3 caption still states that all site estimates are components
of one pooled model, not independent site replications or causal effects of
location. Removing that redundant qualification only from the raster therefore
does not remove it from the reader-facing report.

## Quality controls

- R parse: PASS
- Air formatting check: PASS
- new central-file em-dash scan: PASS
- new central-file trailing-whitespace scan: PASS
- Brown files changed by the central audit: zero
- canonical display or report endpoints replaced: zero
- Quarto renders: zero
- model fits, predictions, inferential calculations, or resampling: zero

## Disposition

The evidence supports one fresh two-line fallback candidate under
`BA-015-DISPLAY-002`. The fallback may remove only the redundant internal
raster qualification while preserving it verbatim in the full Quarto caption.
It must restore exact non-caption geometry before canonical replacement. The
single replacement render remains conditional on complete fallback-candidate
acceptance. Stage 4 and writer notification remain blocked.
