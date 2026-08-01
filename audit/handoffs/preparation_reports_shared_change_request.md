# Preparation reports: protected-file change request

Date: 2026-08-01

Status: **Resolved for the Preparation 06 showcase render; original failure evidence preserved**

Requested reviewer: coordinating task and owner

## Trigger

The Preparation 06 rewrite passed its focused static bounded-execution test.
Immediately before the first permitted page render, the protected-file gate
was rerun. It no longer matched the baseline created before authoring began.
No Quarto render was attempted after this failure.

Baseline:

- inventory:
  `audit/preparation_reports/preparation_report_protected_baseline.csv`;
- inventory creation time: 2026-08-01 14:02:56 +0200;
- inventory SHA-256:
  `7b6650477e6221091be2d9839840adaccaadb2a31f6297874455c86b08d556d3`;
- protected paths: 2,094.

Verification at 2026-08-01 14:33:39 +0200:

- unchanged: 2,029;
- mismatched: 65;
- missing: 0;
- matching byte size but changed SHA-256: 3;
- changed byte size and SHA-256: 62;
- matching SHA-256 among the 65 mismatches: 0.

The complete path-by-path baseline/current byte sizes, SHA-256 values, and
statuses are in
`audit/preparation_reports/preparation06_protected_verification_blocked.csv`
(SHA-256
`364526a30610e2e09fd098f190a9cf4935e86dffeae92929c45290818c991313`).

## Affected protected scopes

| Protected scope | Mismatched paths |
|---|---:|
| `artifacts/10_figures/` | 30 |
| `artifacts/09_tables/` | 7 |
| `artifacts/12_manifests/` | 6 |
| `artifacts/11_source_data/` | 5 |
| `scripts/hypotheses/` | 5 |
| `audit/hypotheses/` | 4 |
| `tests/hypotheses/` | 4 |
| `notebooks/hypotheses/` | 2 |
| `artifacts/08_diagnostics/` | 1 |
| `audit/handoffs/` | 1 |

Protected hypothesis sources or contracts among the mismatches are:

- `audit/hypotheses/H02/H02_analysis_preparation.qmd`;
- `audit/hypotheses/H03-H11_gated_workflow.qmd`;
- `audit/hypotheses/H11/02_implementation_and_v0_comparison.qmd`;
- `audit/hypotheses/implementation_result_comparison_contract.qmd`;
- `notebooks/hypotheses/H02.qmd`;
- `notebooks/hypotheses/H05.qmd`;
- `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`;
- `scripts/hypotheses/H02/build_h02_preparation_report_manifest.R`;
- `scripts/hypotheses/H11/build_h11_stage2_displays.R`;
- `scripts/hypotheses/H11/build_h11_stage2_manifest.R`;
- `scripts/hypotheses/H11/run_h11_stage2_analysis.R`;
- `tests/hypotheses/H02/test_h02_preparation_report.R`;
- `tests/hypotheses/H02/test_h02_reader_report.R`;
- `tests/hypotheses/H11/test_h11_stage2_contract.R`;
- `tests/hypotheses/H11/test_h11_stage2_outputs.R`;
- `audit/handoffs/H02_worker_handoff.md`.

The remaining mismatches are descriptive and H01 stage-3 figures, tables,
source data, diagnostics, and their manifests. Their exact paths and hashes
are in the verification CSV.

## Preparation-report worker actions

- Did not modify, restore, or adjudicate any mismatched protected file.
- Did not run any preparation, hypothesis, normalization, metric, model,
  bootstrap, simulation, prediction, or Shapley computation.
- Did not render Preparation 06 or any other Quarto page after the gate failed.
- Retained the Preparation 06 source rewrite and focused structural test for
  review; the static test result was PASS before the protected-file check.
- Recorded REPORT-011 figure sizing and post-render QA requirements, but no
  visual QA was possible because rendering is blocked.

## Decision needed

Please determine whether the 65 protected changes are accepted concurrent
work. If they are accepted, authorize a new protected-file baseline after the
shared checkout has reached the intended state. Otherwise, the responsible
owners must resolve or restore their files. The preparation-report worker
will not refresh the baseline, render, or continue to Preparations 01–05 and
07 without that decision.

## Owner response and showcase continuation

The owner subsequently requested to see the rendered new version. This was
treated as authorization to accept the current concurrent checkout state for
the showcase render while preserving the original baseline and 65-path
failure record rather than overwriting them.

A separate pre-render snapshot was created at
`audit/preparation_reports/preparation06_render_protected_baseline.csv`
(SHA-256
`153749b6be44ee5fa5a1a36869ef86d5ec0d53dff282ef0d7b5530ee545ce538`).
The final comparison is
`audit/preparation_reports/preparation06_final_protected_verification.csv`.

Across the render:

- 2,092 protected paths matched both byte size and SHA-256;
- two concurrently edited H02 handoff Markdown files had stale byte-size
  metadata in the pre-render snapshot but identical pre/post SHA-256 values;
- no protected content SHA-256 changed;
- all eight accepted Preparation 06 manifest bundles passed their independent
  path, byte-size, and SHA-256 checks inside the rendered page.

The two metadata-race paths were
`audit/handoffs/H02_shared_change_request.md` and
`audit/handoffs/H02_worker_handoff.md`. Their identical content hashes show
that the Preparation 06 render did not change their contents.

## New protected-file failure after the approved Table 13 repair

After the owner approved the Preparation 06 presentation pattern and asked
for Table 13 to be repaired before work continued to the other preparation
reports, a new continuation baseline was created from the then-current shared
checkout:

- inventory:
  `audit/preparation_reports/preparation_reports_approved_continuation_baseline.csv`;
- inventory SHA-256:
  `5706aa7d3cf98b46fae74635f42ecf854249d040de501f28132c9cf7e33f9ad3`;
- protected paths: 2,094.

The Table 13 repair changed only the Preparation 06 report and its focused
test. The page rendered successfully and the focused bounded-render test
passed. The required post-render protected-file comparison then found one
content mismatch:

- path: `audit/handoffs/H05_stage3_handoff.md`;
- role: `hypothesis_handoff`;
- baseline bytes: 10,185;
- current bytes: 10,185;
- baseline SHA-256:
  `7a7620b04af1609d2e0a4a3dbcc48c35726f46ab44689a4cb6e20027f3f1e5eb`;
- current SHA-256:
  `3e599a06e9f46b002577a5d6c680dcf4a34abc6f110118c58387e4230bce22f6`;
- filesystem status: untracked in the shared worktree;
- modification time observed: 2026-08-01 15:18:13 +0200.

The complete comparison is in
`audit/preparation_reports/preparation06_table13_postrender_protected_verification.csv`.
The preparation-report worker did not edit, restore, or adjudicate the H05
handoff. Under the protected-file boundary, this new mismatch blocks the
transition from Preparation 06 to Preparation 01 until the coordinator or
owner confirms that the H05 change is accepted concurrent work and
authorizes a refreshed continuation baseline.

## Final authorized delta reconciliation

The coordinator subsequently accepted the completed H05 closure identities
and authorized one final read-only comparison before a baseline refresh. The
comparison against
`audit/preparation_reports/preparation_reports_approved_continuation_baseline.csv`
checked all 2,094 protected paths and found four mismatches:

| Path | Baseline SHA-256 | Current SHA-256 | Reconciliation |
|---|---|---|---|
| `artifacts/12_manifests/H05/H05_stage3_artifacts.csv` | `9d410da62ce0f3202a740156e3389259d5cfe7557f67bbd628a5cdf0f6720633` | `674e8f64be6d4fdcf60075fa6c8b82afd3e64651af6326e98420e5108073941a` | Exact accepted H05 closure identity |
| `audit/handoffs/H05_stage3_handoff.md` | `7a7620b04af1609d2e0a4a3dbcc48c35726f46ab44689a4cb6e20027f3f1e5eb` | `ff6800d7f1fdf98db5bb3c920eaa745dead1566d13b932c9b01129e7ab805cf3` | Exact accepted H05 closure identity |
| `audit/handoffs/H01_shared_change_request.md` | `e87008f36432323cb5b453b1a74491eeae0dc78fdea21a784062e116540391ad` | `356341118351c26295cadf729a5ed5bc2d02dd9c2ca3f87cac17dd0052cd58ff` | **Not in the accepted closure paths** |
| `tests/hypotheses/H01/test_h01_reporting_inputs.R` | `845635c45d2a72d64e05532fa9c07ca11e4781c84d670256b54d7ac9844a3793` | `40c77e9fba70190e6e7b9ef0ec6e178deeda2ce43c825879c0304efd167a6907` | **Not in the accepted closure paths** |

The complete machine-readable comparison is
`audit/preparation_reports/preparation_reports_final_delta_reconciliation.csv`.
Because the two H01 changes were not authorized, the worker did not refresh
the continuation baseline and did not begin Preparation 01.

## Preparation 03 verification-provenance question

During the reader-facing rewrite of Preparation 03, the worker found that the
stored independent-verification statement is tied to an earlier profile
manifest rather than demonstrably to the current accepted profile artifacts.
No preparation or verification computation was run.

Exact evidence:

- the current
  `artifacts/12_manifests/reference_profile_artifacts.csv` has SHA-256
  `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062`;
- its stored artifacts were written on 2026-07-31 at 06:42:31 UTC after the
  exact-all-zero melEDI day rule changed the Preparation 02 inputs;
- `audit/findings/threshold_timing_zero_relevance_map.md`, dated 2026-07-30,
  states that 394 of 394 independent checks passed and identifies the verified
  manifest as
  `c8e02302521360d3a5cb18f49e0a97aed4a1f0ea64343ead68bde274cddce10d`;
- `audit/ledgers/change_log.csv` records the same earlier manifest identity for
  CHG-019, whereas CHG-053 describes the later downstream profile rebuild as
  still in progress; and
- the current manifest identity is pinned by later preparation-report and
  descriptive read checks, but those checks establish file identity only and
  do not reconstruct the scientific profile values.

The present Preparation 03 source says, without distinguishing manifest
versions, that the complete independent check reconstructed all 288 median
profile groups and all 36 probability-above-threshold groups, passed 394 of
394 checks, and matched all 11 file fingerprints. That visible statement may
therefore overstate the documented verification status of the current
2026-07-31 outputs.

Decision requested: either provide or identify a stored independent-verifier
record for the current manifest identity, or authorize the rewritten page to
report only the checks that can be established without scientific rerunning
(current manifest path/size/SHA-256 agreement, stored support diagnostics, and
the earlier 394-of-394 result explicitly labelled as applying to the preceding
manifest). Under the preparation-report boundary, the worker has not run
`verify_reference_profile_artifacts()` and is stopped before rewriting or
rendering Preparation 03.

### Coordinator resolution

PREP-002 subsequently confirmed that this was a version-specific reporting
gap, not evidence that the current profiles or downstream results are wrong.
The rewrite may continue without scientific rerunning. It must report current
manifest identity and stored-support checks as current, attribute the
394-of-394 independent reconstruction only to preceding manifest
`c8e02302521360d3a5cb18f49e0a97aed4a1f0ea64343ead68bde274cddce10d`,
and retain current-manifest independent reconstruction as open audit item
FIND-043. The worker therefore resumed at the documentation boundary and did
not run the independent verifier or rebuild any preparation artifact.

## Preparation 04 verification-provenance question

During the reader-facing inventory for Preparation 04, the worker found the
same class of version-specific verification gap. The available independent
verification records describe earlier metric and support-gate manifests, while
the accepted stored artifacts now used downstream have later identities and a
larger post-flat-zero-exclusion participant-day set. No preparation builder,
metric calculation, or verifier was run.

Exact evidence:

- the current 29-row metric manifest,
  `artifacts/12_manifests/metric_artifacts.csv`, has SHA-256
  `6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8`;
- the current stored metric settings identify 816 near-eye and 902 chest
  participant-days, whereas
  `audit/reconciliation/preparation04/core_verification.md` and
  `audit/reconciliation/preparation04/result_gate.md` independently verified
  811 near-eye and 897 chest participant-days and identify metric manifest
  `ac0325716421f2d90bb83b445ffb6ad965b131e382373e45f4ad6157eac5937d`;
- CHG-046 records an intervening metric-manifest identity,
  `944f395e00735e6f8200798d4cde387454441d39b9defda68f583bd8778cd34b`,
  for the later L10 round-off repair. It is also not the current manifest;
- the current MDER support-gate manifest,
  `artifacts/12_manifests/mder_support_gate_artifacts.csv`, has SHA-256
  `9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b`.
  The stored independent record in
  `audit/findings/mder_support_cutoff_gate.md` instead identifies manifest
  `c4ecfab41892e44b38dd78097277ccef5f94a379b44c7b309de281e9215a7b3c`
  and reports 733 of 811 near-eye and 825 of 897 chest participant-days at the
  80% support threshold. The current stored summary reports 760 of 816 and
  850 of 902, respectively;
- the current state-support manifest,
  `artifacts/12_manifests/state_support_gate_artifacts.csv`, has SHA-256
  `755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619`;
  and
- later downstream manifests pin the identities of current metric inputs, but
  an identity check does not independently reconstruct metric values or
  support classifications.

The existing Preparation 04 source executes the builders and verifiers and
therefore does not provide a safe stored-output-only wording model. The
rewrite cannot transfer the earlier independent-reconstruction claims to the
current manifests without a version-specific decision.

Decision requested: either identify stored independent-verifier records for
the three current manifest identities, or authorize version-specific wording
analogous to PREP-002. Under the latter option, the page would identify the
current manifest hashes and report only checks demonstrably current, attribute
each independent-reconstruction result solely to its earlier manifest, and
record current-manifest independent reconstruction as an open audit item.

This documentation gap is not evidence that the current metric data or any
downstream result is wrong. The worker has not run
`verify_metric_derivation_core()`, `verify_mder_support_gate_artifacts()`, any
state-support verifier, or any preparation builder, and is stopped before
rewriting or rendering Preparation 04 pending coordinator or author review.

### Coordinator resolution

PREP-003 subsequently confirmed that the mismatch is a version-specific
verification-provenance gap, not an analytical dependency and not evidence
that the current metric artifacts or downstream results are wrong. The
reader-facing rewrite may report current manifest identities and stored
summaries, but complete metric and MDER reconstruction results must remain
attached to their explicitly identified earlier manifests and samples. Exact
independent reconstruction of the current metric, MDER, and diary-period
support manifests remains open as FIND-044. The worker resumed without
running any builder, metric verifier, support verifier, or downstream
computation.
