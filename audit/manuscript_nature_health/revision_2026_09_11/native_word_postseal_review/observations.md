# Native Word figure observations

Date: 2026-09-11. Microsoft Word 16.112.2, build 16.112.26082125.

All 21 figure appearances in the stopped complete-SVG candidate were inspected
through the native Word interface. The inspected file remains unsaved with
AutoSave off. These checks establish the observations below, not acceptance of
the candidate. Existing table defects, the separate LibreOffice S17 defect,
and the Brown scientific replacement remain unresolved.

| Display | Word page | Observation |
|---|---:|---|
| Main Figure 1 | 6 | Overview components displayed. |
| Main Figure 2 | 14 | All four fitted-pattern panels displayed. |
| Main Figure 3 | 23 | Temporal and site-interaction components displayed. The existing caption follows on page 24. |
| Supplementary Figure S1 | 70 | Distribution panels displayed. |
| Supplementary Figure S2 | 71 | Time-series and metric-derivation components displayed. |
| Supplementary Figure S3 | 72 | Photoperiod range graphic and site legend displayed. |
| Supplementary Figure S4 | 73 | Adherence estimates, intervals and legend displayed. |
| Supplementary Figure S5 | 74 | **Failed.** Only the outer A/B tags appear; both plot panels are absent. |
| Supplementary Figure S6 | 78 | Anonymous participant raincloud, connecting lines and summaries displayed. |
| Supplementary Figure S7 | 81 | Both components displayed, but the composite is cramped. Preserve the author's request for separate images. |
| Supplementary Figure S8, A-C | 89 | Temporal estimates, relative curves and support panels displayed. |
| Supplementary Figure S8, D | 90 | Separate site-interaction panel displayed with its notes; preserve this existing two-appearance layout. |
| Supplementary Figure S9 | 91 | Paired-position contrasts and intervals displayed. |
| Supplementary Figure S10 | 92 | Day-type temporal panels and notes displayed. |
| Supplementary Figure S11 | 93 | Daily-activity-status temporal panels and notes displayed. |
| Supplementary Figure S12 | 94 | Site-specific routine-contrast panels and notes displayed. |
| Supplementary Figure S13 | 98 | Light-behaviour display, native colour legend and labels displayed. |
| Supplementary Figure S14 | 101 | Visual-sensitivity contrast panels and labels displayed. |
| Supplementary Figure S15 | 103 | Both components displayed, but the composite is cramped. Its second component contains its own subpanels. Preserve the author's request for separate images. |
| Supplementary Figure S16 | 105 | Age/site selection display and internal panels displayed. |
| Supplementary Figure S17 | 107 | Native Word is sans serif and its internal note is present. This does not resolve the separately observed LibreOffice serif substitution and note clipping. |

The screenshots were emitted in this task's tool transcript. The native zoom
control was 130%, not 90%; earlier informal coordination messages naming 90%
are superseded by this direct control read. No numerical values, model output,
figure geometry, scientific labels or manuscript prose were evaluated or
changed by these rendering checks.

## SVG structure relevant to the repair

The exact S5 source has two `data:image/svg+xml;base64` image payloads. This
nested-image construction is a plausible compatibility mechanism for Word's
absent panels, but it has not been experimentally isolated. The owner should
test a native-vector composition or separate accepted vector components within
the new display boundary. Do not infer a scientific-data failure.

The exact S7 and S15 files each contain two `data:image/png;base64` image
payloads. They are SVG containers around raster panels, not fully native-vector
scientific panels. Their requested split must use accepted vector component
exports if the author's SVG requirement is to be satisfied. Do not merely
rename or extract the raster payloads and call them vectors.

Main Figure 1 contains one PNG within the overview illustration. Its role and
any explicit illustration exception need to be documented by the display
owner; this record does not classify an illustration as a scientific raster
failure. The remaining 16 exact SVG sources have no image elements, including
no recursively embedded image elements. `svg_structure.json` records the
structural inventory without modifying any input.

## Remaining release and evidence boundary

S2 must keep every site column in one horizontal set with complete, uncropped
distributions. S5/S6/S10 manuscript-table fonts need correction in the image
capture pathway; the separate editable Arial table documents are not implicated.
These changes and the S7/S15 splits are with the coordinator and harmonizer for
one consolidated display repair. No repair, save, render or promotion was
released during this native review.

The Mac locked again after the full figure sweep. A fresh native screenshot was
already emitted for the S5 failure, but the requested durable screenshot archive
was not completed. The non-circular observational record manifest is therefore
not a screenshot-complete addendum seal and must not be represented as one.
Native screenshot archiving and verification of the eventual repaired candidate
remain pending. The original Order72d candidate and stopped manifest are
preserved byte-for-byte.
