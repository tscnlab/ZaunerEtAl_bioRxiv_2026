# Nature Health manuscript Phase 1 validation

Validation date: 2026-08-13

## Scope

This validation covers the revised Phase 1 package after the author's decisions on narrative architecture, title direction, Results order, Introduction and Discussion logic, Brown recommendation prominence, ocular terminology, measurement position, recruitment feasibility, and old-manuscript reuse.

No accepted reader report, analysis, model, estimate, interval, p value, diagnostic, sensitivity result, central ledger, shared configuration, or legacy Nature Medicine file was modified or executed. The validation did not use the Nature Health project profile, enter the REPORT-017 render queue, or create `manuscript/R0_NatHealth/`.

No scientific computation was performed. R was used only for structural parsing, link checks, record matching, protected-string checks, and arithmetic consistency within the literature-discovery scoring ledger.

## Render environment

- Quarto: 1.9.37
- Pandoc: 3.8.3
- Command: `quarto render narrative_blueprint.qmd --to html`
- Working directory: `audit/manuscript_nature_health/`
- Output: `audit/manuscript_nature_health/narrative_blueprint.html`
- Render mode: standalone, self-contained HTML with embedded resources
- Execution: explicitly disabled in the QMD

The render completed successfully. Automated browser inspection could not be repeated because the browser security policy blocks control of local `file:` URLs. No substitute browser route was used, and no new viewport or visual-layout claim is made in this validation. The rendered file remains available for direct author inspection.

## Reproducible structural check

- R version: 4.6.1
- Script: `tests/manuscript_nature_health/validate_phase1.R`
- Command: `Rscript --vanilla tests/manuscript_nature_health/validate_phase1.R .`
- Result: PASS

The check established all of the following:

- `claim_evidence_map.csv`: 54 data rows by 8 columns, with unique claim identifiers.
- `nature_medicine_reviewer_map.csv`: 14 data rows by 8 columns, with unique concern identifiers.
- `old_to_new_section_map.csv`: 43 data rows by 7 columns.
- Four Quarto table cross-reference targets resolve in the rendered HTML.
- Fourteen relative blueprint links resolve.
- The rendered HTML contains the expected title, 17 second-level headings, 27 third-level headings, and four tables.
- All required Phase 1 and discovery-package files exist and are non-empty.
- The accepted Brown percentages and denominators, three placement-specific sample anchors, and corrected recruitment-feasibility language occur in the blueprint.
- No task-owned authored Phase 1 source contains an em dash, the prohibited rhetorical term, or eligibility-based language for recruitment reluctance.
- `git diff --check` reports no whitespace error in the task-owned Phase 1, handoff, or validation paths.

## Evidence-discovery validation

The authorized evidence-discovery package contains all eight required outputs.

- Candidate ledger: 35 records.
- Canonical evidence matrix: 25 records.
- Verified bibliography: 25 unique records, matching the evidence-matrix citation keys exactly.
- Every canonical evidence record maps to a verified candidate-ledger record.
- Every proximity total equals the sum of its six component scores.
- One unresolved Zenodo metadata candidate remains explicitly unverified and is not used in the evidence matrix or bibliography.
- The current Brown publisher record carries the PLOS typographical-errata relation and no detected retraction or expression of concern.
- The placement analysis is pinned to bioRxiv version 2, posted 2026-08-11, while version 1 is retained as a prior version. The official metadata endpoint reported no journal publication, and the inspected v2 record carried no withdrawal notice.

The search is bounded and verification-first, not systematic. Its stated database, result-cap, access-level, and citation-chaining limitations remain part of the interpretation. It supports the title as a conceptual description and the wording “an unusually broad harmonized international study,” but it does not support an unqualified first, largest, or global priority claim.

## Protected interpretation checks

- Brown comparisons remain pooled fractions of valid measured minutes in recommendation contexts, not participant-level adherence, adequacy, risk, biological response, or measured health effect.
- Near-eye remains the primary ocular-exposure measurement.
- Chest remains separate complementary evidence and is not pooled with near-eye data or treated as an ocular surrogate.
- The paired sample relates positions under common observation.
- Separately, the chest option broadened recruitment possibilities where potential participants were reluctant to wear the light glasses, especially Costa Rica. This is an author-confirmed recruitment fact, not analytical eligibility and not an inference from the sample counts.
- The verified public placement preprint supports structured differences by analytical scale, metric class, context, site, day, and participant. It uses overlapping MeLiDos data and is related evidence, not independent replication.
- Sleep-period values remain measurements of the bedside sleep environment.
- Hourly evidence remains main and H06_daily remains complementary.
- Closed diagnostic, sensitivity, and non-estimable qualifications remain visible and are not described as unfinished science.
- Open REPORT-017 and DOC-001 work remains display integration, not scientific analysis.

## Artifact identities

| Artifact | SHA-256 |
|---|---|
| `narrative_blueprint.qmd` | `cfdf3ae15bf9ca0599f065f7d2f373179123da635b81181fdf1ef7874a802700` |
| `narrative_blueprint.html` | `ea9e619892e3629a1f35e1696c2e48fe29c84f25d648b9c33ddf9d050858347a` |
| `source_inventory.md` | `a14c48bec9f4fe84532e9e82f64e50928f285fdde60a98cb354ef61043ce30f1` |
| `nature_medicine_reviewer_map.csv` | `acdb0e0617ee83d0e478a738a90b331fc247f7cae8b1b52024342fb10ac02238` |
| `nature_health_targeting_memo.md` | `6d79d73ff7b79e1caa944865ac32a28689cacc9d6ccbae14283261ffa7bd012b` |
| `claim_evidence_map.csv` | `4b36fd1148f338758bbd696ce644623eca576684b3c49e2cc0d47b6872524e9a` |
| `old_to_new_section_map.csv` | `da52009ee90ffcedc7af518930e422f56421478c4962be984970a60dbe559240` |
| `unresolved_author_decisions.md` | `67ae910f385b45451eb7771157fadb64f46109b5fd42af39c05908b427298a5c` |
| `author_decision_2026-08-13.md` | `5e0fca28da5197810961bda78e188f25e8a532f4b631da84d48a64a91e8a7f86` |
| `first_largest_discovery/search_log.md` | `da91e849d20c1248246a0a708fd6df127f8ef7badbedb1bb3a39f86454fcbdfb` |
| `first_largest_discovery/candidate_ledger.csv` | `d468259eda9834127e7f26e13e882245a7879c6dc14191d5c916457bc2602c48` |
| `first_largest_discovery/evidence_matrix.csv` | `4474aa4a252e65f288160dbb6414d01f979844ab1210fabc3048b75360287b4f` |
| `first_largest_discovery/library.bib` | `976ebeff431f4c03e82cd4ee8fe6fef2fc872cee0f5e737f42b948a37c89bcb0` |
| `first_largest_discovery/frontier_map.md` | `56d785b070f6bda30ef003ab6f8ecda6440178115e020972315255c6bb3adc7f` |
| `first_largest_discovery/reading_queue.md` | `f19b312c42a25821d6fbba2f7684fa6449e4405d5cf5135bd73342d23f082d59` |
| `first_largest_discovery/positioning.md` | `a51a31107d7b68953049941bd0e9ed607ba46b4222bcbfb92e1a6855159a1161` |
| `first_largest_discovery/verification_report.md` | `38dc9554b97718b9f2b9324d3536e5bc6ff3a519355fe72609916f875a37a0e0` |
| `tests/manuscript_nature_health/validate_phase1.R` | `e7e7a36dde71e7571761094c5d9317f711d91f4faa6a6bbe7f190f74f024d3ff` |

## Gate status

The revised Phase 1 package is complete. The author has approved Architecture 1 with Architecture 3's direct prose style, Family A with A1 preferred and A3 as fallback, the Results order, the Introduction and Discussion logic, and the old-manuscript reuse strategy.

Phase 2 remains held for one narrow explicit confirmation:

1. the revised one-sentence thesis; and
2. the prominent main-Results use of the three Brown recommendation-context fractions with exact valid-minute denominators and the protected non-adherence, non-health-effect interpretation.

Display numbering and roles remain provisional regardless of that confirmation and stay gated by REPORT-017, DOC-001, coordinator release, and focused author visual approval.
