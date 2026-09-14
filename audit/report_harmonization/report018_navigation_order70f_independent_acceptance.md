# REPORT-018 navigation Order 70f independent acceptance

Date: 2026-09-02

Status: `PASS`

## Disposition

Order 70 is independently accepted and closed. The final Nature Health
landing page was promoted exactly once without a Quarto render or scientific
recalculation. The accepted manuscript landing page uses the approved Brown
participant-state SVG at
`manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg`.

The owner's final replay stopped only because `vapply()` retained names on one
hash vector while the comparison vector was unnamed. An independent R 4.6.1
replay removed that non-content attribute with `unname()` and reproduced all
105 file identities and byte counts. This is a verifier-expression issue, not
a file, content, rendering, or scientific discrepancy. The implementation
script and owner evidence remain unchanged. No rerun or checker patch is
required.

## Independent replay

The independent read-only replay returned:

`ORDER70F_INDEPENDENT_REPLAY=PASS manifest=105/105 postflight=22/22 routes=74/74 landing=3/3 transitions=1_changed lifecycle=5/5 R=4.6.1`

It verified:

- 105 unique, non-circular completion-manifest rows with exact SHA-256 and
  byte counts;
- 22 of 22 postflight checks;
- 74 of 74 production route checks at 708 and 390 pixels;
- 3 of 3 complete landing-page checks at 1,440, 708, and 390 pixels;
- one promotion event containing exactly two promoted files;
- 893 production files, zero symlinks, and no rollback;
- a 37-row corpus transition with only row 1, the landing HTML, changed;
- the accepted landing HTML, corrected Word file, corpus manifest,
  implementation script, and Brown SVG by exact identity; and
- the complete server lifecycle, including viewport reset, normal shutdown,
  and absent listeners.

## Accepted identities

- `_build/nathealth/index.html`:
  `c8abe2f9fbfcbe2fc8b4e39e149797a6dc2d74a5735337ed2399fb6e5814eb21`
- `_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx`:
  `6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`
- `audit/report_harmonization/phase4_corpus_manifest.csv`:
  `b807197850b3d9024899da79403f3aec7d716f9be785fe1eefe6500e1ac1e55d`
- `manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg`:
  `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`
- Order 70 implementation script:
  `f87eaf01f7ea76cba94a1d30bd45ddc07c6fcf55f8ea87c1bb94bf510a56f66a`

## Scope boundary and release

No QMD, analysis, estimate, interval, p-value, model object, figure, table,
package, lockfile, or accepted evidence was changed during independent
acceptance. No commit, push, upload, deployment, or submission occurred.

Order 71a may now be sealed and dispatched once to the Nature Health Writer.
Orders 71b and 71c remain held until the bounded Order 71a source and HTML
result receives independent acceptance.
