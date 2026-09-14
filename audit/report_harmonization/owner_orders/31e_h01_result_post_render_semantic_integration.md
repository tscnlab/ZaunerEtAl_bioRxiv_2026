# REPORT-017 order 31e: H01 result post-render semantic integration

Date: 2026-08-14

Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released for exactly one fresh H01 result target render, semantic
post-render repair, and secure-loopback QA. The H01 companion and every later
REPORT-017 target remain held.**

## Authority

The coordinator independently accepted Stage C after reproducing the full
temporary-copy test, 22/22 manifest identities, profile reversal, and complete
H01 reporting test. The accepted Stage C verification is
`audit/report_harmonization/report017_h01_gt_semantic_post_render_integration_verification.md`,
SHA-256
`4d9c1a57d1eb8d46b575a89113357215b47a62429520de1367ecab6000441742`.

## Exact preflight pins

Stop before execution if any identity differs:

- H01 result QMD:
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`;
- H01 focused reporting test:
  `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`;
- H01 companion QMD:
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`;
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- post-render wrapper:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- accepted repair engine:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- Stage C transition test:
  `696e3308275d366dcc4aefb8e60c36d7c4c42d02a88402e3d06717b6383d0fae`;
- H01 reporting manifest:
  `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`;
- H01 Stage 3 reporting manifest:
  `08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`;
- stored L10 support CSV:
  `5814d5518ab23b3578dac54b19c6c6deea46e8d76aff2f3a6e30bce28752a26a`;
  and
- sealed pre-render H01 HTML:
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`.

Also record the current protected scientific/input inventory and current
`_build/nathealth` inventory before execution.

## Sole render execution

1. Create one fresh audit directory under `/private/tmp` with `mktemp -d`.
   Record its resolved absolute path, permissions, creation time, and proof
   that it is empty.
2. Run exactly one normal-profile command:

   ```text
   GT_HTML_SEMANTIC_AUDIT_DIR=<resolved-fresh-directory> quarto render notebooks/hypotheses/H01.qmd --profile nathealth
   ```

3. Use only the already approved narrow access to the existing user-owned
   renv cache if normal-profile startup requires it. Do not bypass
   `.Rprofile` or `renv/activate.R`.
4. Record Quarto 1.9.37, R 4.6.1, relevant package versions, complete command
   output, duration, and exit status.
5. Require the hook status for the H01 result target to be `REPAIRED`. Stop if
   it reports `NO_GT`, `ALREADY_REPAIRED`, a partial state, or any error.

No second render, companion render, broader render, full-project render,
source edit, test edit, profile edit, package change, lockfile change,
scientific recomputation, commit, or push is authorized.

## Scientific and protected-file checks

After the single render:

- confirm that no model, fit, prediction, bootstrap, resampling, or scientific
  artifact regeneration occurred;
- refresh the exact H01 protected inventory and require every scientific,
  input, source, and accepted artifact outside the authorized QMD, test,
  manifest, profile, hook records, and declared build outputs to remain
  byte-identical;
- run the complete H01 reporting test. Its fresh-render branch must pass and
  require exactly eight `Primary 17-test FDR family` cells and zero
  `Primary 17-test BH family` cells in `tbl-h01-l10-noon-support`;
- verify all 49 reporting-manifest and all 95 Stage 3 reporting-manifest rows;
  and
- recheck the current H01 QMD, owner test, companion, profile, wrapper, engine,
  manifests, and stored L10 CSV identities.

## Actual post-render audit

Retain the external audit directory intact until the harmonizer independently
accepts and consumes it. It must contain exactly one combined summary and one
H01 reversible ledger. Require:

- 36 native gt tables;
- 783 internal-ID substitutions;
- 4,798 reconstructed `headers` substitutions; and
- 5,581 permitted substitutions in total.

Reverse the final durable H01 HTML with the returned ledger and require the
reconstructed hash to equal the combined summary's pre-hook SHA-256. Rerun the
accepted engine's DOM, visible-text, table, row, cell, header-cell, caption,
note, link, and count-preservation checks between reconstructed pre-hook HTML
and final HTML.

The final HTML must have document-wide unique IDs, every explicit `headers`
token resolving exactly once within its own table to the intended `th`, zero
dangling or unsupported ID references, and no visible change across the hook
boundary except the separately authorized fresh-render display changes.
Record the final HTML SHA-256, byte count, permissions, and exact build delta.
Classify `search.json`, `sitemap.xml`, and byte-identical CSS mtime behavior
separately rather than treating them as scientific drift.

## Reader and display verification

Verify all of the following without editing source:

- 36 native gt tables and ten figure endpoints;
- all captions, source notes, source-data links, dynamic internal links,
  navigation entries, country-coded site names, and zero embedded errors;
- the unbuilt Supplementary information link is the known shared DOC-001
  hold, not an H01 source defect;
- external HTTPS GitHub Edit links are external actions and are not subjected
  to internal-link resolution;
- the principal figure and principal table at final display size and at 200%;
- desktop-first table readability and contained horizontal scrolling at the
  narrow viewport;
- typography, labels, captions, notes, callouts, clipping, overflow,
  navigation, and link usability.

For visual QA, start one temporary read-only static server rooted exactly at
`_build/nathealth`, bound only to `127.0.0.1` on one unused high or ephemeral
port. Inspect the exact H01 result route in the in-app Browser at 1440 by 1000
and 708 by 1000. Do not use `file://`, another browser, CDP, Computer Use, a
LAN binding, or a public tunnel. Stop the server immediately after QA, prove
that no listener remains, and verify no post-QA file drift.

## Test classification and return

`tests/report_harmonization/test_post_render_gt_html_semantics.R` is the
accepted pre-integration transition test. It intentionally pins the defective
pre-render H01 HTML. Do not edit or rerun it after the durable render, and do
not classify its expected old-HTML pin as a new defect.

Return:

- exact preflight and post-render identities;
- complete Quarto and hook output;
- the final H01 HTML identity and exact build delta;
- external audit-directory path, combined-summary identity, reversible-ledger
  identity, counts, and reverse proof;
- complete H01 reporting-test and semantic results;
- protected-inventory reconciliation;
- desktop and narrow screenshots, measured final-size QA, and loopback
  teardown evidence; and
- a non-circular owner verification manifest.

Do not remove the external audit directory. The harmonizer will create and
verify a separate post-integration acceptance record, then remove the
temporary directory only after consuming its evidence. Stop and return any
unexpected hook, semantic, render, scientific, link, or visual defect.
