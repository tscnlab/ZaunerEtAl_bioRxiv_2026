# REPORT-018 H06 Order 66b visual stop: independent acceptance

Date: 2026-09-02

Disposition: `ACCEPTED_SHARED_MOBILE_TOC_DEFECT_STOP`

## Accepted stopped state

The H06 owner completed the sealed corrected verification and focused test,
then stopped during secure loopback QA on the first genuine reader defect.
The accepted owner record is
`audit/hypotheses/H06/employment_eligibility_sensitivity/order66b_result_no_rerender_completion/H06_order66b_visual_fail_closed.md`,
SHA-256
`121c7b333cbdb4c8d0c8de1dcddb422cd6d209d58c4c66586d144b1c2ec62fcc`.
Its 60-row non-circular manifest is SHA-256
`4c6cc8cc9bed866e66ca6423ecb739e94d1774e542650c8fe1f5b1d3ff56bad8`
and reproduces 60 of 60 paths by exact SHA-256 and byte count under R 4.6.1.

The stopped browser evidence reproduces finding
`H06-ORDER66B-VISUAL-001`. At 708 by 1,000 pixels, the mobile **On this page**
`details` element opens and its plus changes to a minus, but all ten cloned
section links remain hidden and the panel is visibly blank. The defining
screenshot is SHA-256
`318ed59d574a56161b986f3fc0d1a50088e853a28bb7b470d177a322b6eef0b3`.

## Independent classification

The durable checker
`scripts/report_harmonization/check_report018_mobile_toc_collapse_defect.R`
independently passed under R 4.6.1. It verifies the 60-row owner seal, ten of
ten hidden H06 links, unchanged build and protected state, and the exact
shared-shell mechanism.

The shared include clones the first direct `ul` from desktop `nav#TOC` into
the mobile `details` element but does not remove Quarto's optional `collapse`
class. Bootstrap therefore keeps the cloned list at `display: none` even when
the outer `details` is open. A complete DOM inventory of the accepted 37-page
corpus finds this class on exactly ten routes:

- preregistration deviations;
- H02, H03, H04, H05, H06, H06 daily, H07, H10, and H11 result pages.

All 37 pages contain exactly one mobile-TOC script and one direct desktop TOC
list. The other 27 routes currently lack the optional `collapse` class and do
not demonstrate this failure mode. The source and build copies of
`styles-nathealth.css` remain byte-identical at SHA-256
`051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87`.
The include and profile remain exact at `926a5fc0...` and `e54c7179...`.

This is a shared responsive-navigation defect, not an H06 source, result,
scientific, semantic, table, or figure defect.

## Preserved H06 checks

Before the stop, the central corrected checker passed exactly once, the
focused reader-source test passed exactly once, desktop QA passed all 14
tables and six figures, the employment-eligibility section was complete, and
the 708-pixel page, figures, tables, site-table scroller, and main navigation
were contained and usable. The server was stopped, no listener remained, and
the 892-file build and protected inventories remained unchanged across QA.

The H06 HTML remains SHA-256
`b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9`,
4,898,662 bytes. H06 is held at result acceptance pending repair and bounded
completion of the deferred visual and link checks.

## Next boundary

A separately sealed shared-navigation order may test and add one narrowly
scoped mobile-TOC CSS override, synchronize only the source and built Nature
Health stylesheet, verify all 37 HTML files remain byte-identical, exercise
all ten affected routes and representative unaffected routes, finish the
deferred H06 checks, and seal one result. No Quarto render, HTML rewrite,
hypothesis source edit, scientific computation, corpus-source reseal, or
other-site change is authorized by this acceptance itself.
