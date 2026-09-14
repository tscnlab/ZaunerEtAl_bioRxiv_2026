# Brown adherence Stage 3 and Stage 4 language-harmonization source acceptance

Date: 2026-08-21

Controlling decision: `BA-016`

Controlling change: `CHG-155`

Status: **SOURCE-ONLY INDEPENDENTLY ACCEPTED**

## Disposition

The paired Brown Stage 3 and Stage 4 source-language harmonization is accepted
at its source-only stop. All 34 approved language actions were implemented in
one paired pass, and no unapproved source or scientific change was found.

This acceptance creates no new Brown decision or change identifier. The
scientific authority remains `BA-016 / CHG-155`, and the author-approved Stage
3 and Stage 4 packages remain the historical scientific baseline.

## Accepted post-edit sources

The following identities in the isolated Brown worktree are authoritative for
the next integration gates:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 55,426 | `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43` |
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd` | 24,416 | `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475` |
| `audit/analyses/brown_adherence/language_harmonization/01_verify_stage3_stage4_source_harmonization.R` | 49,667 | `1819c29ee644886b2a0c1f17ee27a2c45e2f006210e7917463dffb6360a33fc0` |
| `audit/analyses/brown_adherence/language_harmonization/brown_stage3_stage4_language_harmonization_handoff.md` | 2,361 | `9fce5e71a270eda25e62d557bbecb3862fdd3c197c647b5ff0ff11e8f938bb02` |
| `audit/analyses/brown_adherence/language_harmonization/source_only/source_only_final_manifest.csv` | 3,659 | `bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46` |

## Independent verification

The durable read-only checker is:

`scripts/report_harmonization/check_brown_stage3_stage4_source_independent_acceptance.R`

It independently reproduced all of the following under R 4.6.1 with digest
0.6.39:

- 12 of 12 central authority and dispatch identities;
- 19 of 19 unique, non-circular owner-manifest members;
- 22 of 22 owner source checks and 34 of 34 approved action rows;
- 189 of 189 historical Stage 3 and Stage 4 manifest members;
- two of two exact reverse reconstructions to the accepted pre-edit QMDs;
- Stage 3 structure of 19 R chunks, 110 expressions, 38 unchanged inline R
  expressions, 16 tables, and five figures;
- Stage 4 structure of 18 R chunks, 59 expressions, 17 tables, and one
  top-down Mermaid diagram;
- exact Stage 3 executable-core identity;
- exact Stage 4 executable-core identity apart from the single approved
  `cols_label()` display relabeling;
- the complete pre-existing relative link-target multisets, plus only the
  approved reciprocal Stage 3 link and Stage 4 anchor suffixes;
- exactly one retained `07_results.qmd` link; and
- the required unique section anchors and unchanged table and figure endpoint
  identities.

Both source diffs pass whitespace checks. The owner verifier passes Air 0.4.1
formatting. Neither harmonized QMD contains an em dash.

## Scientific and historical preservation

The paired pass changed reader language, hierarchy, captions, headings,
explanations, and reciprocal links only. It did not change any model, sample,
formula, estimate, interval, p-value, multiplicity family, FDR decision,
diagnostic, R-squared value, Shapley value, figure or table source, plotted
geometry, privacy boundary, accepted limitation, or claim scope.

The following historical endpoints remain byte-identical:

- Stage 3 HTML `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0`;
- Stage 4 semantic HTML `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f`;
- the accepted 76-member Stage 3 manifest
  `69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21`;
- the accepted 113-member Stage 4 manifest
  `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2`;
  and
- `renv.lock`
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

No QMD was executed. No Quarto, Pandoc, browser, or loopback server was
started. No model, prediction, inference, resampling, or scientific artifact
was produced.

## Render boundary and next stop

This record accepts sources only. It does not authorize a render.

The harmonizer must independently accept this exact owner return and then seal
one separate Stage 3-only target-render order. That later order must pin the
accepted Stage 3 source above, preserve all scientific artifacts and the
historical Stage 3 package, apply the accepted semantic table repair, verify
links, anchors, privacy, and protected tokens, perform bounded served-page
visual QA, and tear down its loopback listener.

The Stage 4 render remains held until the harmonized Stage 3 render is
independently accepted. A combined two-page render and a full-project render
remain prohibited.
