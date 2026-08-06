# H11 application record for gap-timing-unaware terminology

Decision ID: `REPORT-010`  
Decision date: 2026-08-01  
Status: **approved; H11 application recorded**

## Scope

The authoritative shared decision is
`audit/decisions/gap_timing_unaware_dataset_terminology.md`. This H11-scoped
record applies it to visible reader-facing prose, tables, figures,
captions, legends, annotations, and link text in H11 Stage 3 and Stage 4. It
does not rename internal scenario IDs, filenames, code objects, or provenance
records, and it does not alter or reopen any scientific calculation.

The Stage 2 implementation/V0 comparison remains an author-facing audit and
may retain historical labels where they are necessary to distinguish the
submitted implementation and trace its artifacts.

## Required terminology

Use the exact term **gap-timing-unaware dataset** for the sensitivity dataset
previously described as manuscript-prepared, alternative
manuscript-prepared, alternative coverage/gap/metric preparation,
rule-preserving, or similar.

At its first reader-facing use, explain all three points plainly:

1. the gap-timing-unaware dataset still passed the general 50%-per-hour and
   80%-per-day coverage rules;
2. **gap-timing-unaware** means that the timing of the remaining missing
   observations is not used for an additional metric-specific adjustment; it
   does not mean that gaps, missingness, or coverage were ignored; and
3. for contrast at this first explanation only, the primary dataset could be
   interpreted as a **time-sensitive primary metric dataset**.

After that first explanation, call the main scenario only **the primary
dataset**. Do not retain a standing alternative label for it. Continue to use
**the gap-timing-unaware dataset** for the sensitivity scenario.

## Prohibited visible Stage 3/4 labels

Do not use these historical or construction labels in visible Stage 3/4
content:

- V0;
- legacy;
- previous;
- manuscript-prepared;
- alternative manuscript-prepared;
- alternative coverage/gap/metric preparation; or
- rule-preserving.

The prohibition does not apply inside folded/internal code, scenario IDs,
filenames, or provenance records when changing them would break traceability.

## Structural verification required at the later gate

Before any H11 Stage 3 or Stage 4 render is approved, its H11-scoped structural
test must verify the exact first-use explanation, continued use of **primary
dataset** and **gap-timing-unaware dataset**, and the absence of prohibited
historical labels from visible prose, table labels, figure text, captions,
legends, annotations, and visible link text. The test must not reject permitted
internal IDs, filenames, code, or provenance fields.
