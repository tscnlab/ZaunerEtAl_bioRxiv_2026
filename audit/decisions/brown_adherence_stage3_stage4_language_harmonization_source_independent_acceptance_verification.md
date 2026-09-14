# Brown Stage 3 and Stage 4 source-language acceptance verification

Date: 2026-08-21

Status: **PASS**

## Command and environment

The independent checker was Air-formatted, parsed, and run with R 4.6.1 and
digest 0.6.39:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_stage3_stage4_source_independent_acceptance.R "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026" "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
```

The checker is read-only except for an automatically removed temporary
directory used to reverse the two stored source patches. It does not load the
project profile, execute a QMD, invoke Quarto or Pandoc, start a browser, or
calculate a scientific result.

## Reproduced output

```text
BROWN_STAGE3_STAGE4_SOURCE_INDEPENDENT_ACCEPTANCE=PASS central=12/12 owner_manifest=19/19 checks=22/22 actions=34/34 historical=189/189 reverse=2/2 stage3=19_chunks/110_expr/38_inline/16_tables/5_figures stage4=18_chunks/59_expr/17_tables/1_mermaid R=4.6.1 digest=0.6.39 quarto=0 qmd_execution=0
```

The two stored forward patches independently reversed the accepted post-edit
sources to these exact historical baselines:

- Stage 3: 52,506 bytes, SHA-256
  `80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997`;
  and
- Stage 4: 24,147 bytes, SHA-256
  `642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29`.

Independent source-diff whitespace checks returned no finding. Air 0.4.1
accepted the owner verifier. The acceptance checker itself also passes Air
0.4.1 and R parsing.
