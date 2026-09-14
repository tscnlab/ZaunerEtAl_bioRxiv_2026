# Brown-integrated Phase 3 validation

Date: 2026-08-21

Status: PASS for the manuscript-owned Brown-integrated author-review revision, including the accepted cross-state Stage 4 provenance companion.

## Scope

This validation covers only `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd` and its manuscript-owned audit, bibliography, configuration and rendered outputs. It did not execute manuscript code, fit or refit a model, alter an accepted analysis, enter the serial report-render queue, or freeze a figure or table role.

## Accepted Brown evidence verification

The read-only verifier ran under R 4.6.1 with `digest` 0.6.39 against the shared repository and the accepted Brown worktree.

```text
Rscript --vanilla scripts/manuscript_nature_health/verify_brown_acceptance_claims.R . /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

It matched all six controlling identities and the manuscript-facing sample sizes, adherence contrasts, interaction tests, response-scale partition, Shapley weights, between-participant estimates, coverage gate, anonymous-profile dimensions and three site-versus-equal-site FDR localisations. Result: `Brown manuscript claim verification: PASS`.

## Stage 4 provenance verification

The author-approved Stage 4 closure was checked with the existing central R 4.6.1 verifier:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_stage4_author_acceptance_and_harmonization_transition.R . /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

Result:

```text
BROWN_STAGE4_AUTHOR_ACCEPTANCE=PASS stage4_manifest=113/113 BA-016=unique CHG-155=unique writer=authorized harmonization=sealed_and_held
```

The accepted Stage 4 companion adds provenance only. It changes no sample, estimate, interval, p-value, multiplicity decision, diagnostic, sensitivity, limitation or claim. The manuscript source, HTML and Word hashes remained exact, so this provenance update did not require a rerender. The durable manuscript-owned receipt is `brown_cross_state_stage4_provenance_acceptance_2026-08-21.md`, SHA-256 `1fc9154301b8a9f6734fb0f2ba4b994acfdafe3e6875f48d62c895517d9e1e36`.

## Manuscript validation

The manuscript validator ran under R 4.6.1:

```text
Rscript --vanilla tests/manuscript_nature_health/validate_phase3_brown.R .
```

Result:

```text
Abstract: 146 words
Introduction: 403 words
Results: 2804 words in 6 sections
Discussion: 1113 words and no subheadings
Main text: 4320 words
Methods: 3025 words in 14 sections
Audited paragraphs: 76
Protected-number rows: 61
Resolved citation keys: 90
Old references retained: 83 of 98
Verified ethics-site records: 9
Health-evidence records: 9 canonical from 11 candidates
Brown-integrated Phase 3 manuscript validation: PASS
```

All citation keys resolved. The retained CIE standard renders with `CIE S 026/E:2018` and the official title capitalization through a manuscript-local bibliography entry. No em dash, internal hypothesis label, internal workflow label, `BH` abbreviation, or final figure or table cross-reference remains in the reader-facing manuscript.

## Render and visual inspection

- Quarto: 1.9.37
- Pandoc: 3.8.3
- Command: `quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd`
- Scope: manuscript-only render configured with execution disabled
- Outputs: self-contained HTML and Word
- HTML: structural validation passed. Automated in-app visual inspection of the local `file:` URL was blocked by browser policy, and no workaround was used.
- Word: rendered to 27 page images with the document workflow. All pages were visually inspected for clipping, overlap, missing glyphs, broken page transitions and reference rendering. No defect was found. After the final CIE citation correction, only page 19 changed, the other 26 rendered page images were byte-identical, and page 19 was re-inspected successfully.

Figures and tables remain deliberately unselected. Their principal and supplementary roles still await the coordinated output release and author visual review.

## Final artifact identities

| Artifact | SHA-256 |
|---|---|
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3.qmd` | `acb6544209fe9c34f5a28b03eb72bf02283af47b6757f05a3a523c9538e6ed0c` |
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd` | `a6c1376c32783a943d2db19784fcd12e067727ba8a2fd9e9f67bcb5aa9df019f` |
| `manuscript/R0_NatHealth/references_additional.bib` | `247d8c5112aef592db0466e156b668fa6aa42f418456e107a51cfdbed1965814` |
| `manuscript/R0_NatHealth/_quarto.yml` | `a9e8e9b3e420657f409bdb3dcc33b5df444289392e0e7895000bd72666c3e2b5` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html` | `bd0793a5639b5f38e811d7faf7b33ff812d784c805d55cb9459c6f99884cce1b` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx` | `d3ffb9abb583d91d4dffffea69fce870987b59494c76c462f9dfa53b1bf53a02` |
| `audit/manuscript_nature_health/phase3_brown_paragraph_claim_audit.csv` | `8b5dc5863d4481553ea53623a859092b7fb0903ddfb4ef4ee84fa73cddf6cfd4` |
| `audit/manuscript_nature_health/phase3_brown_protected_number_audit.csv` | `94a7dc367529fdaea392906946a3983855b4d01825102e87999760cf5f0f2c30` |
| `scripts/manuscript_nature_health/verify_brown_acceptance_claims.R` | `4fbbd10faa391c7507e760e9335cb2fef8321bba20a2abe20bfcbb7b0570c47f` |
| `tests/manuscript_nature_health/validate_phase3_brown.R` | `e016d49af09eb267211330775bf235c2d4382ef9a46cfa53d0913f1c94bf9019` |
| `audit/manuscript_nature_health/brown_cross_state_stage4_provenance_acceptance_2026-08-21.md` | `1fc9154301b8a9f6734fb0f2ba4b994acfdafe3e6875f48d62c895517d9e1e36` |

The accepted scientific authorities remain those recorded in `brown_stage3_acceptance_integration_2026-08-21.md`. No commit, push, upload or submission was performed.
