# REPORT-018 residual accessibility limitations

The 37-page corpus is render-complete, live-exact, free of rendered error
nodes, and internally link-complete. The final R 4.6.1 DOM audit records two
pre-existing accessibility limitations without changing any reader source or
HTML.

1. Eight older pages retain legacy `gt` identifier and `headers` patterns:
   Preparation 01 through 07 and Descriptives. Across those exact pages, 5,509
   header tokens do not resolve to one table-local identifier and 63 repeated
   non-SVG document identifiers remain. Every other corpus page has zero such
   finding. The exact page-level counts are sealed in
   `corpus_semantic_disposition.csv`.
2. The landing page has 24 informative, captioned images without alt text.
   Descriptives has 17 captioned images with empty alt text, all explicitly
   marked `role="presentation"` and `aria-hidden="true"`; these are accepted
   as decorative representations. Every other figure image in the corpus has
   nonempty alt text. The exact classification is sealed in
   `corpus_image_alt_disposition.csv`.

One H06 companion table contains header cells only, with no data cells. Its
five header cells each use `scope`, so the lack of `headers` attributes is an
accepted scope-only table structure rather than a missing association.

These limitations are outside the author-directed render-completion boundary.
They remain eligible for a future accessibility-specific amendment. The final
REPORT-018 acceptance does not claim that these legacy pages are fully
accessible.
