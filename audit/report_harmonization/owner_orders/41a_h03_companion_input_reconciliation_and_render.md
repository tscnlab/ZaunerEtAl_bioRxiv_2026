# REPORT-018 owner order 41a: H03 companion input reconciliation and render

Date: 2026-08-20

Owner: H03 worker `019fbe52-c067-7521-b2cf-62d9398d173b`

Status: **released as one provenance-repair and companion-render continuation**

## Authority and disposition

Order 41 stopped correctly in the companion input-identity table before any
new HTML or scientific output was produced. The stopped state is accepted by
`audit/report_harmonization/report018_h03_order41_stopped_input_reconciliation.md`,
SHA-256
`5697769cbccd5566d5c21460b9f5a5bc25f731a3fd76e3cac596c0d88b366c69`.

An independent R 4.6.1 reconstruction proved that the accepted current
Preparation 06 one-hour inputs reproduce every value in all ten frozen H03
model frames, both primary model matrices, both site-interaction model
matrices, and all category and site-cell support summaries at tolerance zero.
The two failed SHA-256 values are therefore a provenance-only transition for
H03. No model refit or scientific artifact change is warranted.

REPORT-018 prioritizes successful reader-page integration. Complete this
repair and the H03 companion render in one continuation. Do not open a
language, style, optional-link, historical-manifest, or cosmetic cleanup loop.
H04 and every later render remain held.

## Hard preflight pins

Stop before editing if any pin differs:

- order-41 stop record
  `/private/tmp/H03-order41-evidence.B7czTa/order41_stopped_record.md`:
  `fa767cbb9d174e218c3c6b21359ef1b97d71c3826e4fb23d71cb6c33ee8f9bb8`,
  5,392 bytes;
- order-41 failed-input reconciliation
  `/private/tmp/H03-order41-evidence.B7czTa/failed_input_gate_reconciliation.csv`:
  `3fb9a835fff4b386403cc14f55da75720c35c40a55466dc806919e18aae63cf9`,
  2,020 bytes;
- independent stopped-state reconciliation:
  `5697769cbccd5566d5c21460b9f5a5bc25f731a3fd76e3cac596c0d88b366c69`;
- transition checker
  `scripts/report_harmonization/check_report018_h03_input_transition.R`:
  `ca746b915d2b7d7f23f2f28e19518a5590f252da7bb887e523a93d76f7755fa3`,
  6,120 bytes;
- transition evidence
  `audit/report_harmonization/report018_h03_input_transition_evidence.csv`:
  `1ffbfcdd52760057110d4d4e3326ea8cae896659e481540e54cf770ece7957e5`,
  2,038 bytes;
- current Preparation 06 gate
  `audit/decisions/preparation06_current_base_model_gate.md`:
  `63f17f1b9b3a91d437a5964cde063770d0fb4fac3f9c81e588fc374d9cc71f04`;
- current base-model manifest
  `artifacts/12_manifests/base_model_data_artifacts.csv`:
  `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce`;
- current near-eye one-hour input:
  `7591bcfaae4b49fdde2053160848e170895092b223f96108e538066ce210a951`,
  248,236 bytes;
- current chest one-hour input:
  `18134eec529c36e5fd47c7b3bb1e3b909628b97986cd91eff8e59ee9b5343cbb`,
  268,444 bytes;
- frozen H03 model frames:
  `1356a0cbf0cd0487ef5bd3d756b0b6701b9507e354fdb7c3ce90c9f785fed617`;
- pre-edit H03 contract
  `scripts/hypotheses/H03/h03_contract.R`:
  `fa9979d27158e51193188505da79912be30914b704acbb0e9888622422d7ba63`,
  10,652 bytes;
- pre-edit H03 input audit
  `artifacts/06_model_data/H03/H03_input_audit.csv`:
  `16dccf5d1d68e1d605411da867acee960cf7963d0345e58fefc2adae015fcf1f`,
  3,286 bytes;
- companion QMD:
  `59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131`,
  75,638 bytes;
- accepted result QMD:
  `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41`,
  68,198 bytes;
- accepted result HTML:
  `abe4be0b127c66b357eca66ab5e90609e0ac7902ca611c5f0e8a9adf410f2cc1`,
  335,521 bytes;
- held companion HTML:
  `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf`,
  900,339 bytes;
- Stage 2 test
  `tests/hypotheses/H03/test_h03_stage2.R`:
  rehash from the dispatch manifest and preserve exactly;
- auxiliary stored-output test:
  `30fa488114886eb4e9feeccc55f6f752e229585bfc1f2eb5b5a85bfba582bfc8`;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.

Recheck the complete 23-row H03 result acceptance manifest and all 413
order-41 protected entries. The two coordinator-owned ledger identities may
advance concurrently and must be classified separately. Stop on any other
drift.

## Exact provenance-only edits

Edit only these two files:

1. `scripts/hypotheses/H03/h03_contract.R`
2. `artifacts/06_model_data/H03/H03_input_audit.csv`

Apply exactly these substitutions:

- replace
  `cee864bb0e329b98444088b777c7245250be68111ec9f24db7c0e3f395ed6445`
  with
  `7591bcfaae4b49fdde2053160848e170895092b223f96108e538066ce210a951`;
- replace
  `50f50ca5d39d621d06f2794037c4b769e01fc7329a70432e79a51203727ed209`
  with
  `18134eec529c36e5fd47c7b3bb1e3b909628b97986cd91eff8e59ee9b5343cbb`.

The contract contains each old literal once. The input audit contains each old
literal exactly twice, once as expected and once as observed identity. Change
no path, role, row, order, column, boolean, code, or other byte.

Required post-edit identities:

- contract:
  `3e16b8a9baa26b7006d94122730d8182c2a36263c750ee43a0e260ff379c8b7b`,
  10,652 bytes;
- input audit:
  `42e438db85e44aef58bb32a2c2a7e8e506a9bf226f575c2ceab14850e2e6996c`,
  3,286 bytes.

Require exact reverse substitution to both pre-edit hashes. Parse the contract
under R 4.6.1 and run `git diff --check` on the two files.

## Required source and scientific-preservation checks

Before rendering, run once each under R 4.6.1:

1. `scripts/report_harmonization/check_report018_h03_input_transition.R`;
2. `tests/hypotheses/H03/test_h03_stage2.R`;
3. `tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R`.

All must pass. The transition checker may reproduce the existing tidyselect
deprecation warnings from accepted H03 assembly functions; classify those as
nonblocking implementation warnings, not render warnings.

Do not execute the Stage 2 driver, fit code, historical preparation helper,
historical preparation test, Stage 3 manifest builder, or any broad manifest
builder. Preserve every estimate, interval, p-value, diagnostic, sample,
model object, figure, source-data file, and current/historical manifest.

## Sole fresh render

After all checks pass, create one new absolute empty audit directory under
`/private/tmp`, mode 0700, and run exactly once:

`GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-directory> quarto render audit/hypotheses/H03/H03_analysis_preparation.qmd --profile nathealth`

Use normal R 4.6.1 project/renv startup with only the established narrow
access to the user-owned renv cache. Do not render the H03 result, another
page, or the full project.

## Post-render acceptance

Require:

- exit 0 and semantic-hook disposition `REPAIRED` or a structurally proven
  `ALREADY_REPAIRED` state;
- exactly 27 native gt tables, four figure endpoints, and one top-down
  Mermaid;
- zero document duplicate IDs, every explicit table `headers` token resolving
  exactly once within its own table, and no unsupported ID references;
- the participant-random-intercept anchor
  `sec-h03-prep-participant-random-intercept` exactly once;
- reciprocal result and companion links, deviation anchors, navigation,
  country-coded sites, source-data links, and zero unresolved internal links;
- no embedded error, warning, or stderr node;
- accepted result QMD and HTML, both H03 sources, profile, semantic tools,
  frozen H03 scientific artifacts, and every unrelated build member
  byte-identical;
- build changes confined to the companion HTML, normal search/sitemap
  outputs, target-owned assets, and a Quarto-created build QMD only if it is
  byte-identical to the accepted companion source;
- the historical direct HTML, preparation helper, preparation test, and
  historical manifests unchanged. Classify their expected live mismatches as
  historical metadata under REPORT-018.

## Secure visual QA

Serve only `_build/nathealth` through one read-only HTTP server bound to
`127.0.0.1` after a symlink preflight. Inspect only the exact H03 companion
route at 1440 by 1000, 708 by 1000, and 200-percent equivalent. Inspect all 27
tables, four figures, the top-down Mermaid, headings, callouts, captions,
notes, links, navigation, wrapping, clipping, overlap, and page overflow.
Desktop tables must be usable. Narrow tables may use contained horizontal
scrolling. Inspect stored PNGs at their intended final sizes.

Stop the server, prove no listener remains, reset the viewport, close the QA
tab, and prove post-QA source, protected, and build stability.

## Fail-closed boundary

Return one complete acceptance package or one consolidated genuinely new
defect list. Do not patch or rerender inside this continuation after a new
failure. Do not stop for the already classified historical manifests, stale
direct HTML, stale build QMD, optional favicon, language, style, or minor
cosmetic observations.

No model fit/refit, prediction, simulation, bootstrap, resampling, scientific
artifact regeneration, result rerender, profile/package/lock/ledger change,
later render, commit, push, upload, or publication is authorized.
