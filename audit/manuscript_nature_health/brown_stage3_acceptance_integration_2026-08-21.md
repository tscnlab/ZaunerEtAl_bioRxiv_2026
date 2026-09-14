# Brown adherence acceptance and manuscript integration

Date: 2026-08-21

Status: scientifically integrated, rendered and validated in the manuscript-owned Brown revision. The paired cross-state Stage 4 preparation and provenance companion is now accepted. It adds provenance support only and creates no new estimate or claim.

## Controlling acceptance

- Central decision: `audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md`
  - SHA-256: `985c865228d392b8721810d33c5fe89cfc73163393b52ce3074752fda2192ebe`
- Central verification: `audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition_verification.md`
  - SHA-256: `8e631ed89af58d3eb138bdb20efe0b6a1ef91c28a2b26aa60ba53ae04ac40294`
- Transition manifest, 23 rows: `audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition_manifest.csv`
  - SHA-256: `39ec3d05e009c40984117236c7941ce324675d07f7abb1b828990c8b34890adf`
- Accepted integrated reader source in `/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`:
  `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`
  - SHA-256: `80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997`
- Matching accepted HTML SHA-256: `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0`
- Accepted 76-member final manifest SHA-256: `69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21`

## Stage 4 provenance closure

The author closed the Stage 4 review with the exact wording `Approve Brown cross-state Stage 4 as written`. BA-016 / CHG-155 remains the controlling authority.

- Stage 4 closure decision SHA-256: `3bf604c4ad60a8ef3efb452626598306f5e473b341781e89a84218b6eb9a7583`
- Stage 4 closure verification SHA-256: `dd5b852d3f5e08ce41b5df41072bcf64a2de8d896501206bc79c9d32d8e47e01`
- Twenty-row closure seal SHA-256: `f32f09172406c5d6429ffe1b42bcd403dcf421d1353de749476415ab0289bf75`
- Accepted Stage 4 QMD SHA-256: `642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29`
- Accepted Stage 4 semantic HTML SHA-256: `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f`
- Accepted 113-member Stage 4 manifest SHA-256: `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2`
- Manuscript-owned provenance receipt: `audit/manuscript_nature_health/brown_cross_state_stage4_provenance_acceptance_2026-08-21.md`
  - SHA-256: `1fc9154301b8a9f6734fb0f2ba4b994acfdafe3e6875f48d62c895517d9e1e36`

The central R 4.6.1 checker reproduced all 113 Stage 4 manifest members and authorized the writer provenance follow-up. The current manuscript already contains the accepted hierarchy and qualifications. Consequently, no reader-facing source change or manuscript rerender was required, and the source, HTML and Word identities recorded below remain unchanged.

## Read-only numerical verification

Command:

```text
Rscript --vanilla scripts/manuscript_nature_health/verify_brown_acceptance_claims.R /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

- R: 4.6.1
- `digest`: 0.6.39
- Verifier SHA-256: `4fbbd10faa391c7507e760e9335cb2fef8321bba20a2abe20bfcbb7b0570c47f`
- Six of six controlling identities matched.
- Primary sample, adherence contrasts, interaction tests, response-scale partition, fixed-effect Shapley weights, cross-state associations, coverage gates, anonymous profile dimensions and the three site-versus-equal-site localisations all matched the sealed CSV sources.
- Result: `Brown manuscript claim verification: PASS`.

No model was fitted or refitted. The verifier reads accepted CSVs and checks manuscript-facing constants only.

## Scientific hierarchy preserved

1. The endpoint-inflated state-period adherence model remains the main Brown analysis.
2. The cross-state association is explicitly labelled as a separate exploratory extension.
3. No within-participant day-level claim is released because temporal dependence remains unresolved.
4. The two released cross-state estimates are between-participant observational associations. They are not causal, within-person, stable-trait or trade-off estimates.
5. The anonymous profile display remains optional and descriptive. If selected later, it contains 139 complete profiles and 417 participant-state points without identifiers, ranks or trait labels.
6. The 27 site-versus-equal-site comparisons remain separate from the site-specific tests against zero. The manuscript reports only the three FDR-retained localisations.
7. Sites remain components of one pooled model, not independent replications or causal effects of location.
8. Chest evidence remains separate and complementary for Wake and Pre-sleep. It supplies no sleep ocular claim.

## Manuscript changes

The revision adds or updates:

- the abstract with the three main Free-minus-Work adherence differences;
- Results paragraphs `P-R04` through `P-R04D` for pooled fractions, the main state-period model, site localisation, variance partition and the exploratory cross-state extension;
- `P-R18` for complementary chest adherence;
- Discussion paragraphs `P-D02` and `P-D02B` for health-relevant interpretation without individual risk or trade-off claims;
- Methods paragraphs `P-M12` through `P-M12B` for state definitions, endpoints, population averaging, multiplicity, coverage, cross-state decomposition and the withheld claim.

Figures and tables are not frozen in this revision. The accepted Brown results are available for later display selection, but principal and supplementary roles remain subject to the coordinated figure release and author visual review.

## Final manuscript-owned identities

- Preserved pre-Brown source: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3.qmd`
  - SHA-256: `acb6544209fe9c34f5a28b03eb72bf02283af47b6757f05a3a523c9538e6ed0c`
- Brown-integrated source: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`
  - SHA-256: `a6c1376c32783a943d2db19784fcd12e067727ba8a2fd9e9f67bcb5aa9df019f`
- Manuscript-local bibliography: `manuscript/R0_NatHealth/references_additional.bib`
  - SHA-256: `247d8c5112aef592db0466e156b668fa6aa42f418456e107a51cfdbed1965814`
- Manuscript render configuration: `manuscript/R0_NatHealth/_quarto.yml`
  - SHA-256: `a9e8e9b3e420657f409bdb3dcc33b5df444289392e0e7895000bd72666c3e2b5`
- Rendered HTML: `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`
  - SHA-256: `bd0793a5639b5f38e811d7faf7b33ff812d784c805d55cb9459c6f99884cce1b`
- Rendered Word document: `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
  - SHA-256: `d3ffb9abb583d91d4dffffea69fce870987b59494c76c462f9dfa53b1bf53a02`
- Brown paragraph claim map: `audit/manuscript_nature_health/phase3_brown_paragraph_claim_audit.csv`
  - SHA-256: `8b5dc5863d4481553ea53623a859092b7fb0903ddfb4ef4ee84fa73cddf6cfd4`
- Brown protected-number map: `audit/manuscript_nature_health/phase3_brown_protected_number_audit.csv`
  - SHA-256: `94a7dc367529fdaea392906946a3983855b4d01825102e87999760cf5f0f2c30`
- Brown manuscript validator: `tests/manuscript_nature_health/validate_phase3_brown.R`
  - SHA-256: `e016d49af09eb267211330775bf235c2d4382ef9a46cfa53d0913f1c94bf9019`

The manuscript-local bibliography now supplies the retained CIE standard under a dedicated key so that `CIE S 026/E:2018` and the official title retain their required capitalization in both output formats. The shared bibliography was not modified.

No Brown analysis file, shared report source, central decision, ledger, configuration outside the manuscript project, or report-render artifact was modified by this integration.
