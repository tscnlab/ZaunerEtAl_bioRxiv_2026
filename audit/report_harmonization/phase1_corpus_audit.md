# Phase 1 reader-facing corpus audit

Date: 2026-08-12  
Status: complete, read-only audit; no report source, model, data, estimate, or central ledger changed

## Scope and method

The audit reviewed the Nature Health reader corpus in scientific dependency order: shared landing/context pages; descriptives; Preparation 01–07; H01–H11 results and their preparation/provenance companions; shared sensitivity and assembly pages; and internal workflow pages currently exposed in navigation. The unfinished complementary H06_daily analysis was inspected only for status and was deferred because no accepted reader-facing Stage 3/4 QMD exists.

All 38 current sources were read and indexed. The structural inventory used R 4.6.1 and base R to read text, links, file metadata, and hashes without sourcing or executing QMD code. It indexed 43,060 source lines, 7,293 nonblank reader-prose lines, 743 headings/callouts, 369 Markdown links, 6,177 terminology matches, and 1,795 raw figure/table declaration lines. The separate consolidated output catalog contains 271 cross-referenced candidates: 76 figures and 195 tables.

Evidence:

- `phase1_corpus_inventory.csv`: logical order, title, owner task, scientific status, source hash, profile/sidebar position, expected HTML, and render hash;
- `phase1_structure_inventory.csv`: headings and callouts;
- `phase1_link_inventory.csv`: link text, targets, and target types;
- `phase1_term_occurrences.csv`: line-level language flags, with code distinguished from prose;
- `phase1_numbered_prose_extract.txt`: review copy of every nonblank prose line;
- `phase2_main_supplement_output_catalog.csv`: consolidated figures and tables with source/render anchors, current style, role, and polish status;
- `phase1_audit_runtime.txt` and `phase2_output_catalog_runtime.txt`: commands and R session records.

## Corpus and navigation findings

- The current Nature Health profile lists 32 of the 38 audited QMDs. Accepted H03, H04, H07, H09, and H11 preparation/provenance companions are omitted even though targeted HTML renders exist.
- Expected HTML is present for 35 sources. The three missing expected renders are `supplementary_information.html`, `_deviations.html`, and `notebooks/assemble_artifacts.html`; the first and last sources are currently listed for rendering.
- Two internal production documents—the implementation-result comparison contract and H03–H11 gated workflow—are exposed in the reader sidebar. The assembly workflow is also exposed as reader content.
- The landing page still uses legacy RQ claims, names, and assets that have not been reconciled to all accepted hypothesis reports. Harmonization cannot adjudicate those claims, so the landing source is on a scoped scientific/content hold.
- `_deviations.qmd` is a partial legacy page without stable entry anchors and ends at H07. It cannot serve as the required deviation reference.
- The shared supplementary and sensitivity pages are outlines written partly in the future tense, not complete accepted reader reports.

## Link and cross-reference findings

- The corpus contains 26 hard-coded internal `.html` links across 18 sources but only five relative QMD links.
- Several result/companion pairs link only one way or not at all. H03, H04, and H06 have especially inconsistent reciprocal behavior.
- H06 has 17 cross-referenced figure/table chunks whose labels do not begin with `fig-` or `tbl-`; this weakens Quarto cross-reference behavior and should be repaired without changing output content.
- One existing dynamic link in the landing source points to an obsolete `RQ1.qmd` path.
- No consistent mechanism currently links a reader-facing deviation mention to one exact stable entry.

## Language and information-hierarchy findings

- Production terms such as stage, gate, worker, task, frozen, sealed, verifier, manifest, checksum, and internal audit IDs appear frequently in reader prose. They obscure current scientific meaning and should move to audit provenance or be replaced by a direct scientific qualification.
- Legacy/V0/submitted-implementation and repair-history narratives are prominent in descriptives, preparations, companions, and several results. Current reports should describe the accepted analysis and only the historical consequence that remains scientifically relevant.
- Recurrent specialist terms—heterogeneity, equal-site, GAM/GAMM, diagnostics, common sample, transformed scale, Shapley allocation, concurvity, derivative, pointwise interval, and symlog—are not explained consistently.
- The `Answer in brief` convention varies: most reports use a note callout, H02 and H11 use tip callouts, H08 says `Results in brief`, and H06 adds terminal punctuation. The proposed standard is `::: {.callout-note title="Answer in brief"}`.
- H06 and H10 use top-level section headings where the other result reports use second-level sections.
- Preparation pages generally retain scientifically valuable detail but give hashes, file mechanics, verifier identities, and construction history too much visual priority.

## Output findings

- The selected main figures are already polished. The proposal therefore limits changes to typography, panel/caption hierarchy, label explanations, source/alt text, site conventions, and full-width placement where needed.
- The H02 main near-eye figure has a reader-description mismatch: the source prose and alt text say panel B shows participant curves and panel C site curves, while the rendered figure shows sites in B and participant curves in C. This is a mandatory display-accuracy repair; it does not justify changing the stored curves or results.
- H07's main figure is exceptionally tall because nine nonlinear curves must be paired with their derivatives. It should remain full-width, with a short how-to-read explanation rather than a redesign.
- H10's main figure is dense because it joins age support, retained associations, and site-specific context. It should remain page-wide; panel C must be described as components of omnibus age-by-site interactions, not separate site tests.
- H11 has no scientifically valid same-sample placement figure. The accepted separate near-eye and chest curves are a justified structural exception.
- H05 needs the null result and four unfit sleep-environment cells made immediately visible; no suppressed estimate should be created.

## Scientific qualifications and holds exposed by editing

- `index.qmd`: stop until the coordinator reconciles legacy landing claims to accepted H01–H11 reports.
- Preparation 03: retain a plain statement that independent reconstruction of the current reference-profile input remains incomplete.
- Preparation 04 and H10: retain a plain statement that independent reconstruction of current diary-period support remains incomplete.
- H02: repair only the B/C display description mismatch; no scientific output changes.
- H05: preserve the conclusion that none of 68 primary associations retained adjusted support and four models are unfit for inference.
- H07: do not translate the derivative rule into a biological ceiling or an unconditional plateau claim.
- H11: preserve the global-test versus pointwise-context distinction and the absence of a valid paired-placement display.
- H06: harmonize the accepted hourly main result now; defer the complementary daily analysis until its reader sources are accepted.

## Deviation-ledger readiness

R 4.6.1 checks found 86 unique IDs in the deviation register and no duplicates. The crosswalk has 81 IDs and no crosswalk-only IDs. Five register IDs are missing from the crosswalk (`IMP-022`, `DEV-057`, `DEV-058`, `IMP-023`, `IMP-024`), and two statuses conflict (`DEV-051`, `IMP-013`). The central coordinator must reconcile mappings and statuses before the deviation QMD can be generated without editorial inference.

## Phase 1 conclusion

The accepted scientific reports are safe for a display-only harmonization pass subject to the document-specific holds and exceptions above. The corpus does not need wholesale figure redesign or scientific recomputation. It needs a shared reader vocabulary, predictable result/companion structures, dynamic QMD links, a complete anchored deviation reference, restrained provenance language, and targeted navigation repairs.
