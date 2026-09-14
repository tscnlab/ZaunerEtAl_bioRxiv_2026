# REPORT-018 Order72h independent browser-preview acceptance

Date: 2026-09-11.

Disposition: ACCEPTED for the standalone selection browser preview only.
The mandatory REPORT018-ORDER72E-SELECTION-SVG-PREVIEW-REVIEW coordinator
gate is closed for the exact endpoints below. This is not acceptance of the
stopped Word candidate, manuscript submission, new scientific claims, or any
later display replacement.

## Accepted endpoints and owner evidence

- `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`:
  SHA-256 `197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9`,
  49,967 bytes.
- `audit/manuscript_nature_health/manuscript_figure_table_selection.html`:
  SHA-256 `7055fc384bd845f8b42e3d37901c846060aeef6b8248536dc75240070e7a51e4`,
  29,370,796 bytes. Owner candidate, served copy, and canonical endpoint match.
- Owner recovery root:
  `audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/order72h_scroll_recovery/`.
- Owner `completion_manifest.csv`:
  SHA-256 `13a469421ff156b6357c26564aed0b088960eecafe388efbad4cc7b2fe6295f2`.
  Independent rehash: 35/35 exact, unique and non-circular.
- Owner `completion_seal.md`:
  SHA-256 `e6a1961e633da603867eec3ad4d510101b0c099f0317045ff43f65d2dee56a80`.

The 132-row central release reconciles as 130 live-exact members plus the two
authorized QMD/HTML transitions, each resolved through an exact preserved
preimage. The 113 execution pins reconcile analogously as 111 live-exact plus
those two transitions. No historical release or manifest was rewritten.

## Independent verification

R 4.6.1 was used with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` and
`R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library`. The unchanged owner
validator was replayed in a temporary output root. Complete source checks
passed 21/21 and complete HTML checks passed 43/43. Source, HTML and table
endpoint replay CSVs are byte-identical to their sealed owner counterparts.
All 20 SVG source identities remain exact. Final independent checks pass
14/14, and all 133 post-QA preservation pins remain exact.

The active quarto-authoring skill required immutable-output staging, a
symlink preflight, bounded loopback inspection, teardown and rehash. The
temporary served root contained only an exact copy of the HTML and no
symlinks. The read-only server was bound to 127.0.0.1:51861. The exact route
returned HTTP 200. Supported direct browser viewport overrides were used at
1440x1000, 708x1000 and 390x1000. These are direct viewport checks, not iframe
wrappers or a claim of native mobile-device testing.

Document client/scroll widths were 1425/1425, 693/693 and 375/375 respectively.
All 20 SVG assets loaded, all 11 disclosures were open and all 22 tables were
reachable within their own local range at each width. No page-level overflow
tolerance was used. One pixel of bounding-box rounding was allowed only when
checking cell edges inside their local table range.

The unique Coordination status region preserves 45 cells, an accessible name
and keyboard focus. Three ArrowRight presses moved its desktop scroll from
0 to 120 pixels. Mobile keyboard scrolling reached 1365.5 of a 1366-pixel
maximum and the last cell was reachable. Independent representative visual
inspection also covered the repaired region and complete S5 and S12 displays.
The owner's sealed evidence supplies the complete 20-figure visual sweep;
the coordinator does not claim to have repeated that entire manual sweep.
The browser emitted no warning/error log entries. Its screenshots were
emitted in the coordinator transcript, not saved as a local screenshot archive.

The QA tab was closed and the viewport reset. The server exited after SIGINT;
read-only lsof checks confirmed no listener on 51861 or the owner's old port
8765. Only the optional favicon request returned 404. No Quarto render,
scientific execution, source edit or production promotion occurred during
independent acceptance.

## Explicit limitations and subsequent holds

Twenty accepted SVG files do not mean twenty raster-free scientific interiors.
The independent container inventory confirms two nested SVG image payloads in
S5, two PNG payloads in S7 and two PNG payloads in S15. Main Figure 1 contains
one PNG illustration component. These identities were preserved, not upgraded
or reclassified as native-vector panels by this acceptance.

The stopped Order72d Word candidate remains unaccepted. Its native Word S5
absent-panel defect, the requested S7/S15 splits, S2 single-horizontal-set and
uncropped-distribution requirement, S5/S6/S10 manuscript-image font repairs,
and separate LibreOffice S17 defect require their own consolidated boundary.
Native Word observation evidence is not a screenshot-complete acceptance seal.
No repair, fallback, manuscript save, Word rerender or scientific change is
authorized by this record. Brown main-analysis authority remains held under
the separate BA-017 linkage-alignment process.

The accompanying non-circular independent manifest pins this record, copied
read-only replay evidence and controlling owner/central identities. Its own
identity is reported separately, not included as a self-row.
