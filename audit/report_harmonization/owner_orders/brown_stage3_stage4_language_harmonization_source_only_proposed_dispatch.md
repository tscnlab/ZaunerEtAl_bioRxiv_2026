# Proposed Brown Stage 3 and Stage 4 paired source-language harmonization order

Date: 2026-08-21

Status: **PROPOSED FOR CENTRAL REVIEW; NOT DISPATCHED**

Implementing owner: Brown adherence task
`019fffdf-66d4-7802-9091-09283ad27b7f`

This order has no execution authority until the coordinator independently
accepts the read-only audit and explicitly dispatches this exact order.

## Controlling package

- read-only audit:
  `audit/report_harmonization/brown_stage3_stage4_paired_language_read_only_audit.md`,
  SHA-256
  `4c28cebece937a0d8f34f5c1a41b3272fdfaf9c916e9cd0885fa91bc17bc44f2`,
  9,189 bytes;
- exact 34-row change matrix:
  `audit/report_harmonization/brown_stage3_stage4_language_change_matrix.csv`,
  SHA-256
  `4f684d62236658b3bc7ae6fdfc37984fcb2bfc727e151842144e53e83c8aafae`,
  29,488 bytes;
- controlling transition:
  `audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition.md`,
  SHA-256
  `3bf604c4ad60a8ef3efb452626598306f5e473b341781e89a84218b6eb9a7583`;
  and
- queued source-language authority:
  `audit/report_harmonization/owner_orders/brown_stage3_stage4_language_harmonization_source_only.md`,
  SHA-256
  `4b1f1857e66cb486fcc94fe1e65bbc47cda39e7cd33f34efbf79081b9e24a89a`.

The owner must implement all 34 approved actions as one coherent source pass.
Do not omit an action, add an unlisted editorial change, or split the two
documents into independent wording passes.

## Hard preflight pins

Stop without editing if any pin differs:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Stage 3 QMD | 52,506 | `80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997` |
| Stage 3 HTML | 4,808,772 | `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0` |
| Stage 4 QMD | 24,147 | `642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29` |
| Stage 4 semantic HTML | 4,340,432 | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| Stage 3 accepted fallback manifest, 76 rows | 44,950 | `69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21` |
| Stage 4 final manifest, 113 rows | 54,203 | `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2` |
| Stage 4 final-manifest verification | 29,804 | `60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38` |
| Brown `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The baseline commit is
`442ddd1b592374440f1446c26234c5d6e12cce92`. Record it as provenance, but
hard-pin the exact owner-scoped files above because the isolated worktree may
contain unrelated accepted changes.

## Authorized owner paths

The owner may edit only:

1. `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`;
2. `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd`;
3. one new dedicated paired source verifier at
   `audit/analyses/brown_adherence/language_harmonization/01_verify_stage3_stage4_source_harmonization.R`;
4. one new handoff at
   `audit/analyses/brown_adherence/language_harmonization/brown_stage3_stage4_language_harmonization_handoff.md`;
   and
5. new non-circular source-only evidence under
   `audit/analyses/brown_adherence/language_harmonization/source_only/`.

Do not edit an existing historical source or render verifier. Do not edit an
accepted Stage 3 or Stage 4 manifest. The new completion manifest must exclude
itself and must not create a circular dependency.

## Exact source changes

Apply exactly the rows in
`audit/report_harmonization/brown_stage3_stage4_language_change_matrix.csv`:

- `BROWN-LANG-S3-001` through `BROWN-LANG-S3-020` to Stage 3; and
- `BROWN-LANG-S4-001` through `BROWN-LANG-S4-014` to Stage 4.

The source pass must use the matrix replacement wording or rule, not a new
interpretation. A phrase may be adjusted only for grammar required by its
immediate sentence, and that exact adjustment must be recorded in the change
ledger and shown to preserve the matrix meaning and protected tokens.

Required paired outcomes include:

- one stable `sec-brown-main-results` anchor and one stable
  `sec-brown-cross-state` anchor in Stage 3;
- one stable `sec-brown-provenance` anchor in Stage 3;
- the existing Stage 3 `07_results.qmd` target retained exactly once;
- the Stage 3 Answer in brief callout stating confidence-interval exclusion
  separately from the corresponding tests meeting their FDR threshold;
- exactly one Stage 3 link to the Stage 4 `sec-purpose` anchor;
- Stage 4 result links using the Stage 3 `sec-brown-main-results` anchor;
- relative `.qmd` links only for reader-document navigation;
- removal of only the six manual numeric prefixes from Stage 4 H2 headings,
  while retaining their source anchors; and
- complete preservation of every existing endpoint, source-data target,
  scientific caption or alt-text fact, and technical provenance target.

## Scientific freeze

The paired source verifier must fail closed on any unapproved change to:

- a number, threshold, sample, denominator, state definition, date ownership,
  formula, endpoint process, estimate, interval, p-value, FDR result, family,
  model check, sensitivity result, R-squared value, Shapley value, support
  count, or claim disposition;
- `BA-M1` through `BA-M6` or `BA-CS-M1` definitions, sizes, rows, and results;
- any-valid primary construction or the at-least-80-percent sensitivity
  construction;
- the main versus exploratory hierarchy;
- the withheld within-participant day-level claim;
- the limited, non-causal between-participant interpretation;
- the no-ranking, no-trade-off, no-intervention, and no-independent-replication
  boundaries;
- the complementary chest and bedside sleep-environment roles; or
- any source CSV, RDS, PNG, SVG, manifest, model, builder, lockfile, privacy
  boundary, or historical evidence file.

Do not fit, refit, predict, simulate, bootstrap, resample, calculate an
inferential result, recalculate R-squared or Shapley values, regenerate an
artifact, execute a broad manifest builder, or run Quarto.

## Dedicated source-verifier contract

Use R 4.6.1. Build the verifier before the one complete source-only run. It
must check at least:

1. the exact preflight identities above;
2. R parsing of all 19 Stage 3 and 18 Stage 4 labelled chunks;
3. exactly 110 Stage 3 and 59 Stage 4 parsed R expressions;
4. all 38 Stage 3 inline R expressions byte-for-byte;
5. function-call, object-name, numeric, logical, formula, source-path, and
   expression-order identity within executable chunks, allowing only the
   exact matrix-authorized display character-string substitutions;
6. exactly 16 Stage 3 table endpoints and five figure endpoints, and exactly
   17 Stage 4 table endpoints plus one `flowchart TD` Mermaid diagram;
7. endpoint uniqueness and order, table and figure construction, source-data
   targets, captions, notes, and alt-text scientific content;
8. exact protected-token sets for samples, thresholds, BA families, estimates,
   intervals, p-values, FDR outcomes, model-check results, R-squared values,
   Shapley values, sensitivity results, privacy counts, and limitations;
9. all 34 matrix actions present once, with no unlisted source transition;
10. the three new Stage 3 anchors and all retained Stage 4 anchors unique;
11. reciprocal links resolving to their prospective QMD anchors;
12. exact preservation of the complete pre-existing relative reader and source-data target multiset,
    including the Stage 3 `07_results.qmd`
    target, every existing implementation-report and source-data target, and
    all existing Stage 4 result links; only the matrix-specified Stage 4
    anchor-suffix additions and the single new Stage 3-to-Stage 4 reciprocal
    link may be added;
13. zero reader-document `.html`, absolute, `file:`, worktree-local, or build
    paths;
14. zero fitting, prediction, simulation, resampling, artifact-write,
    rendering, or broad-builder calls introduced;
15. both accepted HTMLs and all accepted manifests byte-identical; and
16. exact reverse reconstruction of both baseline QMD hashes and byte counts
    from a complete change ledger.

The verifier should report all failures from its one complete run rather than
stop at the first wording assertion. A scientific discrepancy or an
unapproved executable-source difference remains fail-closed.

## Execution and return

The owner may run only source parsing, the dedicated source verifier, exact
diff and reverse checks, protected-identity checks, and scoped formatting or
diff checks. Do not execute either QMD. Do not start Quarto, Pandoc, a browser,
or a loopback server.

Return one package containing:

- both post-edit QMD identities and byte counts;
- the new verifier identity, command, R version, runtime, and complete result;
- the exact 34-action ledger;
- pre/post endpoint, link, expression, and protected-token inventories;
- exact reverse proofs for both QMDs;
- a preservation inventory for both historical HTMLs, both accepted manifests,
  Brown scientific artifacts, and `renv.lock`;
- the new handoff; and
- one exact, unique, non-circular completion manifest.

Stop for independent harmonizer and coordinator acceptance. No render is authorized.
Later rendering requires two separate serial releases: Stage 3 first, then
Stage 4 only after Stage 3 acceptance.
