# REPORT-014/017 order 35b: H04 country-label source reflow

Date: 2026-08-20

Owner: H04 task `019febf4-4868-72f3-bd97-31a85e86f8f0`

Status: authorized source-only whitespace reflow; every H04 render remains held

## Purpose

Repair exactly two source-line wraps so the already accepted reader labels
`Delft (NL)` and `Munich (DE)` are each contiguous in their QMD source. This
is a whitespace-only source synchronization. It does not change rendered
prose, scientific content, endpoint order, or any analytical object.

The required H01 sequencing checkpoint is durably recorded in
`audit/hypotheses/H01/report017_order32k_companion_acceptance/order32k_h04_global_country_findings.csv`,
SHA-256 `cc7d51ae2248b9223250580f12b48bc6092d10eb9b22e85a6682ee923f31f963`.
It contains exactly:

- `notebooks/hypotheses/H04.qmd:886`, bare `Delft` with required display
  `Delft (NL)`;
- `audit/hypotheses/H04/H04_analysis_preparation.qmd:914`, bare `Munich` with
  required display `Munich (DE)`.

No other country-site finding is present.

## Hard preflight pins

Stop before mutation unless every dispatch-manifest row is exact. The central
source pins are:

- result QMD:
  `63e815683e1e81dadd480aeb230c7913de7726aa9242f5ce89ec4a0e7e90471c`,
  83,285 bytes;
- companion QMD:
  `52160297aaaa65f9cc0e36839adb0fcbe86e55631c847476b5006f03d657e9da`,
  91,202 bytes;
- H04 source test:
  `934ec16dcd2b7e6c4b2771f09f35c0832d059d695c21c5b917ba3303bd16c19b`,
  33,144 bytes;
- participant random-intercept test:
  `247523ec05b484e161e2717a21d33314375370b84413a3bbcfb150582b86ad90`,
  9,022 bytes;
- owner handoff:
  `1961b349d527b3c945d0d299a27f46603a674843629a918461ea2a504023b50a`,
  30,132 bytes;
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

The accepted order-35a sources and verification remain historical evidence
under acceptance `de987cb6...` and 17-row manifest `5173ebe8...`. Preserve all
order-35 and order-35a evidence byte-for-byte.

The coordination-matrix identity at dispatch is evidence only, not a mutable
owner execution pin.

## Authorized source reflow

Edit only these two QMD regions:

1. In `notebooks/hypotheses/H04.qmd`, reflow the existing country-list
   whitespace so `Delft (NL)` is contiguous on one source line. Preserve the
   exact reader text and punctuation.
2. In `audit/hypotheses/H04/H04_analysis_preparation.qmd`, reflow the existing
   country-list whitespace so `Munich (DE)` is contiguous on one source line.
   Preserve the exact reader text and punctuation.

The complete result-source text after removing all whitespace must be
byte-identical to its preimage after removing all whitespace. The same is
required independently for the companion. Require the full non-whitespace
byte and token sequences to be identical before and after. Require exactly two
zero-context QMD diff hunks and exact reverse substitution to both preflight
QMD hashes.

All R chunk bodies, inline-R expressions, chunk labels, figure and table
labels, captions, alt text, links, formulas, numeric tokens, assignments,
artifact references, and source-data references must remain byte-identical.

## Current handoff synchronization

Preserve the historical order-35 source identities already recorded in
`audit/handoffs/H04_worker_handoff.md`. Append one bounded order-35b source
reflow note that records:

- the two new QMD SHA-256 identities and byte counts;
- that normalized reader text and every non-whitespace byte/token sequence are
  unchanged;
- the exact two-line country-label repair;
- source-test and global country-test results; and
- that no render, QMD execution, or scientific computation occurred.

Do not rewrite any historical handoff identity or scientific statement. Create
an exact handoff diff and reverse proof to SHA-256
`1961b349d527b3c945d0d299a27f46603a674843629a918461ea2a504023b50a`.

No existing current H04 manifest is expected to require resealing. Do not run
a manifest builder. If the complete source test proves that one directly
dependent current test or manifest literal must follow the two new source
identities, stop and report the exact dependency instead of broadening this
order.

## Verification

Under R 4.6.1:

1. parse every R chunk in both QMDs without executing it;
2. verify the two exact reverse proofs and the whitespace/non-whitespace
   contracts;
3. verify byte-identical executable R chunks, inline expressions, endpoint
   sets and order, formulas, scientific numeric tokens, assignments, links,
   source-data references, and protected artifacts;
4. run the unchanged participant random-intercept assessment test once;
5. run the unchanged complete H04 source harmonization test once, writing its
   bounded audit to the new order-35b evidence directory;
6. run the unchanged global country-coded-site test and require PASS with zero
   findings; and
7. run scoped `git diff --check`.

The H04 source test must retain all 37 accepted gates. The auxiliary test must
use only its accepted stored artifacts and must not refit. The global country
test must pass because the exact H01-recorded two-path failure set is removed,
with no new finding.

Write only bounded snapshots, diffs, reverse proofs, command logs, test output,
protected audits, and one non-circular owner manifest under
`audit/hypotheses/H04/report017_order35b_country_label_reflow/`.

## Prohibitions and stop rule

Do not edit any scientific wording, value, formula, code chunk, test,
scientific artifact, source data, existing manifest, historical evidence,
HTML or build copy, profile, shared configuration, central ledger, package, or
lockfile. Do not run Quarto, execute a QMD, fit or refit, calculate science,
regenerate an artifact, render, commit, push, or upload.

Return one combined source-only seal. On any new failure, do not patch or
retry. Seal one stopped state and return the complete bounded finding. Every
H04 render remains held. H01 remains the sole active integration path.
