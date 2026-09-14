# H06 Order 66b no-rerender visual QA stop

Date: 2026-09-02

Status: `FAIL_CLOSED_ON_NARROW_SCREEN_TOC_INTERACTION`

## Disposition

The sealed corrected verifier and the unchanged focused reader-source test
both passed exactly once. Secure loopback QA then established a genuine
narrow-screen interaction defect in the existing H06 result page. Order 66b
requires an immediate stop on such a defect. No source or HTML was patched,
and no render was run.

The result source and scientific content remain accepted. The current result
HTML is not yet accepted as the final reader endpoint because its collapsed
mobile table of contents does not reveal its links.

## Corrected verification

The central R 4.6.1 checker returned:

```text
H06_ORDER66A_STOP=ACCEPTED manifest=33/33 failures=5/5 document_ids=1911 unique=PASS tables=14 headers=421 captions=14 external_qmd=1 dispatch=21/21 build_delta=6 semantic=424 sensitivity=46/46 report=31/31 R=4.6.1
```

The unchanged focused test returned:

```text
PASS: H06 employment-eligibility reader integration; R 4.6.1; 2 QMD sources; 3 stored sensitivity tables.
```

The two console records are preserved in this directory. The failed Order 66a
verifier and all stopped evidence remain unchanged.

## Visual checks completed before the defect

At 1,440 by 1,000 pixels, the page has no document-level horizontal overflow.
The desktop navigation and table of contents are visible. All 14 reader tables
were inspected individually and have complete captions, aligned content, and
no clipping or overlap. All six figures were inspected individually, have
complete captions and alternate text, and render at approximately 642 pixels,
the accepted 170-mm display width. Their text and content are complete and
legible under the recorded final-size contract.

The employment-eligibility section is present and legible. It shows the
near-eye-only scope, exact sample flow, all three estimates and confidence
intervals, FDR-adjusted p-values, stability classifications, the retained
day-type heterogeneity result, model-check qualification, and three source
links.

At 708 by 1,000 pixels, the document again has no horizontal page overflow.
The main content and all six figures are 642 pixels wide. All tables remain
contained. The site-specific table is 700 pixels wide and is correctly held
inside a 642-pixel horizontal scroller. The collapsed main navigation opens
its six reader entries and closes normally.

## Genuine defect

Finding: `H06-ORDER66B-VISUAL-001`

At 708 by 1,000 pixels, activating **On this page** changes the plus icon to a
minus and opens the surrounding `details` element. The resulting panel is
blank. The DOM contains all ten expected section links, but every link remains
hidden because the nested list retains its collapsed state. The screenshot
`narrow_708x1000_on_this_page_open.png` records the visible blank expansion,
and `browser_observations.json` records the open control and ten hidden links.

This is a broken reader interaction, not a scientific or sensitivity-result
defect. The 720-by-500 zoom-equivalent check and remaining link and console
checks were not continued after the stop condition was reached.

## Teardown and preservation

The loopback server was bound only to `127.0.0.1:48731` and served only
`_build/nathealth`. It returned HTTP 200 for the H06 result page. The server
was stopped, no listener remains, the browser viewport override was reset,
and the agent-created tab was closed.

The pre-QA and post-QA build inventories contain the same 892 paths, SHA-256
values, and byte counts, with zero symbolic links. Their CSV serialization
differs only in optional quoting. The result HTML remains SHA-256
`b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9`,
4,898,662 bytes. The result and preparation sources, held preparation HTML,
focused test, scientific artifacts, H06 handoff, profile, lockfile, Sass
cache, H06_daily files, manuscript, shared configuration, and ledgers remain
unchanged.

## Next gate

The next action requires independent acceptance of this stopped package and a
separately authorized repair of the shared or page-specific mobile table of
contents behavior. No repair, rerender, preparation-page render, or later
target is authorized by Order 66b.
