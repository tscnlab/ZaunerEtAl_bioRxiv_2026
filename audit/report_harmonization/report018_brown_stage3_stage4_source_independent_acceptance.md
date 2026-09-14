# REPORT-018 Brown Stage 3 and Stage 4 source independent acceptance

Date: 2026-08-21

Disposition: **ACCEPTED SOURCE-ONLY; STAGE 3 RENDER MAY BE REQUESTED SEPARATELY**

Owner: `019fffdf-66d4-7802-9091-09283ad27b7f`

Owner worktree:
`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`

## Accepted source package

The paired Brown language harmonization is accepted at these exact identities:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Stage 3 QMD | 55,426 | `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43` |
| Stage 4 QMD | 24,416 | `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475` |
| Paired source verifier | 49,667 | `1819c29ee644886b2a0c1f17ee27a2c45e2f006210e7917463dffb6360a33fc0` |
| Owner handoff | 2,361 | `9fce5e71a270eda25e62d557bbecb3862fdd3c197c647b5ff0ff11e8f938bb02` |
| Owner 19-row non-circular manifest | 3,659 | `bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46` |

The owner verifier passed under R 4.6.1:

`BROWN_STAGE3_STAGE4_SOURCE_HARMONIZATION=PASS actions=34/34 checks=22/22 stage3=19_chunks/110_expr/38_inline/16_tables/5_figures stage4=18_chunks/59_expr/17_tables/1_mermaid historical=189/189 reverse=2/2 manifest=19/19 R=4.6.1 quarto=0 qmd_execution=0`

## Independent reproduction

The harmonizer reconstructed both accepted baseline QMDs from the sealed
forward patches into a fresh temporary tree and ran the complete paired source
verifier independently:

```text
Rscript --vanilla audit/analyses/brown_adherence/language_harmonization/01_verify_stage3_stage4_source_harmonization.R \
  /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
  /private/tmp/brown-language-independent.g0XPpv/brown \
  /private/tmp/brown-language-independent.g0XPpv/baseline
```

The independent replay exited zero and reproduced the complete owner result:
34/34 matrix actions, 22/22 checks, 189/189 historical members, 2/2 exact
reverse reconstructions, and a 19-member non-circular package. Every invariant
evidence file was byte-identical to the durable owner evidence. Only the
expected temporary absolute paths, execution timestamps and runtime, and their
direct manifest hashes differed.

The durable independent checker is:

`scripts/report_harmonization/check_report018_brown_stage3_stage4_source_acceptance.R`

It passed under R 4.6.1 with digest 0.6.39:

`BROWN_STAGE3_STAGE4_SOURCE_INDEPENDENT_ACCEPTANCE=PASS owner_manifest=19/19 checks=22/22 actions=34/34 historical=189/189 reverse=2/2 links=exact stage3=19_chunks/110_expr/38_inline/16_tables/5_figures stage4=18_chunks/59_expr/17_tables/1_mermaid R=4.6.1 quarto=0`

## Accepted contracts

- All 34 approved language and structural actions are implemented once.
- Stage 3 retains 19 R chunks, 110 parsed expressions, 38 byte-identical inline
  R expressions, 16 table endpoints, and five figure endpoints.
- Stage 4 retains 18 R chunks, 59 parsed expressions, 17 table endpoints, and
  one top-down Mermaid diagram.
- The Stage 3 `07_results.qmd` link remains exactly once.
- The complete pre-existing relative reader and source-data target multiset is
  preserved, except for the approved Stage 3 reciprocal companion link and the
  approved Stage 4 result-anchor suffixes.
- The within-participant and between-participant distinction is explicit.
- Confidence-interval exclusion and the corresponding FDR-threshold decisions
  remain separate statements.
- Both post-edit QMDs reverse exactly to the accepted pre-edit hashes and byte
  counts through the sealed patches.
- The accepted Stage 3 and Stage 4 HTML files, the 76-member and 113-member
  historical manifests, all 189 protected historical members, and `renv.lock`
  remain byte-identical.
- No QMD was executed. Quarto, Pandoc, a browser, and a loopback server were not
  started. No model, prediction, inference, resampling, or scientific artifact
  was produced or recalculated.

## Queue disposition

This acceptance closes only the paired source-language gate. It does not
accept either rendered page. A separate REPORT-018 order may release the Stage
3 result report as the sole serial render target after central concurrence.
Stage 4 must remain held until the Stage 3 render is independently accepted.
No new language or cosmetic cleanup loop is opened by this acceptance.
