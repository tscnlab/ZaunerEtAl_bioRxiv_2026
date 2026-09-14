# Phase 4 table visual-QA clarification

Date: 2026-08-13  
Source: direct author instruction in the report-harmonization task

This clarification applies to the remaining serial REPORT-017 visual checks.
It does not authorize a source change, table export, artifact regeneration, or
additional render.

## Native HTML tables

A table rendered natively in HTML is judged primarily at a typical
desktop/laptop viewport. It must be reasonably usable there, with readable
type, understandable headings, intact captions and notes, and no clipping or
broken layout.

The 708-pixel check remains required for page integrity and responsive
behavior. A dense HTML table does not need to fit completely without scrolling
at that width. When horizontal space is insufficient, the controlling narrow
check is that overflow is contained and the horizontal-scroll affordance is
usable without damaging the surrounding page.

## Exported table images

When a table is an exported image, its PNG is the controlling visual artifact.
Inspect that PNG at its intended final display or export size. Verify readable
type, complete content, intact captions or notes where baked into the image,
and absence of clipping, overlap, distortion, or illegible compression.

Source-level and semantic checks still apply to any corresponding table code
or data, but they do not substitute for final-size PNG inspection.
