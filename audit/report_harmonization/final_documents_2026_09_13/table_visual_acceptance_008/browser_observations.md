# Independent localhost observations

14 September 2026. Actual server route root: http://127.0.0.1:62011/.
All six complete owner screenshots were opened and visually reviewed before the live review. All six actual candidate routes were then opened using the selected in-app browser. Geometry checks are structural support, not a substitute for the viewed screenshots.

| Route | Table width CSS px | Desktop document width | Narrow document width | Narrow cell overflow |
|---|---:|---:|---:|---:|
| table_2.html | 1320.023 | 1440 | 693 | 0 |
| table_s2_part_01.html | 2088.008 | 1425 | 693 | 0 |
| table_s2_part_02.html | 2088.008 | 1425 | 693 | 0 |
| table_s2_part_03.html | 2088.008 | 1425 | 693 | 0 |
| table_s7_part_03.html | 896.008 | 1440 | 708 | 0 |
| table_s7_part_04.html | 896.008 | 1440 | 708 | 0 |

Desktop viewport: 1440 by 1000. Narrow viewport: 708 by 1000. A 15-pixel vertical browser scrollbar explains document widths below viewport width. No document extended beyond its viewport. All recorded source images were loaded.

Live screenshots inspected: S2 part 1 desktop and narrow interior/right end; S7 part 3 stable desktop; main Table 2 desktop and narrow right end; S7 part 4 narrow right end. In addition, all six whole-table owner screenshots were independently viewed. S2 grid and values stayed aligned with adequate Scaling width; distributions were complete. Table 2 confidence intervals stayed on whole lines. S7 sample labels were complete, with no break after participant-. Dense S2 secondary print text remains a qualification rather than an asserted final Word pass.

Keyboard scrolling reached rightMax 1437 for S2 part 1, 669 for Table 2, and 230 for S7 part 4. Window scrollX remained zero. All four S7 part-4 sample-unit spans occupied exactly one text rectangle. Browser warning/error log was empty.

The first S7 screenshot after a viewport change still used the prior width and was not treated as a 1440-pixel proof. The following stable screenshot was reviewed. No pixel crop or assumed rescaling was used.

QA tab closed and viewport reset. Server PID 90635 stopped with exit 0. Postflight: all 263 owner members exact. Listener check: lsof for TCP 62011 in LISTEN state returned no rows, exit 1. An initial unprivileged bind and later unprivileged stop were denied by the shell sandbox; exact escalated operations succeeded. No browser access denial occurred.
