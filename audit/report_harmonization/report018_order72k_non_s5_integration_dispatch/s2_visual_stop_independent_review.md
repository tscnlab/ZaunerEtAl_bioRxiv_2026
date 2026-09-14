# Independent S2 visual-stop review

Disposition: confirmed visual failure, with preserved scientific content.
Gate: `REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW`.
No corrected capture, final document or canonical promotion is accepted.

## Independent evidence

R 4.6.1 verification passed 11/11 preservation and structural checks. All 295
stopped-package members and 854 pre-recovery pin rows remain exact. Direct
comparison against the immutable full manuscript HTML confirms all 244 S2
body cells character-for-character, all 17 distribution payloads, three
complete repeated headers and the final notes. Comparison with the original
unrendered fragment differs only in HTML whitespace. The three parts retain
14 columns, 17 data rows and six group rows. Table 3 remains byte-exact.

The first failed whitespace-sensitive checker was not erased. The independent
review used the immutable full rendered manuscript as an additional baseline,
not only the Writer's captured source extraction. No scientific values were
recalculated and no missing content was excused as whitespace.

## Visual failure confirmed

After Writer released lease 002, Harmonizer inspected all three existing PNGs
with the local image viewer at original resolution. No new capture or browser
session was created. The following defects are directly visible:

- Part 01: `HH:MM` is cut at the Unit column boundary in duration rows;
  `threshold` is cut in Scaling.
- Part 02: `threshold` is cut in Scaling in the dose and level rows.
- Part 03: `HH:MM` is cut above `clock` in the timing rows.

The fixed widths are 40 CSS pixels for Unit and 50 for Scaling, both in the
unchanged capture helper and the prepared candidate CSS. The helper's text
wrapping and rectangle checks address only numeric columns 3 through 12.
They do not test Unit (2) or Scaling (13), explaining why that limited check
could pass despite visible clipping. All distribution plots are visible in
the inspected images; that does not cure the label defect.

## Focus of any separately released repair

Measure the longest unbreakable Unit and Scaling text using the actual
rendered font and cell padding, then allocate sufficient widths without
shortening labels or altering values. Keep table, capture-wrapper and viewport
widths consistent so widening these columns cannot clip a neighboring column
or distribution. Extend text containment to these two columns, preferably
all relevant table text, and inspect every part at original and intended
Word size. Preserve the already passed numerical wrapping and all source
characters, distribution images, headers and notes. Reuse S5/S6/S10 captures.

This is a repair recommendation, not another execution allowance. No S2
trial remains. The consolidated selection HTML/main HTML/main DOCX correction
pass is unused, and assembly/office QA are still unperformed. No Order72k
manuscript DOCX exists. Native Word inspection awaits an unlocked Mac.

## Context and closure

The review used the create-gt-tables guidance for backend fidelity and the
separation between content and visual verification. Installed versions are
R 4.6.1, gt 1.3.0 and Quarto 1.9.37. The candidate default project, scoped
S2 CSS, source include and capture helper were inspected; no brand file was
found and no style or dependency was changed by Harmonizer. No new HTML,
PDF, Typst or Word render was performed for this review.

Writer released lease 002 and stopped its server at 19:52:17 UTC. The
independent listener check found no listener on port 58005. No task visual
surface remains allocated. The author-unlock request and paused heartbeat
remain as reported. Brown/S5, optional H11 and canonical promotion stay held.
