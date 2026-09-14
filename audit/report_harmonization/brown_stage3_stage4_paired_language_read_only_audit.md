# Brown Stage 3 and Stage 4 paired language read-only audit

Date: 2026-08-21

Status: **AUDIT COMPLETE; IMPLEMENTATION APPROVAL PENDING**

Owner sources remain unchanged. No Brown source, HTML, test, handoff, manifest,
scientific artifact, profile, package, lockfile, or shared file was edited or
rendered during this audit.

## Authority and scope

This audit implements the read-only prerequisite in:

- `audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition.md`,
  SHA-256
  `3bf604c4ad60a8ef3efb452626598306f5e473b341781e89a84218b6eb9a7583`;
  and
- `audit/report_harmonization/owner_orders/brown_stage3_stage4_language_harmonization_source_only.md`,
  SHA-256
  `4b1f1857e66cb486fcc94fe1e65bbc47cda39e7cd33f34efbf79081b9e24a89a`.

The author has accepted the scientific Stage 3 and Stage 4 package and asked
for language harmonization. The task is therefore editorial and structural.
It may improve reader terminology, hierarchy, explanations, captions, notes,
alt text, and reciprocal source links. It may not change an analysis, result,
sample, uncertainty statement, multiplicity decision, model check, model-fit
summary, sensitivity result, or claim boundary.

## Accepted baselines

The complete audit used the accepted Brown worktree at baseline commit
`442ddd1b592374440f1446c26234c5d6e12cce92`. The controlling identities are:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 52,506 | `80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 4,808,772 | `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0` |
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd` | 24,147 | `642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29` |
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html` | 4,340,432 | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| Stage 3 accepted fallback manifest, 76 rows | 44,950 | `69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21` |
| Stage 4 final manifest, 113 rows | 54,203 | `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2` |
| Stage 4 final-manifest verification | 29,804 | `60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38` |
| Brown `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The audit also read the accepted Stage 3 and Stage 4 handoffs and the four
existing source and render verifiers completely. Those historical verifiers
remain evidence of their accepted states. They should not be rewritten to
serve as mutable language-harmonization tests.

## Complete source and rendered-page inventory

R 4.6.1 parsed both QMDs and inspected both HTML documents with `xml2`.

| Contract | Stage 3 | Stage 4 |
|---|---:|---:|
| Source lines | 1,317 | 747 |
| Parsed R expressions | 110 | 59 |
| Inline R expressions | 38 | 0 |
| Labelled R chunks | 19 | 18 |
| Native gt table endpoints | 16 | 17 |
| Figure endpoints in source | 5 | 1 Mermaid diagram |
| Native gt tables in current HTML | 16 | 17 |
| Figures in current HTML | 5 | 1 Mermaid diagram |

All expected captions, source links, endpoint labels, headings, and current
cross-links were enumerated. No missing scientific endpoint or source-data
link was found. The Stage 4 HTML does show duplicated top-level numbering
because six source headings contain manual numeric prefixes while
`number-sections: true` also numbers them. Removing only those manual prefixes
is an approved structural source correction in the change matrix.

## Findings

### Scientific content

No scientific discrepancy was found. The audit did not identify a changed or
unsupported number, sample, formula, estimate, confidence interval, p-value,
FDR decision, diagnostic result, R-squared value, Shapley value, sensitivity
result, or claim disposition.

The following boundaries remain mandatory:

- the endpoint-inflated Brown analysis is the main analysis;
- the cross-state association is separate, exploratory, and non-causal;
- the within-participant day-level claim remains withheld;
- the between-participant association is not a within-person intervention
  effect or an independent replication;
- chest measurements remain complementary context and not ocular exposure;
- the site-average estimate gives each of the nine sites equal weight;
- `BA-M4` tests a site-specific Free-minus-Work difference against zero,
  whereas `BA-M6` compares it with the state-specific site-average
  Free-minus-Work estimate;
- marginal and conditional R-squared values are descriptive point summaries;
  and
- Shapley allocation distributes shared fitted-model information and is not a
  causal or uniquely identified variance decomposition.

### Reader vocabulary and structure

The two documents need one coordinated source-language pass. The principal
reader-facing inconsistencies are:

1. alternating terms for the same equal-site estimand;
2. workflow-status words such as accepted, frozen, gate, and release in the
   Stage 3 reader flow;
3. insufficient first-use explanations for FDR, random intercepts,
   participant-level variation, marginal and conditional R-squared, and
   Shapley allocation;
4. inconsistent use of diagnostics versus model checks and gate versus
   sensitivity analysis;
5. inconsistent near-eye, chest, and bedside measurement-role wording;
6. technical `BH-adjusted p` or `FDR q` display labels where the corpus uses
   `FDR-adjusted p`, while the Benjamini-Hochberg method still belongs in
   detailed methods;
7. Stage 4 double numbering; and
8. incomplete reciprocal anchored QMD navigation between the result report and
   provenance companion.

The opening Stage 3 orientation must retain its existing relative
`07_results.qmd` link while introducing the within-participant and
between-participant distinction. The Answer in brief callout must also state
confidence-interval exclusion and the corresponding FDR-threshold results as
separate evidence, rather than implying that interval exclusion occurred
after multiplicity adjustment.

The exact 34-row implementation matrix is:

`audit/report_harmonization/brown_stage3_stage4_language_change_matrix.csv`

It contains 20 Stage 3 actions and 14 Stage 4 actions. Every row records the
current wording or structure, the replacement wording or rule, the reason,
protected scientific tokens, and the required source check.

## Verification design for the source pass

The historical Brown verifiers and accepted HTML and manifests remain
byte-identical. The source owner should add one dedicated paired source-only
verifier that:

- parses all 19 Stage 3 and 18 Stage 4 chunks;
- preserves the 110 and 59 parsed R-expression sequences exactly after
  excluding only approved display-string substitutions;
- preserves all 38 Stage 3 inline R expressions byte-for-byte;
- preserves formulas, thresholds, sample and result tokens, source-data paths,
  endpoint sets, figure paths, table construction, and scientific row order;
- proves exactly 16 Stage 3 tables and five figures plus 17 Stage 4 tables and
  one top-down Mermaid diagram remain present;
- requires all existing captions, alt-text scientific content, and source-data
  links to remain represented;
- requires one unique `sec-brown-main-results` anchor, one unique
  `sec-brown-cross-state` anchor, and one unique `sec-brown-provenance` anchor;
- requires reciprocal relative `.qmd` links and rejects `.html`, absolute,
  `file:`, worktree-local, and build-output reader links;
- preserves the complete pre-existing relative reader and source-data target
  multiset, including the Stage 3 `07_results.qmd` target, all existing
  implementation-report and source-data targets, and every existing Stage 4
  result link; only the matrix-specified Stage 4 anchor suffixes and the one
  new Stage 3-to-Stage 4 reciprocal target may be added;
- rejects fitting, prediction, simulation, resampling, artifact writes,
  rendering, or broad-builder execution; and
- reconstructs both exact pre-edit QMDs from a complete reversible change
  ledger.

The source-only order must stop after one complete verifier execution. It may
not run Quarto or mutate either accepted HTML.

## Pass and render disposition

The two documents should be edited together in one paired source-only pass.
This prevents terminology and reciprocal-link drift and allows one complete
scientific-token audit.

They must then be rendered in two separate serial passes after independent
source acceptance:

1. Stage 3 result report, followed by structural, semantic, link, privacy, and
   served-page visual acceptance;
2. Stage 4 provenance companion only after Stage 3 acceptance, with the same
   checks plus final provenance-manifest reconciliation.

A combined render or full-project render is not appropriate. This audit
authorizes neither source editing nor rendering. The proposed bounded owner
order must receive central approval before dispatch.
