# REPORT-018 Nature Health Order 69b Word independent acceptance

Date: 2026-09-02

Status: `INDEPENDENTLY_ACCEPTED`

## Accepted output

The Order 69b Word recovery is accepted. The verified fresh candidate and the
promoted canonical DOCX are byte-identical:

- `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
- `audit/manuscript_nature_health/reference_doc_word_correction_2026_09_02/candidate_reference_styled_11pt_footerfix.docx`
- SHA-256 `6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`
- 28,792,333 bytes

The accepted postprocessor is
`scripts/manuscript_nature_health/prepare_word_manuscript.py`, SHA-256
`05ed9ca826757c643970a6d201fbcc15cfc83648d2ebdc8d44f707d85f214727`,
31,160 bytes.

## Independent reproduction

The final 25-row owner completion manifest at SHA-256
`a682c82ee1753f2d060945094cc83e477705efebc9c920a780b41bbfe6e03910`
was reproduced under R 4.6.1 with digest 0.6.39. All 25 paths, byte counts, and
SHA-256 values match; paths are unique and the manifest is non-circular.

An independent OOXML reparse of the accepted candidate and canonical DOCX
confirmed:

- both archives are valid and byte-identical at the accepted identity;
- 27 A4 sections comprise 14 portrait and 13 landscape sections;
- every landscape section has `w:distance="72"`, while portrait numbering
  remains continuous and unchanged;
- all 26 inserted body section-break paragraphs carry exactly one
  `w:suppressLineNumbers`;
- exactly two footer parts exist, each with exactly two paragraphs, one
  preserved PAGE field, and one suppression marker per paragraph;
- Normal is Arial 11 pt with the preserved 360-twip automatic line spacing;
- Title and Heading 1, Heading 2, and Heading 3 retain explicit sizes of 26,
  18, 16, and 14 pt;
- the complete text sequence and all 69 embedded media parts match the failed
  Order 69a candidate, proving that the footer-only recovery did not alter
  manuscript content or displays.

The machine-readable owner structural result at SHA-256
`67dbbbb279d7e8dde5c803a46e63ab22d7fd12e9e96b0f12e944ab9afa7084b5`
was independently read under R 4.6.1. It contains 308 checks, every check is
PASS, the failure list is empty, and the overall status is PASS.

The page inventory summary at SHA-256
`4f40530e5ad65fdc4fdbd62b12883f9c531977f46783f59d745fdc971aca0f9f`
was independently verified under R 4.6.1. The accepted PDF at SHA-256
`bf80090749ff7e334422f8e584455b1c10ff147a01728745b71a8f984f559c73`
contains exactly 102 A4 pages, comprising 60 portrait and 42 landscape pages,
with zero blank candidates and zero pages containing out-of-bounds glyphs.
All 102 corresponding page PNGs are present, uniquely numbered 1 through 102,
and nonempty.

Independent full-resolution visual inspection sampled the prior failure area
on pages 5 through 7, the accepted two-page Supplementary Figure S8 treatment
on pages 82 and 83, and the final page 102. The prior stray footer values are
absent, centered page numbers remain visible, content line numbering is
continuous, wide tables are readable and unclipped, the S8 crop and caption
continuation are intact, and the final sparse page is valid rather than blank.
This agrees with the owner's recorded inspection of all 102 pages and the
coordinator's independent inspection of the prior failure pages.

## Stability and release

Independent R 4.6.1 comparison against the sealed preflight inventory confirms
all 892 files below `_build/nathealth` remain byte-identical, with zero missing,
added, changed, or symbolic-link entries. The manuscript QMD, nested profile,
accepted HTML, reference DOCX, capture manifests, scientific artifacts,
website sources, package state, lockfiles, and existing corpus manifest remain
at their protected identities.

The Order 69b completion record at SHA-256
`894e6201ea94f178185690b360d5c5f4ed6374f503b27f4bb354b1cf3a649b39`,
postflight stability record at SHA-256
`b6f7b0e9b4a97c19778874987cd7ed13ebe5edc6585d4e418448e8fb4937e499`,
and teardown record at SHA-256
`4b4a0085dbf2271c13d9a4b2f238f56447651ffd5b4c3c59cb0a2ee0cd32cd44`
are accepted.

Order 69b is closed. The serial gate for the separately sealed, no-QMD
website integration Order 70 is released. That release does not authorize a
full-profile render, scientific execution, or mutation of any route other than
the manuscript landing index and strictly necessary manuscript resources.
