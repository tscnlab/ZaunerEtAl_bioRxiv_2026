# REPORT-018 Order 71b2d completion

Date: 2026-09-03

Status: `PASS_PROMOTED_AWAITING_INDEPENDENT_ACCEPTANCE`

## Outcome

The final Nature Health Word manuscript was promoted once to
`manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`.
Its SHA-256 is `74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8` and its size is
28,793,619 bytes.

The sole Word display repair replaced `word/media/image15.png`, the captured
Supplementary Table S3, while preserving every other uncompressed DOCX member.
The repaired PNG is 2,118 by 1,464 pixels, SHA-256
`e8847874e5b1d08db8e67527c7ff4742fbd9912bae58ac161fecc21df6219e4c`. It preserves the approved 1,059 CSS-pixel
table width and 12-pixel capture font while showing every denominator in full.

## Validation

- The sealed dispatch manifest reproduced 18 of 18 identities under R 4.6.1.
- The complete structural suite passed: 87 valid package parts, 28 authors,
  14 affiliations, 91 bibliography entries, 53 displays, 27 sections, 124
  resolved internal links, 102 unique targets and 195 bookmarks.
- The exact 22 repaired destinations remain present. `fig-s3` remains absent
  from both hyperlink and bookmark sets as required.
- The replacement render contains 102 pages with unchanged page
  dimensions. Pages 1 to 60 and 62 to 102 are decoded-pixel identical to the
  previously inspected render. Page 61 differs only within the Supplementary
  Table S3 image region (237,115,1767,990).
- Original-resolution inspection passed for all 102 pages. On page 61, the
  complete `555,738 / 1,086,468` total and all four `1,175,160` denominators
  are readable without clipping, overlap or missing glyphs.
- The accepted manuscript QMD, Supplementary Information QMD, self-contained
  HTML, direct Supplementary Figure S6 SVG and integrated website remain exact.

## Statistical terminology decision

The author's preference for R² or variance explained is already satisfied in
the frozen manuscript wherever those terms are technically valid. H02, Brown
adherence, H01/H07 and the exploratory H03/H04 mixed-model summaries use R² or
explained variance. The two H03/H04 time-of-day decompositions remain described
as shares of variation in fitted hourly patterns because they partition fitted
linear-predictor variation without a response-variance denominator and are not
R². This decision required no source or render change.

## Evidence

The non-circular completion manifest is
`audit/manuscript_nature_health/order71b_execution_2026_09_03/order71b2d_completion_manifest.csv`.
It excludes itself. The 102-page inventory, page comparison and every-page QA
records are listed there with exact identities.
