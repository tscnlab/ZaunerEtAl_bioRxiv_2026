# REPORT-018 Brown Stage 3 recommendation-window and BA-M consolidation audit

Date: 2026-08-24

Status: **READ-ONLY AUDIT PASS; PROPOSED ORDER NOT DISPATCHED**

Queue authority:
`audit/report_harmonization/report018_post_navigation_display_queue_2026_08_24.md`,
SHA-256 `9ebb1d81ef202b420aec42d12e5de372871edec780c5f72885e18d327f0f5a36`.

Brown owner: `019fffdf-66d4-7802-9091-09283ad27b7f`.

## Disposition

Queue item 1 can be expressed as one bounded source-and-display order. The
pending owner-pass BA-M repair is a valid baseline, not a competing change. It
has already removed reader-facing `BA-M4` and `BA-M6` labels from the Stage 3
QMD and Figure 3 while retaining immediate scientific translations in the
Stage 4 provenance companion. The new order should accept those postimages and
add only the superseding recommendation-window language.

No scientific discrepancy was found. No Brown file, figure, HTML, test,
manifest, handoff, source data, model output, or owner state was changed in
this audit. No candidate was generated and no R analytical computation,
Quarto, knitr, Pandoc, browser server, or render was run.

## Complete affected inventory

The inventory contains 57 uniquely identified rows in
`audit/report_harmonization/report018_brown_stage3_window_label_inventory.csv`:

- two authority rows;
- eight accepted, pending, linked-source, and linked-HTML state rows;
- 18 QMD occurrence classifications;
- four source builders;
- five frozen source CSVs;
- ten paired PNG/SVG endpoints; and
- ten directly dependent pending or historical verifier, manifest, handoff,
  completion, and render-history records.

All 39 unique live paths with recorded identities rehashed exactly. The five
frozen display sources retain 6, 27, 27, 6, and 417 rows, respectively. The
five PNGs retain dimensions 1680 by 1000, 2640 by 3360, 2640 by 3360, 1680 by
919, and 2944 by 1888. Every current SVG contains one `Wake`, one `Pre-sleep`,
and one `Sleep` display token, with no `Daytime` or `Evening` token. This is the
pre-change display state, not the requested final state.

The only reader-facing Brown-report use of `Evening` that denotes the exact
three-hour window occurs in
`audit/analyses/brown_adherence/07_results.qmd` at line 394. It is included as
one exact source substitution. Bibliographic titles and ordinary clock-time
uses of evening are outside the substitution and remain protected.

Other `Wake` occurrences in the integrated Stage 3 QMD identify the internal
analytical state, predictor, cycle anchor, sample, contrast, or source-data
value. They must not be replaced globally. The exact display-oriented
occurrences are enumerated in the change matrix. The participant-profile prose
will explicitly say that the source-data state remains `Wake` while the figure
shows it as `Daytime`.

Genuine uses of `context` remain necessary where they distinguish the primary
near-eye sensor position, complementary chest sensor position, bedside sleep
environment, or behavioral interpretation. The proposed changes prohibit only
category names such as `Daytime context`, `Pre-sleep context`, `Sleep context`,
or `recommendation context`.

## Exact replacement matrix

`audit/report_harmonization/report018_brown_stage3_window_label_change_matrix.csv`
contains 42 unique actions:

- 19 exact QMD substitutions;
- 13 exact builder substitutions; and
- ten candidate-first durable asset transitions.

The matrix notation `<<NL>>` means one LF byte. Every text preimage currently
occurs exactly once. Applying all 32 text substitutions in memory and reversing
them in reverse order recovers all six current files byte-for-byte.

The prospective text identities are:

| Target | Bytes | SHA-256 |
|---|---:|---|
| Linked `07_results.qmd` | 29,578 | `d941731ae4cef7e4d903c9968407694bd3554ff805a1d26a04e9daaee1bb3aaa` |
| Integrated Stage 3 QMD | 56,275 | `a57d26e7174a2223607e13c2071b3f9073e40c1b7749895b19705dea3856e65e` |
| Main Stage 3 display builder | 21,156 | `9746ab27c8fc268e040b6045b8939feec6e057e291e0dac08ecf1d137e02ef27` |
| Work-day and coverage builder | 16,195 | `e7a06c8cf645d900d72a769cdf5a8163c7471879c70646393ab7c96ceef731e0` |
| Free-minus-Work builder | 18,033 | `fa12843257bf43136286e783ece85802ded974a9f4fa1350a2108b6dbb3ab0e3` |
| Participant-profile builder | 20,831 | `86b019d44d313ad7a9da80bdb3ca34f0f7c8ff5f6259c1724daadaeb5d21c160` |

The prospective Stage 3 QMD preserves its numeric-token multiset, 38 inline R
expressions, relative target multiset, chunk-label set, and executable R chunk
text. The linked `07_results.qmd` preserves its numeric tokens, inline R, and
links. All four prospective builders parse under R 4.6.1.

## Caption and display contract

The five affected endpoints are:

1. `fig-main-adherence-levels`;
2. `fig-main-site-workday-adherence`;
3. `fig-main-site-free-work-contrasts`;
4. `fig-main-coverage-sensitivity`; and
5. `fig-participant-state-raincloud`.

Each caption will identify `Daytime`, `Pre-sleep`, and `Sleep` as Brown et al.
recommendation windows. None will call them contexts. The axis and facet
changes are display mappings only. Internal data retain `Wake`, `Pre-sleep`,
and `Sleep`.

The wording preserves `recommendation adherence` as the outcome. It also
preserves every number, confidence interval, raw or adjusted p-value,
multiplicity family and decision, sample, model identity, source-data row,
site, marker, reference line, legend meaning, and non-causal qualification.
In particular, Figure 2 keeps seven emphasized sites and 20 open circles;
Figure 3 keeps five orange diamonds, three black asterisks, the 27-member FDR
family, and both reference lines; and the participant display keeps 417 points
from 139 anonymous complete profiles.

## Pending BA-M package and direct dependencies

The pending BA-M owner package remains exact:

- Stage 3 QMD `ea8f639a5b58ef591bf4716928ef32db4de68b30e157e2670867a5c0ee2d9c05`;
- Stage 4 QMD `8fc81d9b28b60a3ab28315b6e83f884e55d2f8cbcb7cb374312414b1922c9c92`;
- Figure 3 builder `7d65e028764d522635438b10cd0573315a32ace1753b8c53762b074164bd05fd`;
- Figure 3 PNG `2467061413fc1da4834eb92072598f5af46526631e573401bbe3fa874eb4695a`;
- Figure 3 SVG `8e5eee7e55b3e99953de87f6f00698c28903f5445db1bf01e15c662851123e8d`;
- verifier `cc396bd7a0d38fbc7c6361e428436e67e4253cd0f27590fcf309e469380b2b08`;
- 38-row non-circular owner manifest
  `eec6b7c03da8769b32d828b5eae8f8cec6819dc27ac9e6d6a8824c5d37eb16e1`;
- owner handoff `9724e6efbb10a71f35c831469dbab72a666b851bb24b1b02adb86f64bcd117ba`;
  and
- completion record `8a33fa9eee353e4debad4ab4f1b03ee76e08f80774b66af95db9a20526af8e43`.

The 38-row manifest reverified 38 of 38 exact, unique paths. Stage 3 contains
zero reader-facing BA-M4 or BA-M6 token. Stage 4 remains a provenance document
and immediately translates its retained internal identifiers.

The proposed order deliberately does not rewrite any existing verifier,
manifest, handoff, or completion record. These records are historical evidence
for earlier accepted states. A new dedicated refresh, focused verifier,
non-circular current display manifest, completion record, and handoff will
carry the new direct dependencies. This prevents circular or self-hash rows and
avoids falsifying historical identities.

## Candidate and render boundary

The proposed owner order is at
`audit/report_harmonization/owner_orders/brown_stage3_window_label_and_ba_m_display_repair_proposed.md`.
It permits no current action. If central coordination approves and dispatches
it, the owner will:

1. apply only the exact text matrix;
2. create one dedicated refresh that reads only the five frozen CSVs;
3. generate all ten PNG/SVG candidates outside durable targets;
4. prove source-row, aesthetic, geometry, marker, line, SVG, decoded-pixel,
   typography, and visual equality except for the authorized text bands;
5. promote the ten accepted assets once; and
6. seal one new non-circular source/display package.

No HTML or Quarto command belongs to that order. After independent
source/display acceptance, the integrated Stage 3 page may receive a separate
serial render release using the established R 4.6.1 and semantic-repair
boundary. Because the matrix also corrects the one linked `07_results.qmd`
sentence, that page needs its own serial target release or an explicit central
decision to retain its stale HTML. Stage 4 remains frozen.

H06_daily and H03/H04 remain queued and inactive.

## Read-only verification

Command:

```text
/Library/Frameworks/R.framework/Resources/bin/Rscript --vanilla \
  scripts/report_harmonization/check_brown_stage3_window_label_package.R \
  /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
  /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

Result under R 4.6.1:

```text
BROWN_STAGE3_WINDOW_LABEL_READ_ONLY_AUDIT=PASS inventory=57 pins=39 matrix=42 qmd=19 builders=13 assets=10 ba_manifest=38 R=4.6.1
```

The next action is independent central review of this package. The Brown owner
must not be woken from this read-only audit.
