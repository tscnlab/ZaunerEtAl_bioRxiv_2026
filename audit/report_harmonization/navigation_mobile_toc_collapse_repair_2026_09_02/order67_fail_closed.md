# REPORT-018 Order 67 fail-closed return

Date: 2026-09-02

Status: **STOPPED BEFORE PROMOTION**

## Passed boundary

The sealed preflight passed before candidate work:

- 25 of 25 dispatch members were exact, unique, and non-circular under R 4.6.1.
- The mandated central checker reproduced the 60-row owner seal, 10 of 10 hidden H06 links, exactly 10 affected routes, and the complete 892-file build.
- Source and built `styles-nathealth.css` remained byte-identical at SHA-256 `051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87`, 4,548 bytes.
- The accepted build had 892 of 892 exact files and zero symlinks.
- No competing navigation promotion, Quarto, Pandoc, semantic hook, shared-build writer, or loopback process was active.

The full candidate copy was exact before the repair. The single authorized CSS rule produced the prescribed postimage at SHA-256 `736b7f1309d8ddacda8b70999d37e6ee26920b9927cf1ae7215ec891a94b2dfe`, 4,611 bytes. The candidate then contained 891 unchanged build files and exactly one changed file, `styles-nathealth.css`, with zero symlinks.

## New candidate defect

The first required browser check failed on `notebooks/hypotheses/H06.html` at 708 by 1,000 pixels. Opening **On this page** produced ten cloned section links, but zero were visible. The cloned list retained class `collapse` and computed `display: none`.

Static inspection established the boundary mismatch:

- nine of the ten affected routes reference the external `styles-nathealth.css`;
- the newly rendered H06 result page has zero references to that stylesheet;
- H06 instead embeds the pre-repair Nature Health CSS inside its HTML; and
- the embedded CSS does not contain `.nathealth-mobile-toc ul.collapse { display: block; }`.

Consequently, changing only the source and built external stylesheet cannot repair H06. Repairing it would require an HTML change, a render, or another scope expansion, all explicitly prohibited by Order 67.

## Fail-closed disposition

Candidate QA stopped immediately. No promotion occurred. Neither production stylesheet changed, all 892 live build files remain exact, the 37-route corpus manifest remains unchanged, the browser tab was closed, the viewport was restored, the candidate server was stopped, and port 57331 has no listener.

The candidate postimage remains isolated under the recorded temporary candidate root. No retry, patch, HTML rewrite, Quarto execution, scientific execution, manifest reseal, commit, push, or upload occurred.
