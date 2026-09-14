# BA-018 independent M1 coverage-gate disposition

Date: 2026-09-12. Authority chain: BA-018 / CHG-157.
Status: SCIENTIFIC_STOP_CONFIRMED, AUTHOR_DISPOSITION_REQUIRED.
The scientific replacement package is not decision-ready for final acceptance.
`BA-LB-G2-REVIEW` remains open. This record authorizes no new computation,
retry, model change, report or integration.

## Independent evidence

The owner Stage 2 root is
`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/`.
The scientific stop is under `completion_v2/continued_final_package_002/`:

- Final manifest: `5753221dd6a001c1715e2ba8e3e34ec2a83976e6d4ed0f637fa2cf3ac22baa80`,
  182 exact, unique, non-circular members.
- Verification: `6d2cdb8eb1036aba5a72f17edd03cf1f32d9c328e5de7fc06216da2e32f7d46a`.
- Handoff: `a9218c8e1a1b15d67f6e72ffb3f6be634acbefb6ab06b1479c2800fc483c1347`.
- Open gate: `d9c8d95ce57faecbed7a5009c2637b25b1b8f0d873b1072cc69839cfb2600b32`.
- Sixteen stored finalization checks:
  `c8dabe78033fe7d672c7fafffab48f043c569335185ce6e5c89302b4155c6d58`.

The full current estimand/multiplicity manifest is
`baff7f3cb89565235193a2a74dc64afd82a58e3fea3d519c55fce08318d4863a`,
23/23 exact. All 18 independent R 4.6.1 stored-output checks pass. These
audit checks reproduce the scientific failure; they do not turn it into PASS.
The stored scientific validation remains 12/13, with only
`M1_80_claim_gate` false. No model, RDS, prediction, uncertainty derivation,
diagnostic or render was evaluated by this independent audit.

## Confirmed finding BA-LB-M1-COVERAGE-001

Category: claim robustness. Confidence: confirmed. Severity: high for release
of an unqualified primary claim, not evidence of corrupted data or invalid
model fitting.

The immutable Stage 1 plan, line 144, requires all three M1 effects to retain
direction and 95% interval-exclusion status, with at most a 2-percentage-point
shift. Its line 292 explicitly stops Stage 2 for a failed prescribed coverage
claim gate. The Stage 2 transition carries that exact contract forward.

The Pre-sleep Free-minus-Work, equal-site contrast is:

| Sample | Difference, percentage points | 95% interval, percentage points |
| --- | ---: | ---: |
| Primary any-valid | 5.9179818185073 | 1.38004439137757 to 10.455919245637 |
| At least 80% coverage | 4.11661227878292 | -0.856565126950924 to 9.08978968451676 |

Both point estimates are positive. Their absolute shift is
1.80136953972438 percentage points, within the existing 2-point limit.
Only interval-exclusion status changes. Daytime and Sleep meet all three
criteria. This is not a direction reversal, not a coding failure, and not a
test establishing that the two sample estimates differ from each other.

Exact source: `estimands/B_to_B80_claim_gate.csv`, key
`analysis_state=Pre-sleep`, `family=BA-M1`,
`contrast=Free day minus Work day`, `weighting=equal_site`, SHA-256
`1dea9c6364e8cb87bf8d52ecb9b7ac8e4d12a739b248d4c96e71cc7df38f1dd6`.
It matches the corresponding complete `multiplicity/BA_M1.csv` rows for both
samples. The percentage-point table above is only a scale conversion of those
stored estimates and limits, reproduced in the retained R audit.

Both full 54-cell grids, all historical-B cell reproductions, quadrature,
the complete M1-M5 families, omnibus ranks, M6 components and state sums,
absence of a second M6 support-sample FDR family, probability bounds and the
M6 coverage/localized-direction gate pass their stored checks. These results
do not establish the still-unexamined endpoint, overall-calibration, temporal,
influence or remaining sensitivity assessment. The fitted models remain
provisional. Raw membership was not rederived by this focused audit; its
existing protected source and model-input evidence remains controlling.

## Disposition and proposed author choice

Accept the stop as correctly enforced. Preserve the failed gate, both model
bundles, all exported results, family definitions, confidence levels and job
history unchanged. Do not rerun the estimand driver, select another model,
change thresholds or call the coverage finding a structural fit failure in
order to obtain a desired result.

The bounded proposed continuation for author consideration is to complete the
already planned diagnostics and sensitivities, while retaining this failed
gate and explicitly restricting the Pre-sleep claim as coverage-sensitive.
This is a proposal, not execution authority. The author must decide before
any new Brown job. A later exact continuation would need to classify this
sealed scientific stop in the supervisor without marking it successful or
repeating any fit/estimand export. Decomposition eligibility and any report
release must be resolved under that explicit scope and the remaining results,
not inferred here.

## Preservation and holds

The versioned retry used its exact approved driver and supervisor once. The
additional 31.406769749999512 seconds remain counted. Total recorded time is
99.408186624990776 seconds within the same 1,200-second budget, not a reset.
There are seven jobs, with the original bookkeeping stop and this scientific
stop both preserved as nonzero. The latest child was reaped without timeout.
A fresh exact-PID process probe found PID 70118 absent; no process was killed.

No diagnostics, draws, deletion/temporal sensitivity, decomposition, report,
Stage 3/4, S5, manuscript, selection-page, website or Writer numerical update
is released. The Harmonizer's read-only website preflight may finish. The
Writer's returned layout proposal is durably archived but not implemented.
The current documents remain previews, not final accepted deliverables.
Browser denials and all independent rendering/visual gates remain binding.
