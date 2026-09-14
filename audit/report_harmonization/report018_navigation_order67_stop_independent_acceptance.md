# REPORT-018 navigation Order 67 stop: independent acceptance

Date: 2026-09-02

Disposition: `ACCEPTED_CANDIDATE_BOUNDARY_STOP`

## Accepted stopped state

The navigation owner passed the exact Order 67 dispatch and R 4.6.1 preflight,
created an isolated 892-file candidate, and applied only the authorized CSS
rule. The candidate stylesheet matched the prescribed SHA-256
`736b7f1309d8ddacda8b70999d37e6ee26920b9927cf1ae7215ec891a94b2dfe`,
4,611 bytes. The owner then stopped at the first candidate browser failure,
before production promotion.

The accepted owner record is
`audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/order67_fail_closed.md`,
SHA-256
`7fbf139addab800060de16d4688853f1e426cf55a04451d5814aa709f24f9396`,
2,501 bytes. Its 43-row non-circular evidence manifest is SHA-256
`e5bd594c9ffe6bdbbb675307646b130bf141ba00eef59896f356ca3e38ce2240`
and reproduces 43 of 43 members by exact hash and byte count under R 4.6.1.

At 708 by 1,000 pixels, H06 produced ten cloned links but zero visible or
effectively focusable links. The screenshot is SHA-256
`2e44f4e1660833d59738fa50882dc08fc71dacfaa1e95a55b450a0dd8ac095ff`.

## Independent classification

The durable checker
`scripts/report_harmonization/check_report018_navigation_order67_stop_and_js_scope.R`
passes under R 4.6.1. It confirms:

- all 43 stopped-state members and all 892 production build files are exact;
- source and built production stylesheets remain at their 4,548-byte
  preimage, so no promotion occurred;
- H06 is the only accepted route that embeds the Nature Health stylesheet
  instead of referencing the external stylesheet;
- all 37 routes contain one byte-identical mobile-TOC cloning script;
- 31 routes contain at least one `collapse` list within the desktop TOC;
- 10 routes place `collapse` on the root list and are wholly hidden after
  cloning;
- the 31 routes contain 115 such lists in total, including nested lists; and
- the candidate server stopped and production remained unchanged.

The Order 67 external-CSS scope was therefore insufficient. This is a valid
fail-closed stop, not a task stall and not an H06 source, scientific,
semantic, table, figure, or content defect.

## Correct repair boundary

The failure is caused by copying Bootstrap presentation state from the
desktop TOC into the mobile clone. The narrow repair is to remove the
`collapse` class from the cloned root list and all cloned descendants while
leaving the source desktop TOC untouched.

The exact prospective shared include is SHA-256
`153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980`,
1,542 bytes. It adds only:

```js
list.classList.remove("collapse");
list.querySelectorAll(".collapse").forEach((element) => {
  element.classList.remove("collapse");
});
```

The checker proves one exact occurrence of the current script in each of the
37 HTML routes, 37 deterministic HTML postimages, and exact reversal for the
include plus every route. Each HTML grows by exactly 154 bytes and no other
byte changes.

Because the accepted pages embed the include at render time, a no-render
repair requires a candidate-first shell transformation of the shared include
and all 37 HTML copies. A direct HTML-hash-only corpus-manifest reseal produces
the exact prospective manifest SHA-256
`5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b`,
11,479 bytes, while preserving all 37 source paths and source hashes.

This boundary must be authorized by a separate order. It must preserve both
stylesheets, all page content and semantics, all scientific artifacts and
sources, and all historical evidence. No Quarto or QMD execution is needed.
