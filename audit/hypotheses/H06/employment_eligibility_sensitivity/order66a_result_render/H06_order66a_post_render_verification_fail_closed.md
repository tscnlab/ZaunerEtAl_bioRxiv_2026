# H06 Order 66a post-render verification stop

Date: 2026-09-02

Status: `FAIL_CLOSED_AFTER_SUCCESSFUL_SINGLE_RENDER`

## Scope and disposition

The sole authorized Order 66a result render completed successfully. Quarto ran
all 43 knitr steps, Pandoc completed with the three accepted resource warnings,
and the semantic repair completed. No second render was attempted.

The first consolidated post-render verification script then returned five
failed assertions. The Order 66a instruction requires a stop after an
assertion failure. Secure loopback visual QA was therefore not started, and
this result endpoint is not presented as fully accepted by Order 66a.

Read-only diagnosis found that the five assertions are defects in the new
verification harness rather than demonstrated defects in the rendered page.
The harness was not patched or rerun after failure. Independent acceptance is
required before any no-rerender verification continuation.

## Sole render execution

The exact command was:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order66a_semantic.mo0UpB \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

The command ran with the authorized narrow access to the existing user-owned
Quarto Sass cache. It exited 0 after approximately 28.34 seconds. The output
reported semantic disposition `REPAIRED`, 14 tables, 69 repaired IDs, 355
repaired `headers` attributes, and 424 substitutions.

The accepted Pandoc warnings were unchanged:

1. `../../audit/hypotheses/H06/H06_analysis_preparation.html` was not fetched
   as a resource.
2. `../../audit/hypotheses/H05/H05_analysis_preparation.html` was not fetched
   as a resource.
3. `../../Datatype.woff2` was not fetched as a resource.

The canonical result HTML is now
`_build/nathealth/notebooks/hypotheses/H06.html`, SHA-256
`b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9`,
4,898,662 bytes.

## Exact semantic and build facts established before the stop

- Raw semantic reversal reproduces pre-hook SHA-256
  `4bf5f7437f3192abd8fdb40994e2b638673cf920bf561141052761c61735f357`.
- Reapplication reproduces the canonical post-hook HTML byte for byte.
- The semantic ledger has 424 substitutions, comprising 69 IDs and 355
  `headers` attributes across 14 native `gt` tables.
- The build contains 892 files and zero symbolic links. No `H06.knit.md`
  remains.
- The build delta is limited to six expected target-owned paths: three
  source-identical employment-sensitivity CSV resources were added, and the
  H06 HTML, `search.json`, and `sitemap.xml` changed.
- The held H06 preparation HTML remains SHA-256
  `ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683`.
- The Sass database remains user-owned, 36,864 bytes, SHA-256
  `22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`,
  with no WAL or SHM file.

## Consolidated failed assertions and read-only diagnosis

1. **Unique document IDs.** The harness reported 1,911 IDs but only 1,843
   unique values. Immediately before that assertion, it passed the same parsed
   document by reference to `normalized_dom_without_mutable_values()`. That
   helper intentionally overwrites every internal table ID with the same
   placeholder. A fresh read-only parse of the saved HTML found zero duplicate
   IDs. The difference is exactly 68 duplicate instances, which is the 69
   repaired table IDs collapsed to one placeholder.
2. **Table-scoped header resolution.** The same in-memory mutation overwrote
   all 355 table `headers` attributes with one placeholder, so every one of the
   14 table checks failed in the harness. The saved HTML retains the repaired
   endpoint-specific IDs and `headers` values. For example,
   `tbl-h06-primary-effects--gt-0001` is a `th`, and its data cells refer to it.
3. **Table captions.** The harness looked only for a native `caption` child
   inside each `gt` table. Quarto supplies each accepted caption as a
   `figcaption` in the enclosing table figure. All 14 table endpoints are
   present, but the harness searched the wrong DOM location.
4. **Reader-link hygiene.** The harness applied the internal `.qmd` prohibition
   to all links. It therefore rejected the external GitHub edit link ending in
   `notebooks/hypotheses/H06.qmd`. The internal-link audit itself found all
   internal targets and fragments present. No local filesystem or build-path
   reader link was identified.
5. **Protected dispatch paths.** The harness prefixed the project root to the
   dispatch manifest's absolute Sass-cache path and therefore tested a
   nonexistent constructed path. A direct read-only check found the actual
   cache exact at the accepted path, SHA-256, size, owner, and sidecar state.

These diagnoses do not substitute for the required corrected post-render and
visual acceptance. They explain why no rendered-page defect is currently
demonstrated by the five failed assertions.

## Preserved identities

- Result source: `5f8ec988d680e1a3e3dbf2410f0d4e6a49ded80a9990b3a09661aebdc98cbd4e`
  (65,023 bytes)
- Preparation source: `5b128499a1f1a9312089ec47dfd1ba30cebb2a31059608659c0aa464753abfa0`
  (63,867 bytes)
- Focused reader test: `aa3031f939f0d4ac5f0621e60e18c32fbe5e9716a8fa577a94d2582a620892b0`
  (6,014 bytes)
- Standalone sensitivity source: `199808d90b0c282b64fe5fba4706bec4845f8f79a73e4365c471cb05ada4e80f`
  (19,444 bytes)
- Standalone sensitivity HTML: `4abe8a146f716a170b3fc9ea1a54aefe246b438a2a784c43cd855ce0570bdb98`
  (1,324,553 bytes)
- Sensitivity report manifest: `aa820c8d2df6bf19db9141141220c722ca5b88862d172c1d0b947c9835fc1ed9`
  (12,053 bytes)
- H06 handoff: `d7199fd0fb4056f4ec67a630814303b3eedeec7b00316b32cf798a2fda6611cf`
  (18,908 bytes)
- Profile: `e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7`
  (10,042 bytes)
- Lockfile: `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`
  (603,493 bytes)

No report source, test, helper, historical manifest, handoff, preparation page,
profile, package, lockfile, model, estimate, interval, p-value, FDR decision,
diagnostic, source data, scientific artifact, H06_daily file, manuscript,
shared configuration, or ledger was changed by the render or the stopped
post-render diagnosis.

## Required next gate

The next action requires independent review of this stopped package. A later
explicit no-rerender continuation may correct or replace only the verification
harness, complete the held read-only checks and secure loopback QA against the
existing HTML, and accept or reject the result endpoint. No such continuation
is authorized by Order 66a.
