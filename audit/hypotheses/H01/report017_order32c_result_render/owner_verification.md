# REPORT-017 order 32c owner verification

## Disposition

**STOPPED.** The single authorized H01 result render completed successfully,
and the fresh page passed the H01-specific reporting, semantic, navigation,
reader-link, and deviation-link contracts. Release is nevertheless held by
unclassified build changes, an out-of-scope global H04 country-code failure,
and two reader-facing figure defects. No page, source, test, artifact, or
shared file was patched, and no second render was run.

## Final result identity

- Result QMD: `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`
- Frozen companion QMD: `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`
- Fresh result HTML: `d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410`, 1,643,915 bytes
- Frozen companion HTML: `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`
- Nature Health profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`
- Semantic wrapper: `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`
- Semantic engine: `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`
- Accepted hook test: `696e3308275d366dcc4aefb8e60c36d7c4c42d02a88402e3d06717b6383d0fae`

## Render and semantic hook

Exactly one command ran:

```text
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

It exited 0 under R 4.6.1 and Quarto 1.9.37. The configured hook reported
`REPAIRED` with 36 tables, 783 IDs, and 4,798 headers substitutions. Its exact
line and lifecycle are in `render_execution_record.md`.

## Protection and build reconciliation

- All 12 dispatch rows and all 25 independent source-acceptance rows were
  exact before execution.
- The protected inventory contained 1,240 files. The only protected content
  change was the authorized H01 result HTML.
- The companion source and HTML, profile, hook, engine, tests, current source
  manifests, handoff, and protected H01 scientific artifacts remained exact.
- The H01 deviation reconciliation test independently confirmed 1,161
  protected scientific artifacts unchanged.
- The build contained no symlinks before or after rendering or QA.
- Authorized content changes were the target H01 HTML, `search.json`, and
  `sitemap.xml`.
- Two additional build copies changed during the render. Both now match their
  existing current source files exactly, but this exceeded the strict build
  delta allowed by the order:
  - `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png`
  - `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`
- Three duplicate build entries appeared after the post-render inventory.
  No existing build member changed content during browser QA, no protected
  member changed, and the duplicate files were preserved for disposition.

## Focused contracts

- H01 fresh reporting test: PASS
- Navigation contract: PASS for 37 accepted reader sources
- Reader-link contract: PASS for 37 sources and 86 deviation anchors
- H01 deviation-link contract: PASS
- Global country-code contract: FAIL only for two H04 source locations
- H01-specific registered country-coded site-name check: PASS for all nine
  registered names

## Result-page semantics

- 36 native gt tables, exact endpoint set and order: PASS
- Principal table first: `tbl-h01-primary-publication-summary`
- Ten labelled figures, exact endpoint set and order: PASS
- Principal figure first: `fig-h01-model-support`
- Unique document IDs: PASS
- 11,084 table `headers` tokens resolved once within their table: PASS
- 11,157 explicit ID-reference tokens resolved once: PASS
- Raw errors, warning nodes, unresolved references, and object leaks: zero
- Compact FDR wording and zero compact BH abbreviations: PASS
- Reader links checked: 217, with only the known DOC-001 Supplementary hold
- Deviation links: 40 occurrences to 36 unique exact anchors, all resolved
- Displayed source-data links: 19, all resolved
- Active H01 navigation and preparation/companion links: PASS

The evidence-only semantic checker had one stale expectation for two retired
section IDs. The accepted source and HTML use `detailed-analysis-record` and
`analysis-record-and-source-data`; the endpoint and order audits for the
actual page passed.

## Secure-loopback visual QA

- The page was inspected at 1440 by 1000 and 708 by 1000.
- All 13 reader sections were captured at both widths.
- All ten figures were inspected at final desktop display size.
- The principal figure and table were inspected at desktop, narrow, and 200
  percent.
- The exported principal figure was inspected at its intended final-size
  equivalent.
- No browser console errors or warnings occurred.
- At 708 pixels there was no document-level horizontal overflow and no
  uncontained overflow. Five gt tables and two code blocks used contained
  scrollers.
- The loopback server was stopped, and the final listener check found no
  listener on `127.0.0.1:56205`.

Visual defects:

1. Figure 5 has overlapping direct labels in its dense central clusters.
2. Figure 1 and Figure 6 contain important raster text that becomes too small
   at the 708-pixel display width.

## Held work

- No source repair was attempted.
- No test, manifest, page asset, or build duplicate was edited or removed.
- No second render was run.
- The H01 preparation/provenance companion was not rendered.
- All later REPORT-017 targets remain held.
- No commit or push occurred.

The complete classifications are in `combined_stopped_state_defects.csv`.

