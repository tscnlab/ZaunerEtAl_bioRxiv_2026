# REPORT-018 H09 order 56 stopped-state independent acceptance

Date: 2026-08-22

Status: `ACCEPTED_STOPPED_FIGURE_TYPOGRAPHY_DEFECT`

## Disposition

The sole H09 result render completed successfully under R 4.6.1, Quarto
1.9.37, the normal `nathealth` profile, and the accepted semantic hook. The
fresh result page passes the complete nonvisual, semantic, link, navigation,
country-label, protected-identity, and build-stability contracts.

The owner correctly stopped after secure-loopback visual QA identified one
consolidated readability defect. At the required 170-mm display width, the
smallest essential text is 5.099363 pt in the primary-effects figure,
6.692913 pt in the paired-placement figure, and 5.099363 pt in each of the
near-eye and chest diagnostic figures. All four values are below the required
7-point floor.

This is a genuine display defect. It is not a scientific, semantic, source,
link, navigation, or general page-layout defect. The current figure data,
estimates, intervals, FDR decisions, categories, panels, marks, colours,
symbols, and source links remain accepted and unchanged. No patch, second
render, companion render, model execution, scientific recomputation, commit,
push, or upload occurred.

## Independent R verification

The central checker is
`scripts/report_harmonization/check_h09_order56_stopped_acceptance.R`,
SHA-256 `40807ca7788272984227b7afcea33ae509f0ace89d26862bf2e4f3e27ddcbaa2`,
13,213 bytes. Its verification table is
`audit/report_harmonization/report018_h09_order56_stopped_independent_verification.csv`,
SHA-256 `c840236e8c5c84465c1ae3147aaa99b5c8cc36c9124734b872701ca84a2029aa`,
2,170 bytes.

R 4.6.1 reported:

```text
H09_ORDER56_STOPPED_INDEPENDENT_ACCEPTANCE=PASS checks=21/21 owner_manifest=98/98 tables=11 figures=4 semantic=11/54/505/559 visual=8PASS+1FAIL build=851 protected=176 R=4.6.1
```

The independent replay verified:

1. The owner stopped record is SHA-256
   `6f1d5900c51ecc9f7215ecb080d8f1cf0bc10d476e3c0baddb10610f8f8135e5`,
   1,241 bytes.
2. The owner 98-row manifest is SHA-256
   `a9ed20cdafbc27a826574be3337e5a7769b1fff7f129bb0b12a347b490ba7ace`,
   22,521 bytes. All 98 paths are live-exact, unique, and non-circular.
3. The one recorded render exited 0. The accepted result source remains
   `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6`,
   36,970 bytes. The fresh result HTML is
   `dbc9122ca0a7be6e051741d8354f9ebdec8e072753d9b2592d6387f9716a7caa`,
   244,127 bytes.
4. The page contains exactly 11 native gt tables and four H09 figure
   endpoints. Document IDs are unique and all 505 table-header tokens resolve
   exactly once inside their own table.
5. The semantic hook reports `REPAIRED` with 54 ID substitutions, 505
   `headers` substitutions, and 559 total substitutions. Its exact reverse
   and reapplication checks pass.
6. All 16 nonvisual domains pass. Eight of nine visual domains pass. The sole
   failure is exactly `final_size_170mm_essential_text_floor`, with the four
   measured values stated above.
7. The complete 851-file build inventories before and after QA are
   byte-identical. The complete 176-path protected inventories before and
   after QA are byte-identical.
8. The historical Stage 3 audit remains 96 of 108 live-exact with exactly 12
   previously accepted historical-to-fresh transitions and no new mismatch.
9. The companion source and held HTML remain exact at `7563a933...` and
   `4054dfc6...`. Both historical H09 tests, the profile, and `renv.lock`
   remain byte-identical.
10. The loopback server was stopped and its final audit passes 2 of 2 checks.

## Authorized next boundary

One separately sealed consolidated display-only repair and result-rerender
order may be issued. It may regenerate only the four affected PNG/PDF figure
families from their frozen paired source CSVs, make the corresponding display
literals reproducible in the existing H09 builder, update only directly
dependent current display records, and rerender the H09 result exactly once
after a candidate-first 7-point typography gate passes.

The repair must preserve every scientific row, value, estimate, interval,
p-value, FDR decision, diagnostic value, category, panel, mark, scale, colour,
shape, label meaning, and source link. It must not run the full Stage 2
builder, read a fitted model, or regenerate any scientific artifact. A fresh
render must repeat the semantic, structural, protected, build, and complete
desktop, narrow, 200-percent-equivalent, and 170-mm visual checks.

The H09 companion and every later REPORT-018 render remain held pending
independent acceptance of the repaired result page.
