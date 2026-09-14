# REPORT-018 H01 METRIC-010 point-baseline acceptance and pilot authority

Date: 2026-08-31  
Status: **POINT BASELINE ACCEPTED; PILOT AUTHORIZED; PRODUCTION HELD**

## Authority

During the selection scientific-scope audit, the H01 owner relayed the author's explicit acceptance of the H01 METRIC-010 point-result baseline and request to implement the changes. This closes only the material point-baseline author gate documented in:

- `audit/hypotheses/H01/mder_METRIC-010/H01_METRIC-010_author_gate.md`, SHA-256 `c4d9842dc59b51afcc7fc50426903ab9b656fc29beac9e9cba2dcf4372f142cc`;
- `audit/hypotheses/H01/mder_METRIC-010/author_gate_post_repair/H01_METRIC-010_gate_summary.csv`, SHA-256 `0d7876c800b4862b22a4ab92c4cc7dde3b4aa77273137eb74f9d883bbe1e1b92`; and
- controlling METRIC-010 decision `audit/decisions/mder_mean_of_viable_ratios.md`, SHA-256 `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`.

The accepted point baseline consists of eight isolated MDER runs, zero major diagnostic failures, three primary MDER support changes, one primary non-MDER multiplicity consequence, and the documented gap-timing-unaware and paired-placement interpretation.

## Authorized pilot

The H01 owner may run one separately stored 50-successful-refit production-code pilot for every planned MDER bootstrap target. Every pilot output must be labelled:

`PILOT - NOT FOR INFERENCE OR MANUSCRIPT REPORTING`

The pilot must:

1. use the corrected `mder_mean_of_viable_ratios` primary and repaired gap-timing-unaware inputs;
2. bridge any current post-METRIC-011 input pins to the sealed MDER frames by exact identity and reconciliation before execution;
3. preserve every accepted non-MDER scientific artifact and every current accepted H01 report artifact;
4. store code, inputs, outputs, checkpoints, logs, tables, and figures only in a separate pilot evidence root;
5. target 50 successful refits for each planned MDER bootstrap target and record attempts, failures, warnings, seeds, runtime, checkpoint behavior, resource use, and consequential package versions;
6. provide preview uncertainty and multiplicity summaries only as pilot evidence, never as accepted inference; and
7. stop at `H01-METRIC010-PILOT-REVIEW` for separate production approval.

Any identity mismatch, non-MDER drift, unplanned target, model-definition change, or inability to reproduce the accepted point baseline requires a fail-closed return.

## Not authorized

This authority does not permit:

- the production bootstrap;
- replacement of any accepted production model, diagnostic, table, figure, source-data, manifest, QMD, or HTML artifact;
- final BH/FDR or other multiplicity promotion;
- Stage 2, Stage 3, or Stage 4 reporting refresh;
- a Quarto render or manuscript edit;
- a central ledger, profile, package, or lockfile change;
- a commit, push, upload, or publication; or
- treating pilot previews as inferential or reportable results.

After the pilot, the owner must return runtime, failures and warnings, checkpoint status, resource use, and preview tables and figures. A separate explicit production approval is required before any accepted scientific or reporting target may change.

