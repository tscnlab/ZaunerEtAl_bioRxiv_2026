# REPORT-018 Order 71b2 Word-bookmark predispatch proof

Date: 2026-09-03

Disposition: `PASS_FOR_BOUNDED_REPAIR`

The Writer correctly stopped Order 71b after its one DOCX render and one
postprocessing pass, but before page rendering or canonical promotion. The
stopped candidate and protected canonical preimage share the same unresolved
internal-display-link defect, so this is not an author-block regression.

Independent read-only OOXML inspection reproduced:

- 124 internal hyperlinks with 102 unique target names;
- 179 unique bookmark starts in the preserved fresh raw DOCX, with 16 missing
  supplementary-figure targets;
- 173 unique bookmark starts in both the stopped candidate and protected
  canonical preimage, with 22 missing display targets;
- loss of the six main display bookmarks during wrapper-table replacement;
  and
- absence of 16 Supplementary Figure bookmarks in the fresh raw DOCX.

The exact missing set is:

`fig-study-overview`, `fig-daily-architecture`, `fig-activity-context`,
`tbl-participant-site`, `tbl-brown-adherence`, `tbl-metric-context`, `fig-s1`,
`fig-s2`, and `fig-s4` through `fig-s17`.

`fig-s3` already resolves and must remain unchanged. Every one of the 22
missing targets maps uniquely in the stopped candidate. The six main targets
map to their unique top-level `Figure 1:` through `Figure 3:` and `Table 1:`
through `Table 3:` caption paragraphs. The 16 supplementary targets map to
their unique Heading 3 paragraphs beginning `Supplementary Figure S<n>.` or,
for combined sections, `Supplementary Figure S<n> and Table`.

The repair can therefore add exactly 22 zero-width bookmark pairs without
altering any visible text, run, style, relationship, image, section, caption,
or scientific content. The preserved fresh raw DOCX, postprocessor preimage,
fresh capture manifests, protected outputs, and accepted source all match the
identities in the accompanying non-circular manifest.

One new no-Quarto, no-capture postprocessing pass from the preserved fresh raw
DOCX is eligible for a sealed continuation. A 23rd missing target, any
nonunique destination, any changed existing bookmark, or any other structural
difference must stop the continuation without page rendering or promotion.
