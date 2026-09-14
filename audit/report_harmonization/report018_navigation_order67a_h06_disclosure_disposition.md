# REPORT-018 Navigation Order 67a: H06 disclosure disposition

Date: 2026-09-02  
Status: **ACCEPTED INHERITED MARKUP DEBT; NONBLOCKING FOR ORDER 67a**  
Scope: structural and reader-interface classification only; no scientific computation

## Finding

Final production QA for Navigation Order 67a found five non-mobile `details`
elements in the accepted H06 result page. Four are content-bearing disclosures.
The fifth has the summary `Show technical source and figure checks` but contains
no child content after its `summary` element.

This fifth element is not a usable disclosure and must not be represented as
one. It is an inherited inert marker. The marker is immediately followed by the
visible `technical-source-and-figure-checks` section and then the visible,
content-bearing `figure-reproducibility` section. No technical content is
missing or hidden behind the inert marker.

## Independent reproduction

R 4.6.1 independently compares the retained pre-promotion H06 page at
`/private/tmp/nathealth-order67a-continuation-backup.NqZwGw/preimages/_build/nathealth/notebooks/hypotheses/H06.html`
with the promoted production page at
`_build/nathealth/notebooks/hypotheses/H06.html`.

The structural inventory is identical before and after the navigation shell
change:

- five non-mobile `details` elements;
- four content-bearing disclosures;
- one and only one empty marker, with the exact summary named above;
- the marker remains inside `models-and-inference`;
- the next two sibling sections remain
  `technical-source-and-figure-checks` and `figure-reproducibility`;
- the Order 67a shell reversal reconstructs the retained pre-promotion H06 HTML
  exactly.

The current H06 endpoint is SHA-256
`4883b77a2e225c8bad8628f1a04274f5d19d81aeb7cc493949707cdc6cd98e2f`,
4,898,816 bytes. The retained pre-promotion endpoint is SHA-256
`b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9`,
4,898,662 bytes. Their only accepted difference is the 154-byte mobile-TOC
script transition already proven by Order 67a.

## Disposition

`NAV-67A-H06-DISC-001` is classified as inherited reader-interface debt, not an
Order 67a regression, not missing content, and not scientific or semantic
drift. REPORT-018 does not open a new H06 content or cleanup loop for it.

Order 67a may complete its no-mutation QA and final seal with this exact gate:

1. The four content-bearing disclosures must open and expose their descendants.
2. Exactly one inert marker is permitted, and only with the exact summary,
   containing section, and following sibling sections sealed above.
3. The inert marker may toggle its own empty open state, but it must not be
   called content-bearing or useful.
4. The two following technical sections must remain visible and complete before
   and after that toggle.
5. The repaired mobile `On this page` disclosure is separate and must continue
   to open, close, and expose all 17 H06 links normally.
6. Any second empty marker, missing technical content, structural transition,
   or new QA defect is blocking.

The owner may update only Order 67a task-owned QA, classification, and final
evidence. No H06 QMD, HTML, CSS, include, corpus-manifest, scientific artifact,
or other production file may be edited or rendered. No Quarto, Pandoc, knitr,
semantic-hook, or manuscript command is authorized. The existing production
promotion remains the only promotion.

## Controlling identities

- Current mobile-TOC include:
  `153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980`
  (1,542 bytes)
- Current corpus manifest:
  `5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b`
  (11,479 bytes)
- Current H06 HTML:
  `4883b77a2e225c8bad8628f1a04274f5d19d81aeb7cc493949707cdc6cd98e2f`
  (4,898,816 bytes)
- Retained pre-promotion H06 HTML:
  `b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9`
  (4,898,662 bytes)

Final Navigation Order 67a acceptance remains required before the downstream
Nature Health manuscript HTML and DOCX render order may be released.
