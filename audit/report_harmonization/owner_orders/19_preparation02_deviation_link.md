# Harmonization follow-up 19 — Preparation 02 exact deviation link

Date: 2026-08-12  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Controlling decisions: `REPORT-014` / `CHG-124`; `REPORT-016` / `CHG-126`; website integration `CHG-128`  
Dispatch mode: **one source-only link repair; no render or execution**

## Exact owned source and identity

- `notebooks/preparation/02_coverage_sample_flow.qmd`
- pre-edit SHA-256: `4c0d825d1c7d6d78c7c1e5b41292c53f525d15ad978ee9d5bbd92199abb6e008`

Recheck this identity immediately before implementation and stop on drift.
Edit no other source. Preparation 06's accepted `DEV-056` link and the other
five preparation pages must remain untouched.

## Exact change

At the current paragraph beginning “The daily denominator differs from the
preregistered sleep-excluded denominator,” preserve every existing word and
add one short final sentence:

> This primary full-day denominator choice is documented in [DEV-055](../preregistration_deviations.qmd#dev-055).

The visible literal ID and target are required. Do not place the link inside a
code chunk or generate it dynamically. Do not add any other deviation ID or
link. The target must remain the relative `.qmd` source plus exact lower-case
anchor; do not use `.html`, `file://`, `_build`, a build path, or an absolute
local path.

## Scientific and ownership boundary

This is link-only. Do not change the fixed 1,440-minute denominator, hybrid
full-day interpretation, sleep-excluded sensitivity role, coverage rules,
thresholds, samples, values, objects, chunks, identifiers, captions, tables,
figures, code, or claims. Do not execute R or Quarto. Do not edit stored
artifacts, manifests, scripts, tests, configuration, ledgers, bibliography,
lockfiles, manuscript files, or another QMD. If the accepted paragraph cannot
be preserved exactly apart from the added sentence, stop and report the
conflict.

## Evidence to return

- pre- and post-edit SHA-256;
- exact source line of the added sentence;
- confirmation that `DEV-055` occurs once as the required literal link and
  that `notebooks/preregistration_deviations.qmd#dev-055` resolves;
- confirmation that the paragraph's pre-existing text and every executable
  chunk are byte-identical;
- no forbidden internal page-link form;
- `git diff --check` and scoped status showing only this QMD;
- confirmation that no render, R execution, scientific recomputation, or
  collateral edit occurred.
