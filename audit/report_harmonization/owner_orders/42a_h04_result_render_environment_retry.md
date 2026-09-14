# REPORT-018 owner order 42a: H04 result render environment retry

Date: 2026-08-20

Owner: H04 worker `019febf4-4868-72f3-bd97-31a85e86f8f0`

Status: **released as the sole serial render target**

## Authority and exact purpose

Order 42 stopped before knitr in the known restricted renv cache-lock startup
loop. Its owner stop report is
`/private/tmp/H04-order42-evidence.myeSDE/report018_h04_order42_environment_startup_stop.md`,
SHA-256
`5775c40724eadceb0df35a1ed74d34f0d2f406a39f2e7acdae7d4e1769c2122d`.
The 16-row owner manifest is
`5ac53f314d5f1221b4babd4752ef8af0cfd1ef5fbe91e0a37c90c39f6d0e0f2f`.

Independent acceptance is
`audit/report_harmonization/report018_h04_order42_environment_startup_stop_independent_acceptance.md`,
SHA-256
`c1fa59f6d7fcfa92a4b2ea443696ff73c7f904affe6160fda25f605ab3040a1c`,
with 13-row non-circular manifest
`71132a3c90e3112c9bf9c16af2c47571958e849ea0d62c2b1d00e58d7f806c9b`.
R 4.6.1 independently verified all 20 dispatch rows, all 260 protected
paths, and all 836 build files. No byte changed. Both required source tests
already passed. Do not rerun those tests before this continuation.

Order 42a authorizes only one environment-startup retry of the H04 result
render using the already accepted narrow access to the existing user-owned
renv cache. The H04 companion and all later targets remain held. Do not open a
language, style, optional-link, historical-test, or cosmetic cleanup loop.

## Hard preflight pins

Before the retry, require exact current identities:

- result QMD:
  `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`,
  83,285 bytes;
- held companion QMD:
  `efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474`,
  91,202 bytes;
- unchanged stale result HTML:
  `cad724ca28c651db62f2bb11a51d0d53adbf133785a6d9477f600900269e3cbe`,
  380,116 bytes;
- held companion HTML:
  `73e1c1f097b2053fd55bfea4857d3c72490af490bfa5e7ebf96c8f801bb57a8f`,
  1,207,573 bytes;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- source test:
  `934ec16dcd2b7e6c4b2771f09f35c0832d059d695c21c5b917ba3303bd16c19b`;
- participant stored-output test:
  `247523ec05b484e161e2717a21d33314375370b84413a3bbcfb150582b86ad90`;
- H04 handoff:
  `99de6fd036b7e7c52a55406615642024092e3177317255101c4a5db1ff391036`;
- source-only acceptance:
  `085d974c4c7d8d905434777612befe12f47e8cfd7910da607a1f42f3c5208101`;
- source-only acceptance manifest:
  `417e6a16deb8aab4a05be30f92be3a0b1c303533f6635771c3e3a6e6a9b3b44a`;
- `renv.lock`:
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

Rehash the retained order-42 owner report and evidence manifest. Reinventory
the build and H04 protected set. Require 836 files, zero symlinks, and no
drift from the order-42 post-stop inventories. Stop before execution on any
drift.

## Sole render retry

Create one fresh absolute empty semantic-audit directory under `/private/tmp`
with mode 0700. Run exactly once:

`GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-directory> quarto render notebooks/hypotheses/H04.qmd --profile nathealth`

Run the command with `sandbox_permissions=require_escalated`, or the exact
task-equivalent narrow permission that allows transient writes only to the
existing user-owned renv cache while preserving normal `.Rprofile` and
`renv/activate.R` startup. Do not bypass the project profile. Do not remove a
lock manually, change a package or lockfile, or use `R_PROFILE_USER=/dev/null`.

This is the only render invocation authorized. Do not run a preliminary
startup command, source test, or dry run. If startup stalls again, if the
render exits nonzero, or if any later gate fails, stop once and return one
combined fail-closed package. Do not retry or patch inside this order.

## Post-render acceptance

Require the complete order-42 acceptance contract:

- R 4.6.1 and Quarto 1.9.37, exit 0, and semantic disposition `REPAIRED` or a
  proven already-repaired state;
- exactly 17 native gt tables and seven figure endpoints in accepted order;
- `tbl-h04-primary-results` and `fig-h04-primary-estimates` first in their
  endpoint classes;
- zero duplicate document IDs, every explicit `headers` token resolving once
  to its intended header within its own table, and zero unsupported ID refs;
- reciprocal result and companion links, registration and deviation anchors,
  active navigation, country-coded sites, source-data links, and zero
  unresolved internal reader links;
- zero embedded error, warning, or stderr nodes;
- result and companion QMDs, held companion HTML, profile, hook, tests,
  manifests, handoff, and the complete protected scientific set unchanged;
- build content changes limited to the H04 result HTML, search and sitemap,
  and source-identical target resources, with every delta classified; and
- no model fit, refit, prediction, simulation, bootstrap, resampling,
  multiplicity recomputation, scientific artifact regeneration, or scientific
  value change.

Do not run a broad manifest builder or reseal historical manifests.

## Secure-loopback visual QA

After all nonvisual gates pass, preflight zero symlinks and serve only
`_build/nathealth` through one read-only server bound to `127.0.0.1`. Inspect
only `notebooks/hypotheses/H04.html` at 1440 by 1000, 708 by 1000, and a
200-percent-equivalent viewport.

Inspect all 17 native tables and all seven figures. HTML tables must be usable
at typical desktop or laptop width. Narrow tables may use contained horizontal
scrolling. Stored PNGs control exported final-size figure acceptance. Check
labels, legends, axes, captions, callouts, disclosures, navigation, wrapping,
clipping, overlap, links, and page overflow.

Stop the server, prove no listener remains, reset the viewport, close QA tabs,
and prove post-QA source, profile, protected, and build stability.

## Prohibitions and return

Return one acceptance package or one combined fail-closed defect list. No
source edit, companion or later render, full project render, model execution,
scientific artifact change, profile, package, lockfile, ledger, manuscript,
broad-manifest, commit, push, upload, deletion, or publication action is
authorized.
