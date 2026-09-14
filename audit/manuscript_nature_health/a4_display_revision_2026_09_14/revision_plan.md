# Author-requested A4 display revision

14 September 2026. This is a new candidate-only revision after the author approved the cumulative manuscript text changes. Accepted earlier packages remain immutable. No scientific computation, data/model change, figure redraw, or unrelated prose edit is authorized.

## Controlling request

The author requested A4-only pages in the Word manuscript, proportional figure sizing, full-text-width main Figures 1 and 2, portrait main Figure 3 and Table 2, landscape Table 3, and appropriate A4 portrait or landscape supplementary pages. Table S4 should fit one page, with its redundant FDR-family column hidden if needed. Table S7 should use two consistent-width parts with compact exact-sample line breaks. Figure S8 should be one complete appearance. Current Figure S15A and S15B should become separately numbered figures with separate captions, with consequent cross-reference updates only. S4, S7, S8 and the S15 split also apply to the webpage. The active Harmonizer build must not be interrupted.

## Inputs and findings

- Main accepted Word: `audit/manuscript_nature_health/final_pagination_completion_2026_09_14/deliverables/Nature_Health_manuscript.docx`, SHA-256 `325c3a8e3a76ea225970f80e177ceed0bbdd592b72e79196d154597f3581250b`.
- Accepted display/native package: `audit/manuscript_nature_health/final_format_completion_2026_09_14/`, manifest `86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2`.
- Accepted HTML in that package: `project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html`, SHA-256 `752ee27291e7970d28fc369c1ad3c396dc8894f483aa9864e65b9edea638df17`.

Read-only OOXML inspection found no non-proportional stretching of main Figures 1 or 2. Figure 1 is 4.62 by 4.4 inches, matching its SVG aspect ratio of 1.05. Figure 2 is approximately 4.204 by 5.35 inches, matching its SVG aspect ratio of 0.78571. Both drawing extents and inner transforms agree. Both placements are smaller than full text width. Several sections are A3 from the previous readability enlargement, including Table 3 and Figure 3. The current request supersedes that page-size choice.

## Implementation boundaries

Work only in this new manuscript-owned root until coordination returns an additional explicit boundary. Do not edit live manuscript sources, accepted packages, shared scientific/report sources, or the active website candidate. Preserve all image source bytes, numerical cells, intervals, p-values, sample descriptions, model qualifications and existing scientific claim roles. Changes to cell line breaks, column widths, the redundant S4 family column, source-neutral captions and figure numbers must be individually recorded and reversible.

Use source aspect ratios, not independent width/height targets, for every Word drawing. Recheck both outer and inner drawing extents. Normalize each section to A4 portrait or landscape and fit each display with its caption. The actual result, not existing page numbers, controls final QA.

For S4, retain the existing note that all four tests form one FDR-correction set even if the repetitive body column is removed. For S7, retain every exact sample string; line breaks may separate the participant and participant-day components. The S15 split will use S15 for adjusted chronotype associations and S16 for observed timing patterns; existing age and biological-sex figures consequently become S17 and S18. Table numbering remains unchanged. Existing corrected S15B source bytes remain authoritative.

## Verification and coordination

Use R 4.6.1 for any consequential scientific verification; this task is limited to non-analytical document infrastructure and protected-string/identity checks. Use the bundled document runtime and renderer, never desktop LibreOffice. Render candidate Word outputs and inspect all final pages. Preserve the accepted converter-specific native/browser adjudications unless the new placement changes the relevant evidence.

The coordinator has been notified of the new request. No message or interruption was sent to the active Harmonizer. Return the final Word and a bounded, source-aligned webpage delta through the coordinator after verification. Record that all 20 prior text changes are author-approved and unchanged except for the newly necessary figure-caption and cross-reference edits.
