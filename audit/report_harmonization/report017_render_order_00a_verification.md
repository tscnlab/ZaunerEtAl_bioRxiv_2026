# REPORT-017 Phase 4 render order 00a verification

Date: 2026-08-13  
Scope: central preregistration-deviation page and landing page only  
Status: **target renders and structural checks passed; one pre-existing source-link defect returned; current integrated visual review remains partial**

## Execution boundary

Quarto 1.9.37 rendered the two authorized targets serially through the Nature
Health profile with document execution disabled:

```text
quarto render notebooks/preregistration_deviations.qmd --profile nathealth --no-execute
quarto render index.qmd --profile nathealth --no-execute
```

The first sandboxed invocation could not open the macOS Sass cache database.
The same two exact commands then completed through the narrowly authorized
external `quarto render` execution. No R or knitr execution occurred. No other
QMD was rendered, and no full-project render was run.

## Source and configuration preservation

All three dispatch identities matched before rendering and remained unchanged
after both renders:

| Path | Pre-render SHA-256 | Post-render SHA-256 |
|---|---|---|
| `notebooks/preregistration_deviations.qmd` | `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d` | `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d` |
| `index.qmd` | `bde8b03095bc4d4a47a8398f4cf565b1d1aa6f1d1dc4989b81d91b9453898022` | `bde8b03095bc4d4a47a8398f4cf565b1d1aa6f1d1dc4989b81d91b9453898022` |
| `_quarto-nathealth.yml` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` |

`git diff --check` passed for all three dispatch sources. Rendering did not
edit any source or shared configuration file.

## Rendered identities

| Output | SHA-256 | Bytes |
|---|---|---:|
| `_build/nathealth/notebooks/preregistration_deviations.html` | `c033c1b8110e58375757e8ef8ac5c5d0dbf5f402a651454b247c1a622ded6880` | 160936 |
| `_build/nathealth/index.html` | `42e6887276d86e366b180b35b66288f5ce839d56225e60e9583e390e76b2bde0` | 405991 |

Both HTML files declare `quarto-1.9.37` as their generator and contain no
Quarto cell-error block.

## Structural verification

The focused R 4.6.1 source contracts passed:

```text
Rscript --vanilla tests/report_harmonization/test_country_coded_site_names.R
Rscript --vanilla tests/report_harmonization/test_navigation_contract.R
Rscript --vanilla tests/report_harmonization/test_reader_links.R
```

The current rendered HTML was then inspected read-only with `xml2`:

- all 86 authoritative deviation IDs occur exactly once as lower-case HTML
  anchors, with 86 corresponding level-three entry headings;
- the landing-page content link resolves to the rendered central deviation
  page;
- both pages contain the accepted H03, H04, H07, H09, and H11 companion
  additions exactly once in the sidebar;
- the comparison contract, H03-H11 gated-workflow page, assemble-artifacts
  page, and H06_daily are absent from rendered navigation;
- all nine rendered study-site labels on the landing page include country
  codes;
- the four approved non-site Munich names remain unchanged;
- all 1,210 rendered links have a nonempty visible or accessible label;
- no `file:` URL, absolute `/Users/` path, or `_build` path occurs in a
  rendered `href` or `src`; and
- the deviation page and landing page contain 17 and 10 table-of-contents
  links, respectively, with no empty heading.

`supplementary_information.html` remains absent by design because this render
order explicitly excluded it. Its navigation target therefore remains pending
the later serial render.

## Returned source defect

The landing-page methods section links to `RQ1.qmd`. Because that legacy page
is explicitly excluded from the Nature Health render set, Quarto leaves the
link as `RQ1.qmd` and copies the QMD into the output directory instead of
creating a reader-facing HTML target. The link therefore opens source text,
not the accepted Nature Health H01 report.

This is a pre-existing `index.qmd` source defect at line 546. The dispatch
instructed the coordinator to return a scoped source defect instead of editing
the held landing-page source, so no repair was made. A later authorized source
change should point dynamically to `notebooks/hypotheses/H01.qmd` or remove
the obsolete legacy reference after scientific-content review.

## Visual review

The sealed 1440 x 1800 preview for the unchanged deviation-page source was
reviewed directly. Its title, introductory hierarchy, glossary callouts, body
text, margins, wrapping, and first-viewport entry structure are readable and
show no overlap or clipping. Preview SHA-256:
`733b624d6bfc182240d126880d36754792e06c5f685aa6dc5600830a2ecb2a0f`.

The current integrated `file://` pages could not be opened by the available
browser because local-file navigation is blocked by its URL policy. The
rendered DOM checks cover headings, navigation membership, entry hierarchy,
link labels, and error/clipping proxies, but they do not constitute a complete
current full-page visual inspection. No alternate browser or local-server
workaround was used. Current integrated visual acceptance therefore remains
pending together with the later serial render audit.

## Gate disposition

This order completed the two requested target renders without source drift or
scientific execution. REPORT-017 and DOC-001 must remain open because the
returned landing-page source-link defect, the explicitly deferred
supplementary-information render, the remaining inbound owner-page renders,
and the final integrated visual and HTML audits are still outstanding.
