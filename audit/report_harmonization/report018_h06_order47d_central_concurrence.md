# REPORT-018 H06 order 47d central concurrence

Date: 2026-08-21

Disposition: `CONCUR_DISPATCH_ONE_COMPANION_RENDER`

## Authority reviewed

- Controlling order: `audit/report_harmonization/owner_orders/47d_h06_hourly_companion_render.md`
  - SHA-256: `fe25c05e3fb20b9a76c41bd2fd67810e9b2cf7845fb52ffc1b92cd01d0663523`
  - Bytes: 9,631
- Non-circular dispatch manifest: `audit/report_harmonization/report018_h06_order47d_dispatch_manifest.csv`
  - SHA-256: `9067ddc6607ea7e5f94fa7bb8d8259073137ac740a606ddcea9431e6dd052a47`
  - Bytes: 5,506
- Accepted H06 result record: `audit/report_harmonization/report018_h06_result_independent_acceptance.md`
  - SHA-256: `1e5097504278defa98cbc42cc6798d85926cb525316886c12d4cf8f3c7f8f7a1`
- Accepted result source and HTML:
  - `notebooks/hypotheses/H06.qmd`: `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`
  - `_build/nathealth/notebooks/hypotheses/H06.html`: `8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa`
- Held companion source: `audit/hypotheses/H06/H06_analysis_preparation.qmd`
  - SHA-256: `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`
- Stale companion HTML: `_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html`
  - SHA-256: `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`
- Accepted profile: `_quarto-nathealth.yml`
  - SHA-256: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`

## Independent verification

The central checker is `scripts/report_harmonization/check_h06_order47d_central_concurrence.R`, SHA-256 `53a3adf0f75427bef836d3143e8e5ad9682dd909c3e27a97918df9a908166773` after Air 0.4.1 formatting.

The checker ran with `Rscript --vanilla` under R 4.6.1 and independently established:

1. All 37 dispatch-manifest paths are unique, non-circular, present, and exact by SHA-256 and byte count.
2. All 34 companion R chunks parse. The source exposes exactly 30 unique native table endpoints, three unique figure endpoints, and one `flowchart TD` Mermaid.
3. The unchanged 315-row preparation manifest has exactly the 20 documented historical mismatches and 295 live-exact rows. The mismatch set equals the order's enumerated set.
4. The accepted profile keeps the H06 result and companion adjacent and retains the semantic post-render hook.
5. The unchanged companion test, dedicated integration helper, and H06 contract parse under R 4.6.1.
6. The dedicated helper is confined to synchronizing the companion source copy and rebuilding the H06 preparation manifest after a successful render.
7. `_build/nathealth` contains no symbolic links.
8. A filtered process inspection found no active Quarto render, Pandoc, semantic-hook, or H06 render process.
9. `air format --check` and scoped `git diff --check` pass.

No H06 source, helper, test, profile, manifest, HTML, scientific artifact, or build output was edited or rendered during central verification.

## Released boundary

Order 47d may be dispatched exactly once to the idle H06 owner. It authorizes only:

1. the sole companion target render specified in the order;
2. one execution of the unchanged dedicated helper after a successful render;
3. the unchanged full companion test and the specified semantic, protected-identity, build-delta, link, navigation, country-label, visual, final-size, loopback, and teardown checks; and
4. one non-circular owner completion or stopped-state seal.

The accepted H06 result must remain unchanged. H06 daily result and companion renders, all later targets, source/helper/test/profile/scientific edits, full-project rendering, package or lock changes, commits, pushes, and uploads remain held.

The coordination-matrix identity in the dispatch manifest is dispatch-time evidence. A coordinator status update made solely to record the authorized dispatch is not owner-path drift and must not broaden the order.
