# Brown cross-state Stage 4 provenance acceptance

Date: 2026-08-21

Status: accepted provenance follow-up recorded. This closure creates no new estimate, result, interpretation or reader-facing claim.

## Controlling closure

- Authority remains BA-016 / CHG-155.
- The author supplied the exact gate wording, `Approve Brown cross-state Stage 4 as written`.
- Controlling decision: `audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition.md`
  - SHA-256: `3bf604c4ad60a8ef3efb452626598306f5e473b341781e89a84218b6eb9a7583`
- Verification:
  `audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition_verification.md`
  - SHA-256: `dd5b852d3f5e08ce41b5df41072bcf64a2de8d896501206bc79c9d32d8e47e01`
- Twenty-row non-circular seal:
  `audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition_manifest.csv`
  - SHA-256: `f32f09172406c5d6429ffe1b42bcd403dcf421d1353de749476415ab0289bf75`

## Accepted paired endpoints

The following sources are in `/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`.

| Artifact | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | `80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0` |
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd` | `642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29` |
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html` | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv` | `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2` |

The accepted Stage 4 source is a preparation and provenance companion to the already accepted Stage 3 results. Its accepted semantic HTML changes only generated table attributes and does not change visible or scientific content.

## Read-only verification

The existing central checker was run under R 4.6.1:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_stage4_author_acceptance_and_harmonization_transition.R . /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

Reproduced output:

```text
BROWN_STAGE4_AUTHOR_ACCEPTANCE=PASS stage4_manifest=113/113 BA-016=unique CHG-155=unique writer=authorized harmonization=sealed_and_held
```

No model, prediction, scientific calculation, report render or project profile was run.

## Manuscript disposition

The Brown-integrated Nature Health manuscript already preserves the now accepted Stage 4 hierarchy and qualifications:

1. The endpoint-inflated recommendation-adherence analysis is main.
2. The cross-state association is a separate exploratory extension.
3. The within-participant day-level claim is withheld because temporal dependence remains unresolved.
4. The released cross-state estimates are limited, non-causal between-participant associations, not within-person effects, stable traits, trade-offs, rankings or independent replications.
5. Chest evidence is separate complementary context and supplies no sleep ocular claim.
6. The accepted samples, multiplicity families, diagnostic qualifications, coverage gate, privacy boundary and site interpretation remain unchanged.

Stage 4 therefore requires no reader-facing source edit and no manuscript rerender. The current manuscript identities remain:

| Artifact | SHA-256 |
|---|---|
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd` | `a6c1376c32783a943d2db19784fcd12e067727ba8a2fd9e9f67bcb5aa9df019f` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html` | `bd0793a5639b5f38e811d7faf7b33ff812d784c805d55cb9459c6f99884cce1b` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx` | `d3ffb9abb583d91d4dffffea69fce870987b59494c76c462f9dfa53b1bf53a02` |

The separately sealed Brown report-language harmonization pass remains held in its serial queue. It does not block this provenance closure and does not authorize a manuscript wording change.
