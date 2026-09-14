# REPORT-018 H09 order 57c fail-closed record

Date: 2026-08-22

Status: **FAIL_CLOSED after the single render and dedicated helper.** The
unchanged post-render verifier and secure-loopback browser QA were not started
because the helper's required 555-row manifest postcondition failed first.

## Authority and completed pre-render gate

The controlling order is
`audit/report_harmonization/owner_orders/57c_h09_environment_process_probe_and_companion_retry.md`,
SHA-256 `8aa2087907c2108f6235394dfadb61b1eca1fbf0e2bd5a320f0eff71c859ea22`,
9,750 bytes. The 31-row dispatch reproduced exactly, uniquely, and
non-circularly under R 4.6.1.

The independent environment-stop checker ran once and returned its exact
accepted PASS. The retained owner verifier was copied byte-for-byte into the
fresh external directory `/private/tmp/h09-order57c-working.mx4s2k` and ran
once with the authorized read-only process inventory. It returned:

```text
REPORT018_H09_ORDER57B_PRE=PASS dispatch=36/36 stop=58/58+17/17 stage3=87+19 chunks=22 later=3 endpoints=19/1/1 links=23/22 helper=554 semantic=19/102/588/690 protected=545/545 support=16/16 R=4.6.1
```

The process inventory found zero competing H09, Quarto, Pandoc, helper,
semantic, or loopback processes.

## Single render and helper

Exactly one companion render ran with R 4.6.1, Quarto 1.9.37, the accepted
project library, the normal `nathealth` profile, and external semantic evidence
at `/private/tmp/h09-order57c-semantic.wgVojR`. It exited zero. Exactly one
dedicated H09 preparation-manifest helper then ran and also exited zero.

Invocation counts are therefore:

- owner pre-render verifier: 1;
- H09 companion render: 1;
- dedicated H09 helper: 1;
- unchanged post-render verifier: 0;
- secure-loopback browser QA: 0.

No second verifier, render, helper, source repair, test, model, result render,
or browser session was started.

## New fail-closed findings

### Preparation manifest

The helper recorded 553 unique, live-exact, non-circular rows, not the required
555. The exact transition from the verified 554-member pre-render inventory is:

- 17 historical source-side companion members became absent: the local
  companion HTML and its 16-file support tree;
- 16 canonical website page assets were added under the target output tree;
- the net helper inventory is therefore 553 rows.

The current manifest is internally valid at 553/553, SHA-256
`90a47a6070a692d0089ef68f821b781998428f189d2718e12a8cdda046868ae2`,
158,291 bytes, but fails the sealed 555-row contract. The helper was not rerun.

### Source-side preservation

The scoped Quarto render removed the historical source-side companion HTML and
all 16 source-side support files. They were present and exact in the complete
pre-render gate. They were not restored because Order 57c forbids a cleanup
loop or historical-record rewrite.

The historical sample-support PNG itself was reproduced byte-identically in
the canonical website asset tree at SHA-256
`3116032e2bab0ad904a5cca5cb6353b5c0554e576cf076596671e31ed2caa775`,
129,472 bytes. Thus this stop does not indicate changed figure data, geometry,
labels, colours, or visible content.

### Semantic ledger

The semantic hook repaired all 19 tables, retained unique document IDs, and
all `headers` tokens resolve within their table. Ledger reversal and
reapplication are exact. The fresh render nevertheless produced 591 header
substitutions and 693 total substitutions, while the sealed held-page contract
expected 588 and 690. The actual result is therefore `19/102/591/693`, not
`19/102/588/690`.

### Build transition

The build tree changed from 851 to 871 files. There are no missing build files,
20 additions, and four changed files. The additions comprise 16 target-page
assets and four linked H09 provenance resources. The changed files are the
target HTML, its source-identical build QMD, `search.json`, and `sitemap.xml`.
This is larger than the sealed one-asset expectation and is recorded without
cleanup.

## Preserved scientific and source state

The authoring companion source remains unchanged at SHA-256
`394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f`,
51,736 bytes. The build QMD is byte-identical to it. Fifteen controlling and
scientific preservation pins pass exactly, including the accepted H09 result
source and HTML, Stage 3 manifest, contract, input audit, historical test,
dedicated helper, profile, and lockfile.

The rendered companion HTML is SHA-256
`09b604b011ef14c138c15720b419a9ca200e15f71ce3e40a9b85c23f6803f96d`,
631,401 bytes. It was not rerendered after the stop.

## Verification evidence

The order-specific failure verifier is
`verify_order57c_fail_closed.R`, SHA-256
`b3e3c47b095ef4c3a5e8c33d064f9e77d03b8ff9a3da0f29289fde15dee78df0`,
20,266 bytes. It reported:

```text
REPORT018_H09_ORDER57C_FAIL_CLOSED=PASS pre=12/12 process=0 render=1 helper=1 manifest=553/555 semantic=19/102/591/693 expected_semantic=19/102/588/690 source_side_missing=17 build=851->871 protected=524/17/4 pins=15/15 R=4.6.1
```

The external working and semantic directories are retained for independent
acceptance. The next action is independent H09 review of this fail-closed
state.
