# REPORT-017 Preparation 06 narrow-visual stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/06_model_ready_datasets.qmd`  
Outcome: **STOP. The focused test and semantic audit pass, but the opening left-to-right Mermaid has unreadable labels at the required 708-pixel viewport.**

Preparation 07 remained held. No Quarto render, page-source edit, scientific
computation, data or artifact change, or additional browser inspection
occurred after the defect was confirmed.

## Preserved stopped-test chain and authorized recovery

The fourth focused-test checkpoint remains sealed in:

- `report017_preparation06_fourth_focused_test_stop.md`, SHA-256
  `d59877a901c07cc0d9d54f3f606971b6bda5f13e2a01890a6d324ab4527d9c27`;
- `report017_preparation06_fourth_focused_test_stop_manifest.csv`, SHA-256
  `c5f635e7a4d78831d64144c7fce0f5c61c5e6350a55866a5612bd8d628f1dc99`.

After that seal, one final coordinator-authorized test-only replacement
changed the internal `REPORT-011` label assertion to the accepted
reader-facing phrase check `Its final-display check covers`. Reverse
substitution reproduced the pre-edit test SHA-256
`54f7ca192b3d051093acefe2423dfd711bb562892bc921ec40dff810a225be7b`
exactly. The final focused-test identity is
`03017c71915194335422f538f72750b914855310f5045d893b71a346961112ec`,
17,136 bytes.

Across the complete bounded recovery, the authorized test-only changes were:

1. replace the opaque `historical METRIC-003 provenance` token with the exact
   accepted reader-facing historical-method sentence;
2. delete the two obsolete 725/729 wording tokens;
3. replace the stale non-MDER invariance word order with the exact visible
   sentence containing the 25,620-cell and 618 × 47 invariants; and
4. replace the internal `REPORT-011` visibility assertion with the exact
   reader-facing final-display QA phrase.

Every other MDER, L10, active-count, invariance, path, hash, decision,
qualification, table, figure, source-data, terminology, HTML, and forbidden
execution assertion remained unchanged. Each authorized edit received an
exact reverse-substitution or reverse-insertion check, an R parse check, and
`git diff --check`.

The final focused command was:

```text
Rscript tests/test_preparation06_report.R _build/nathealth/notebooks/preparation/06_model_ready_datasets.html
```

It used normal project R 4.6.1 startup, `.Rprofile`, `renv/activate.R`, and the
project library `renv/library/macos/R-4.6/aarch64-apple-darwin23`. It completed
in 16.012 seconds with exit status 0 and returned:

```text
PASS: Preparation 06 source satisfies the bounded-render, terminology, gt-table, figure, and provenance contract.
```

No package was installed or updated, and `renv.lock` was not edited.

## Semantic HTML audit

The existing rendered HTML retained SHA-256
`2179253dc28326c0cef4084327e3eb76f755bdc1d493209697da02f5c3855814`.
The read-only R 4.6.1 semantic audit passed after two audit-harness-only
normalizations: one for the nonbreaking space in the rendered Figure 2 label,
and one to distinguish permitted external GitHub `.qmd` edit links from
forbidden internal `.qmd` page links.

The completed semantic checks found:

- the accepted title and 10 H2 sections;
- the reader-facing render-boundary callout;
- 19 unique `tbl-*` endpoints, each with one native `gt` table, one nonempty
  Quarto caption, nonempty headers and rows, and one source note;
- the current MDER definition, all four active availability counts, the
  25,620-cell and 618 × 47 invariants, and the L10 numerical-zero evidence;
- both visible independent-reconstruction qualifications and the statement
  that they are not evidence of incorrect data or results;
- the exact dynamic DEV-056 link and its single resolved target anchor;
- the figure caption, substantive alt text, PNG, and paired
  `categorical_levels.csv` link;
- all nine country-coded submitted-manuscript site names in accepted order;
- six main-content links with nonempty labels and resolved targets;
- Preparation 06 as the sole active navigation item, with H06 daily results
  after H06 results; and
- no rendered error or warning container, raw tibble, raw console block,
  unresolved fragment, or forbidden internal page href.

The evidence files are:

- `report017_preparation06_semantic_checks.csv`, SHA-256
  `b18223648c1d64f687e688649d3aaef739d5e5bb80e34845580fab2581335691`;
- `report017_preparation06_semantic_table_audit.csv`, SHA-256
  `3d5b8e2ab6b60625f1c3dfdb15a14ede5dabc74032042a387b7eca8e7041289e`;
- `report017_preparation06_reader_links.csv`, SHA-256
  `56d7344fd39a699dd0fa77ef47648605143b96a063aa8ff2c62e1fae26460f89`.

The site-composition PNG remains 2,160 × 1,958 pixels, 224,765 bytes, at
SHA-256
`058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.
Its paired source-data CSV remains 21,916 bytes at SHA-256
`809d109d3647ef4ac1798ef9eb59c06e2c7db41f5b9ce1dade4d0a8b583f0a22`.

## Exact visual defect

At the requested 1440 × 1000 viewport, the document client width was 1,425
pixels and matched the document scroll width. The main column was 1,148.5
pixels wide. The opening Mermaid used a 1,724.3203125 × 322 view box and
displayed at 1,148.5 × 214.46875 pixels. Its scale was 0.666052, leaving the
nominal 16-pixel labels at approximately 7.993 points. The desktop overview
was readable and showed no clipping, overlap, or page-level horizontal
overflow.

At the requested 708 × 1000 viewport, the document client width and scroll
width both equalled 693 pixels, and the main column remained within its
642-pixel width. The same left-to-right Mermaid displayed at 642 × 119.8828125
pixels. Its scale was 0.372307, reducing the nominal 16-pixel node and edge
labels to approximately **4.468 points**, well below the approved 7-point
minimum. The narrow screenshot confirms that these labels are unreadable.

The defect is confined to the opening diagram's horizontal composition. The
exact source declaration remains `flowchart LR` at QMD line 1576. The diagram
nodes, edges, labels, identifier, caption, and alt text were not changed.

DOM measurement showed all 19 native-table wrappers retain `overflow-x: auto`
and at least 11-pixel, or 8.25-point, table text. Three narrow wrappers had
contained horizontal scroll ranges of 119, 21, and 25 pixels. In accordance
with the stop rule, their visual inspection and the intended-size empirical
figure inspection were not continued after the Mermaid failure. No table or
figure visual-pass claim is made at this checkpoint.

The visual metrics are stored in
`report017_preparation06_failed_visual_metrics.csv`, SHA-256
`887e370200e2224654f6043140ab7a8cb0126045038ad8a85770b6fc00147c47`.
The retained screenshots are:

- `report017_preparation06_desktop_top.png`, SHA-256
  `6dbcad2e2d136d4862ff2d8b6ae7f8428ecddbc8dd92bb8d6773aadaf35440f1`;
- `report017_preparation06_narrow_top.png`, SHA-256
  `c532aede600f973ac91fbb2489473a06e88227f45d1a65a7079177629a2cb337`.

## Secure loopback lifecycle

The build root contained no symbolic link. The first sandboxed bind attempt
returned `PermissionError: Operation not permitted` before creating a
listener. The already authorized narrow elevation then started exactly one
read-only static server:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory _build/nathealth
```

- Document root:
  `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth`
- Address and port: `127.0.0.1:55326`
- Target URL:
  `http://127.0.0.1:55326/notebooks/preparation/06_model_ready_datasets.html`
- Operating-system PID: `81082`
- Start timestamp: `2026-08-13T17:44:21+0200`
- Stop timestamp: `2026-08-13T17:47:51+0200`
- Process exit status: `0`

The target page, styles, scripts, fonts, Mermaid assets, and empirical PNG
returned HTTP 200. The optional favicon request returned 404 and had no page
effect. No non-GET request occurred. The viewport override was reset and the
review tab was finalized before teardown. After the keyboard interrupt,
`lsof -nP -iTCP:55326 -sTCP:LISTEN` returned exit status 1 with empty output,
the expected no-match PASS proving that no listener remained.

## Preservation at the visual stop

The pre-QA and post-QA 829-file build inventories are byte-identical, including
mtimes, at SHA-256
`10db1ea49fe7d940653d61802a85374497c935058968e5c5c6b1f8be6eeb91e6`.
The scoped comparison contains 168 rows: 167 paths remain byte-identical, the
focused test contains only the coordinator-authorized reporting assertions,
and zero unexpected changes occurred. The pre-QA and post-QA comparisons are
byte-identical at SHA-256
`e97f564338c458d36af8afba307a601b701a96888033bb011ad50025a0b2947a`.

The final protected identities are:

| File | SHA-256 |
|---|---|
| `notebooks/preparation/06_model_ready_datasets.qmd` | `2067db45d46b49bec34985f68eb9e10d5e35377548c5103218321261d50f4c5b` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `tests/test_preparation06_report.R` | `03017c71915194335422f538f72750b914855310f5045d893b71a346961112ec` |
| `audit/handoffs/preparation_reports_worker_handoff.md` | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` |
| `_build/nathealth/notebooks/preparation/06_model_ready_datasets.html` | `2179253dc28326c0cef4084327e3eb76f755bdc1d493209697da02f5c3855814` |

No source repair or rerender is authorized at this stopped checkpoint.
