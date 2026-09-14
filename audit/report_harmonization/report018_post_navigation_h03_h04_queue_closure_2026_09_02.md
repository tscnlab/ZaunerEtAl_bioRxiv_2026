# REPORT-018 H03/H04 post-navigation queue closure

Date: 2026-09-02

Queue item: 3, H03/H04 Supplementary display and language

Disposition: **FULLY SUBSUMED BY LATER AUTHOR-ACCEPTED DISPLAY TOPOLOGY; NO OWNER DISPATCH**

## Controlling later decision

The queue originally anticipated one Supplementary display pairing the H03
and H04 category-by-site summaries, followed by the H04 temporal display. The
author later selected a different final topology:

1. H04 activity is main Figure 3 as one accepted four-panel composite. Panels
   A to C provide the temporal display and panel D provides the
   activity-by-site estimates and support.
2. H03 light source is Supplementary Figure S7 as one accepted four-panel
   composite. Panels A to C provide the temporal display and panel D provides
   the light-source-by-site estimates and support.

This later author decision supersedes the queue's earlier H03/H04 pairing and
vertical-placement instructions. It does not leave an unimplemented H04 owner
task.

## Requirement reconciliation

| Queued requirement | Final accepted disposition |
|---|---|
| Pair `fig-h03-primary-estimates` and `fig-h04-primary-estimates` in Supplementary Information | Superseded by the author's main-versus-supplementary decision. Each domain is now internally combined with its corresponding temporal display. |
| Place `fig-h04-temporal-near-eye` immediately below the paired display | Superseded. H04 temporal panels A to C and site panel D are one real main Figure 3 composite. |
| Select `tbl-h04-near-site-factorization`, supported by `tbl-h04-category-support` | Subsumed into main Figure 3 panel D and its P/D/H support header. The accepted source values and support contract remain controlling. |
| Use the H03 category-by-site interaction model | Preserved in Supplementary Figure S7 panel D and its caption as the light-source-by-site interaction model. |
| Use the H04 activity-by-site interaction model | Preserved in main Figure 3 panel D and its caption for the five named categories. `Other` remains the accepted additive display-only estimate. |
| Use `site-average estimate` for the equal-site fitted-log-mean estimand | Preserved in both accepted composites and captions. |
| Preserve scientific values, intervals, p-values, FDR decisions, category order, geometry, palette, non-colour cues, missing cells, model flags, weights, and display-only status | Preserved by the H03 acceptance and H04 revision 3 non-circular acceptance. No scientific source was recomputed for this closure. |
| Preserve the exact accepted five-category H04 near-eye sample contract | Preserved in main Figure 3: 126 participants, 724 participant-days, 16,135 unique participant-hours, 16,875 generated long rows, 16,135 effective weighted hours, nine sites, and 4,746 exact-zero participant-hours, with 1/k weighting. |

## Current integration evidence

- The finalized selection source places H04 as main Figure 3 and H03 as
  Supplementary Figure S7. It is sealed at SHA-256
  `1e29b5f4a83343978bbb4bf8e841072d1b941832991e3fa78139517738044676`.
- The current Nature Health manuscript source includes the accepted H04
  Figure 3 selection asset and its four-panel caption.
- The current Supplementary Information source includes the accepted H03
  four-panel Supplementary Figure S7 and its interaction-model caption.
- The accepted H03 PNG is
  `ae5174afa8d9b57b5d9a635dfe2320482105d72007882db7513e29380271f52d`.
- The accepted H04 selection PNG is
  `22d402974fc0df26c77536e5db8af166e87637f2192ea4cc4f01da2d98ebb122`.

## Boundary

No H03 or H04 owner was activated. No file owned by either analysis task was
edited. No analysis, prediction, inference, resampling, source-data
regeneration, Quarto render, or HTML mutation was performed. The existing
manuscript source integrations are cited as evidence only and were not edited
by this closure.
