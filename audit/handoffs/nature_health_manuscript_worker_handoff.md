# Nature Health manuscript worker handoff

Date: 2026-09-01

Status: **Author-handover manuscript rendered and validated; main displays integrated; complete Supplementary Information appended; author rewrite is next**

Branch and checkout: `rewrite/NH`, shared checkout

Coordinating task: `019faf58-3df3-7383-8034-f715cdfdd154`

Report-harmonization task: `019ff52e-48ac-77b3-9a0e-9a87749a3bba`

## Current author-handover release

The complete manuscript has received a final meaning-preserving continuity pass and is ready for the lead author's write-over. Main Figures 1 to 3 and Tables 1 to 3 appear at their Results narrative positions. Supplementary Tables S1 to S13 and Supplementary Figures S1 to S16 appear together after Competing interests and render from the same source as a standalone Supplementary Information document. Author contributions use the official CRediT role names.

R 4.6.1 validation passed with a 149-word abstract, 4,124 Introduction/Results/Discussion words, 3,043 Methods words, 76 audited paragraphs, 61 protected-number rows, 90 resolved citation keys, and 83 of 98 original references retained. Quarto 1.9.37 rendered both HTML documents successfully. Desktop and 390-px browser inspection found no missing display, unresolved reference, or page-level horizontal overflow. A visible-text invariant check preserved all 5,241 main-manuscript and 3,347 Supplementary Information numerical tokens in their original order through the final editorial and display-language pass.

Current manuscript-owned identities:

| Artifact | SHA-256 |
|---|---|
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd` | `2c0f6bbfc69a434258c8d4bb1d9455a2f9e0920a9bbaa634adf5aaa9922323c3` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html` | `122e96caf0d635086983a2e875d650417cce21c3623ba6a5b655cc47010be012` |
| `manuscript/R0_NatHealth/supplementary_information_outline.qmd` | `49c91cf49b6f5c6308f5b3ea39cba750da3942e0d058b45c4f2ec7782b2f34bf` |
| `manuscript/R0_NatHealth/supplementary_information_standalone.qmd` | `84b88515af524e78f66ba947017afa195a000fa57663aa715d113fe1dab91f3b` |
| `manuscript/R0_NatHealth/_output/supplementary_information_standalone.html` | `a52450b9a9792f5ff2f879766e009a6c5194d64ae072549dbce029997ab19861` |
| `manuscript/R0_NatHealth/manuscript_displays.css` | `392ae8f69446ed18e8ebce4d1c5cf2a510264584497541f313249be4fb391677` |
| `manuscript/R0_NatHealth/_quarto.yml` | `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33` |
| `tests/manuscript_nature_health/validate_phase3_brown.R` | `b729d32c2bdc98d92e4db97a06b12c81adfd65b49dc071db84b54b26fb762c14` |
| `audit/manuscript_nature_health/phase3_brown_protected_number_audit.csv` | `4d0af0f66d355bab71b578ecee629ef6d4975ceba1095a691200f25645f08675` |

Reader-facing table terminology was converged with the Descriptives, H01, H05, H06_daily, H07, H08, H09, and H10 source owners without entering the serial report-render queue. The current H01 source-only identity after the final association-label pass is `92d7795d5f64e451d3633e5987f6365ebf7ccb6b1bc24b469d064847b0c97e0a`. Full source-owner identities and visual-QA details are recorded in `audit/manuscript_nature_health/figure_table_integration_qa_2026-08-31.md`.

## Current Brown-integrated release

BA-016 / CHG-155 is the controlling acceptance for the Brown adherence Stage 3 package. The endpoint-inflated state-period model remains the main Brown analysis. The manuscript now includes its pooled fractions, Free-minus-Work contrasts, site heterogeneity and three FDR-retained site-versus-equal-site localisations, response-scale partition, and the separately labelled exploratory between-participant cross-state associations. The within-participant day-level claim remains withheld because temporal dependence is unresolved. The manuscript does not describe the between-participant estimates as causal, within-person, stable-trait or trade-off effects, and it keeps chest evidence separate and complementary.

The paired cross-state Stage 4 preparation and provenance companion is now author-approved under the unchanged BA-016 / CHG-155 chain. The central R 4.6.1 checker reproduced all 113 final-manifest members and authorized this provenance-only writer follow-up. Stage 4 adds no estimate or claim. The manuscript already contained its accepted hierarchy and qualifications, so the QMD, HTML and Word identities remain unchanged and no rerender was performed. The separate Brown report-language pass remains held in its serial harmonization queue and does not block the manuscript.

The Brown-integrated source is `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`. It rendered successfully to self-contained HTML and Word under Quarto 1.9.37 and Pandoc 3.8.3 with execution disabled. R 4.6.1 validation passed with 146 abstract words, 4,320 main-text words, 76 audited paragraphs, 61 protected-number rows and 90 resolved citation keys. All 27 Word pages were visually inspected. The manuscript-local CIE record now preserves the official `CIE S 026/E:2018` title styling without changing the shared bibliography. The full validation and identities are in `audit/manuscript_nature_health/phase3_brown_validation.md`.

Current artifact identities:

| Artifact | SHA-256 |
|---|---|
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd` | `a6c1376c32783a943d2db19784fcd12e067727ba8a2fd9e9f67bcb5aa9df019f` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html` | `bd0793a5639b5f38e811d7faf7b33ff812d784c805d55cb9459c6f99884cce1b` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx` | `d3ffb9abb583d91d4dffffea69fce870987b59494c76c462f9dfa53b1bf53a02` |
| `audit/manuscript_nature_health/phase3_brown_paragraph_claim_audit.csv` | `8b5dc5863d4481553ea53623a859092b7fb0903ddfb4ef4ee84fa73cddf6cfd4` |
| `audit/manuscript_nature_health/phase3_brown_protected_number_audit.csv` | `94a7dc367529fdaea392906946a3983855b4d01825102e87999760cf5f0f2c30` |
| `audit/manuscript_nature_health/brown_stage3_acceptance_integration_2026-08-21.md` | `21fe7a07d50fd344ffb2ddbe9b71a71aad61bff71b7643b8747511ee72baa3e7` |
| `audit/manuscript_nature_health/brown_cross_state_stage4_provenance_acceptance_2026-08-21.md` | `1fc9154301b8a9f6734fb0f2ba4b994acfdafe3e6875f48d62c895517d9e1e36` |
| `audit/manuscript_nature_health/phase3_brown_clarity_changes.md` | `3907aa56d10710d53dbd3e7f8999f6aa88153a4a2065c25ac0652995370f67d1` |
| `audit/manuscript_nature_health/phase3_brown_validation.md` | `3793d7c9830319225f3ed5197cc44e6653192a39dd15608bf1d3e1685a4af66f` |

The pre-Brown Phase 3 source remains preserved unchanged. The older Phase 3 identities below are historical pins, not the current release.

## Phase 3 update

The complete author feedback received on 2026-08-14 has been integrated in a new sibling source. The Phase 2 source and render remain unchanged. The revision expands the health rationale and population literature, reports the full roster and position-specific samples, adds the accepted temporal-architecture allocation and effect-size results, organises exposure metrics as thematic streams, strengthens geographic, photoperiod, interaction and site-specific results, clarifies the main hourly and complementary participant-day analyses, corrects the activity-complete biological-sex interpretation, restores detailed Methods content and repairs the malformed Huss reference title through a task-local bibliography record.

The author selected **The multiscale architecture of personal light exposure**. Headline scope is now expressed as multisite, cross-site or the exact nine-site, seven-country design, avoiding a title that could imply international representativeness. The manuscript consistently qualifies the primary near-eye estimand as ocular exposure during wear and treats chest exposure as complementary non-ocular evidence. The chest option is described as broadening recruitment possibilities among people reluctant to wear the glasses-mounted sensor, especially at San José (CR), not as changing eligibility or enlarging the ocular sample.

The Free-versus-Work paragraph now separates the supported common-site additive ratio of 1.45 from the interaction-model equal-site average of 1.15, which was inconclusive. The owner-approved H03 update at commit `c88c2d7` adds an explicitly exploratory participant-intercept assessment and population-mean within/between sensitivity. The manuscript reports the 0.080 participant-intercept increment, hierarchy-respecting marginal-R² allocation, residual lag-one correlation and zero-mass mismatch without replacing the primary population-mean model, implying participant-specific source responses or claiming individual prediction. The sealed H04 update at commit `2c8c097` now adds the parallel exploratory activity decomposition at both positions. It reports the 0.092 participant-intercept increment and marginal-R² allocations while preserving the five-category frame, exact fractional weights, absence of activity random slopes, model-based rather than raw response-variance interpretation, and residual-correlation and zero-mass qualifications. The older main-text activity quasi-deviance allocation was removed to avoid presenting unlike allocation denominators as directly comparable. The nine site ethics approvals are filled from the supplied archive. Dortmund (DE) is explicitly covered by the TUM multicentre approval for the BAuA site. The author clarified that the protocol-development trial was the Tübingen cohort included in the present analysis, not a separate pilot sample. The manuscript now reports that Tübingen participant feedback informed procedural refinements before implementation at the remaining sites, cites the published protocol, and does not label this formal participant or community co-design. The reference crosswalk accounts for all 98 original references: 83 are retained, 15 have source-specific reasons for omission and 7 current sources are new.

The original submission's complete title-page and declaration material is now restored: 28 authors, 14 affiliations, available ORCIDs, corresponding-author metadata, acknowledgements, funding, contribution roles, Data and Code availability, and competing interests. Two duplicated initials in legacy contribution lists were removed mechanically. The legacy all-author approval sentence was not carried forward because figures and the lead-author rewrite remain pending. The AI-assistance statement and final analysis-archive version also remain provisional.

The pre-Brown integrated Phase 3 manuscript-only HTML render and R 4.6.1 validation passed. That historical snapshot had a 145-word abstract, 4,391 main-text words, 69 audited paragraphs and 54 protected-number rows. It is superseded for current author review by the Brown-integrated release documented above, while its source remains preserved.

The 2026-08-15 `BA-BS3-REVIEW` receipt remains a historical pending-stage record. It was superseded by central acceptance under BA-016 / CHG-155 on 2026-08-21. The accepted package was identity-checked and integrated as described above.

### Phase 3 artifact identities

The identities below describe the earlier pre-Brown Phase 3 snapshot. They are retained as historical validation pins only.

| Artifact | SHA-256 |
|---|---|
| `manuscript/R0_NatHealth/_quarto.yml` | `bdd2955ef533d634da31b4c77371517bc8bf817cf7b7618cef29ce815c4c2842` |
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3.qmd` | `bc24e444f1782724a3ed467f84f60bb1e5d308aa28d43573f96826a8341b103f` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3.html` | `4d55c9f546e0814e659562771a21b3360ef8b26b8edf2ae27cbbd8389315caea` |
| `manuscript/R0_NatHealth/references_additional.bib` | `0eea4950e6bd232684aa4bc2871e82cc5cab3aad268a66231fc5374165f96252` |
| `audit/manuscript_nature_health/phase3_paragraph_claim_audit.csv` | `a46158afb455ac4e738ce6328ffed9cd4198d3b9ee7a1914a8575c9598254bc7` |
| `audit/manuscript_nature_health/phase3_protected_number_audit.csv` | `130cca468d489b0b615b2b69f8bb77d9f0b6dbdcf379e2035a6526a77c1eef09` |
| `audit/manuscript_nature_health/phase3_author_feedback_2026-08-14.md` | `4df75a6cf0aa3422751b39da156c55dfe22bc83c71c03d3a87d8bb8291bffbd1` |
| `audit/manuscript_nature_health/phase3_clarity_changes.md` | `280c7657b91ae1e3320aa1e6a110d7f709a0aafb82c0afe91574972e1a6a20e6` |
| `audit/manuscript_nature_health/phase3_validation.md` | `80b308e9df06c18e9e73a38d25d53c3ea0355db31a230cb5fcc78f34c8ea7978` |
| `audit/manuscript_nature_health/end_matter_restore_2026-08-14.md` | `139fb05218f412d7a2b176edf3cc3070bf2f7b8d46a3537f6c04331e18a1915e` |
| `audit/manuscript_nature_health/h04_pending_integration_review_2026-08-14.md` | `66d2082cbce60e7ecd65ca2f2863dff5f83e5e994215f3f3fd6911a923b6f17f` |
| `audit/manuscript_nature_health/ethics_approval_matrix.csv` | `b9a56742d0a18225d40c917ddfcf609113af9b360baf6a219a34fb8a3fc9c235` |
| `audit/manuscript_nature_health/ethics_document_review_2026-08-14.md` | `7c5f10990c79da33cba35f563ca254f6a5b592d9cd88981c471d41f28ae3fcc0` |
| `audit/manuscript_nature_health/old_reference_disposition.csv` | `ec0b7d2d1da60045fb764a410a7cdf19cb099e5d1085890931314e659a696a68` |
| `audit/manuscript_nature_health/old_reference_disposition.md` | `c373a6f5c76b180d9c66e3e3c8ec5ae03ed042fef89f36e4fec01fbe79c4dcde` |
| `scripts/manuscript_nature_health/build_reference_crosswalk.R` | `d8695fbfde3abd9b0d765741a39562787b039ef5754102009c5395d70ff85164` |
| `audit/handoffs/nature_health_manuscript_shared_change_request.md` | `202330fbc562a8012be449d1d16a2921beb52d8f5b4c0416e9a0bfc4fc332f1a` |
| `tests/manuscript_nature_health/validate_phase3.R` | `f3bc56943d29faa0e38c5247d84a509b3d5d006a8ac22becaadc98229b404cc9` |

### Health-outcome evidence package

The active `discover-evidence` workflow produced a separate bounded health-outcome package with 11 candidate records and 9 verified canonical works. Seven are direct empirical studies and two are contextual sources. One preprint version and one correction record are linked but not treated as primary evidence. The package supports population-health relevance while preserving the observational, measurement-position and no-health-outcome boundaries.

| Artifact | SHA-256 |
|---|---|
| `health_outcomes_discovery/search_log.md` | `07d27e4a4476e630d3ed17bf50912943c96a6c67c080b9fb5d19cc66a08461cd` |
| `health_outcomes_discovery/candidate_ledger.csv` | `045bec94ede8ca6ed794cbdf278ae41ecf66546051bb3422e7947d597fa6b7ba` |
| `health_outcomes_discovery/evidence_matrix.csv` | `ffa41a1375072c8e985fe1471a0bb4d9cea79910ec966de86694a8cc1a4182a9` |
| `health_outcomes_discovery/library.bib` | `7f79c4d8486efe74610296ab12a96a2e5b601b7c65c5f9a05310696906949669` |
| `health_outcomes_discovery/frontier_map.md` | `160bffee15feff54a65525a281e8a575ceaa76ab887cb14755cd9be2f116bf68` |
| `health_outcomes_discovery/reading_queue.md` | `c76a68f0b06d1079e35f8256bafbe2dd2c1f87a84800094ea5731355b3c56caa` |
| `health_outcomes_discovery/positioning.md` | `965545815f8291d222113e4ca3270987935a9b70130cc8a6aa9b979fe13978c2` |
| `health_outcomes_discovery/verification_report.md` | `84c285a6512b250cb5c8d928a17a8d25e1bdf71655548d34a3d84ddbc74f88cd` |

## Completed scope

The Phase 1 evidence, journal-targeting, reviewer-design, claim-provenance, legacy-reuse, and narrative-architecture package is complete and revised after the author's decisions. The author subsequently approved the revised thesis and prominent Brown recommendation-context placement, completing the Phase 1 gate. The complete Phase 2 Introduction, Results, Discussion and Methods narrative is now drafted, rendered and structurally validated in the task-owned Nature Health manuscript directory. The previous Nature Medicine submission remains unchanged.

The task-local authorized skills were used as follows:

- `clarify-scientific-writing`: protected evidentiary meaning while translating the accepted corpus into a direct, cross-disciplinary narrative and recording the full-document invariant reconciliation.
- `quarto-authoring`: created the standalone blueprint and the new execution-disabled, traceable Quarto manuscript without using the shared Nature Health project profile or entering REPORT-017.
- `discover-evidence`: produced the required eight-part bounded evidence package, then verified the author-supplied public placement preprint and its version history.
- `analyze-gamms`: supported the read-only interpretation of temporal fitted-curve quantities and the sealed H03 and H04 mixed-model R² decompositions without refitting any model.

## Author-approved architecture

The author approved:

1. Architecture 1, nested scales of exposure, with the direct prose style of Architecture 3.
2. Family A was subsequently narrowed to the author-selected title **The multiscale architecture of personal light exposure**.
3. The Results order from multisite baseline through nested variation, context, person-level evidence, and measurement boundary.
4. The proposed Introduction and Discussion logic.
5. Substantive reuse of accurate and effective Nature Medicine prose, with Results and the scientific argument rebuilt.
6. Prominent integration of the Brown recommendation contexts as a health-relevant exposure benchmark.
7. Ocular light exposure as the measured construct, using the shorter term only where the ocular meaning is unambiguous.

The bounded literature search supports the scientific distinctiveness of the combined design but not an unqualified first, largest, international-representativeness or global priority claim.

## Phase 2 narrative draft

The complete draft now includes:

- a 135-word provisional unreferenced abstract;
- an unheaded 406-word Introduction;
- 1,678 words of Results in the six approved topical sections;
- a 920-word Discussion without subheadings;
- 2,134 words of Methods in 14 topical sections;
- the exact Brown recommendation-context denominators and fractions;
- main hourly and complementary daily routine evidence kept distinct;
- integrated geographic, immediate-context, person-level, placement, null, non-estimable and diagnostic evidence;
- the verified public wearing-position preprint as overlapping related work;
- 55 paragraph-level source mappings; and
- 38 protected-number audit rows.

The Introduction, Results and Discussion total 3,004 words, below the stated 4,000-word Article limit. The draft deliberately leaves the title, abstract, author list, main and supplementary display calls, ethics and engagement completion, availability statements and other end matter provisional.

## Principal Phase 2 artifacts and identities

| Artifact | SHA-256 |
|---|---|
| `manuscript/R0_NatHealth/_quarto.yml` | `c8f9675d5c21b99ea0e37d6ef698961cb922eb1eb3696b8e07f59ef0d00ee960` |
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth.qmd` | `c27101300061d7e75d9fa5aecd98cb4d0630db01de6e45b842d216af5eed3138` |
| `manuscript/R0_NatHealth/references_additional.bib` | `21f72db088d3463e2b3035bad05d28dc20bf61faf048531e3987c1e97845a554` |
| `manuscript/R0_NatHealth/supplementary_information_outline.qmd` | `14626f8093aac6531285404e7ab376905bd7b268057f5f0b7273a1378274c443` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth.html` | `f7dfc612295aacdc60e8805ae446b0390eb46d560a8407d097a6f0ae636e7791` |
| `audit/manuscript_nature_health/phase2_paragraph_claim_audit.csv` | `bf89e28adcdc2aef5a3bf8619c2dd0f35633aae849c23fae9a11654d4c774773` |
| `audit/manuscript_nature_health/phase2_protected_number_audit.csv` | `ed55dd60d5f574ba8e9e907f0c08d6ffd88e610bcf1f10b3a9c9142b9fefdbe9` |
| `audit/manuscript_nature_health/phase2_clarity_changes.md` | `50a5631d25a194f64ca329e148878c08a058e8d35b8b64b427357b77a2c9a610` |
| `audit/manuscript_nature_health/phase2_validation.md` | `122d63ae3cfdef5ede0cd9d8f342e507d9e43fae3e047b9665e22da686b66808` |
| `tests/manuscript_nature_health/validate_phase2.R` | `510340360a9c5eb6f77323969737621d186027935960a4658b984df1a80e38fa` |

## Approved revised thesis

Across nine sites in seven countries, harmonized near-eye measurements reveal a shared daily architecture of ocular light exposure, with differences among people and days within sites exceeding differences among sites; only 24.0% of valid waking minutes reached the recommended daytime range, whereas 63.3% of pre-sleep and 87.7% of sleep-environment minutes fell within their respective upper limits.

The Brown values remain pooled fractions of valid measured minutes in contextual ranges. They are not participant-level adherence, adequacy, health-risk, biological-response, or health-effect estimates.

## Placement and recruitment interpretation

The fixed interpretation is:

- near-eye is primary for ocular exposure;
- chest is separate complementary evidence;
- paired or common-sample analyses relate positions while preserving separate estimands;
- positions cannot be pooled or converted through a universal correction;
- sleep-period measurements describe the bedside sleep environment; and
- the chest option broadened recruitment possibilities where potential participants were reluctant to wear the light glasses, especially Costa Rica. This concerns willingness and recruitment feasibility, not analytical eligibility.

The author supplied the public bioRxiv version 2 preprint **Sensor placement causes outcome-dependent bias in ambulatory light-exposure estimates**, DOI `10.64898/2026.07.28.741277`. Verification established:

- version 2 title and posting date: 2026-08-11;
- version 1 posting date: 2026-08-01 under an earlier title;
- no journal publication reported by the official bioRxiv metadata endpoint at the check date;
- full public v2 PDF SHA-256: `dd8f47c141c1b36e11b5c83a9665e5101d61054038e4f8f7b673a76a34cbab0a`; and
- the defensible qualitative claim that position differences vary by analytical scale, metric class, context, site, day, and participant, so a universal correction is not supported.

This preprint should be a numbered related-work citation in the Nature Health manuscript. It uses overlapping MeLiDos data and is not independent replication. The overlap and parallel work must be disclosed in the manuscript's related-work statement and the eventual cover letter. The accepted Nature Health analyses remain the authority for this manuscript's numerical claims.

## Completed author gate

The author explicitly approved both:

1. the revised one-sentence thesis above; and
2. prominent main-Results use of the three Brown recommendation-context fractions with exact valid-minute denominators and the protected interpretation.

Architecture, title family, Results order, Introduction and Discussion logic, and old-manuscript reuse were already approved. This confirmation authorized Phase 2 drafting but did not freeze the final title, abstract, display numbering, or output roles.

## Principal Phase 1 artifacts and identities

| Artifact | SHA-256 |
|---|---|
| `audit/manuscript_nature_health/narrative_blueprint.qmd` | `cfdf3ae15bf9ca0599f065f7d2f373179123da635b81181fdf1ef7874a802700` |
| `audit/manuscript_nature_health/narrative_blueprint.html` | `ea9e619892e3629a1f35e1696c2e48fe29c84f25d648b9c33ddf9d050858347a` |
| `audit/manuscript_nature_health/source_inventory.md` | `e38a59239471d59584f93bef56f98ff544f95256c30c430f95a571fb1c02fcb1` |
| `audit/manuscript_nature_health/nature_medicine_reviewer_map.csv` | `acdb0e0617ee83d0e478a738a90b331fc247f7cae8b1b52024342fb10ac02238` |
| `audit/manuscript_nature_health/nature_health_targeting_memo.md` | `5fafbe9b6816dd9c409316580ae00670d1c27e1f41933c8d65398133934a688e` |
| `audit/manuscript_nature_health/claim_evidence_map.csv` | `4b36fd1148f338758bbd696ce644623eca576684b3c49e2cc0d47b6872524e9a` |
| `audit/manuscript_nature_health/old_to_new_section_map.csv` | `da52009ee90ffcedc7af518930e422f56421478c4962be984970a60dbe559240` |
| `audit/manuscript_nature_health/unresolved_author_decisions.md` | `dfeaaadf60a2407a8c7c0eed6a4cdf38dcf3dd100a54f4510d53799ffafe2533` |
| `audit/manuscript_nature_health/author_decision_2026-08-13.md` | `a96c8fe11cafcdd7ae54be0eb44ebd3411f6ba561f216fb3146b60d52777cf4d` |
| `audit/manuscript_nature_health/phase1_validation.md` | `b38297f3e06cb3810ca815d6704a469528449b9e52390dfc582d4b44b28eabd7` |
| `tests/manuscript_nature_health/validate_phase1.R` | `e7e7a36dde71e7571761094c5d9317f711d91f4faa6a6bbe7f190f74f024d3ff` |

## Evidence-discovery package identities

| Artifact | SHA-256 |
|---|---|
| `search_log.md` | `da91e849d20c1248246a0a708fd6df127f8ef7badbedb1bb3a39f86454fcbdfb` |
| `candidate_ledger.csv` | `d468259eda9834127e7f26e13e882245a7879c6dc14191d5c916457bc2602c48` |
| `evidence_matrix.csv` | `4474aa4a252e65f288160dbb6414d01f979844ab1210fabc3048b75360287b4f` |
| `library.bib` | `976ebeff431f4c03e82cd4ee8fe6fef2fc872cee0f5e737f42b948a37c89bcb0` |
| `frontier_map.md` | `56d785b070f6bda30ef003ab6f8ecda6440178115e020972315255c6bb3adc7f` |
| `reading_queue.md` | `f19b312c42a25821d6fbba2f7684fa6449e4405d5cf5135bd73342d23f082d59` |
| `positioning.md` | `a51a31107d7b68953049941bd0e9ed607ba46b4222bcbfb92e1a6855159a1161` |
| `verification_report.md` | `38dc9554b97718b9f2b9324d3536e5bc6ff3a519355fe72609916f875a37a0e0` |

The validated package contains 35 candidate records, 25 canonical evidence records, and 25 matching bibliography entries. One target-linked Zenodo candidate remains explicitly unverified and is not used as evidence.

## Scientific and display status

- All accepted H01 to H11 analyses are scientifically closed. Hourly H06 is main and H06_daily is complementary.
- AUDIT-004 and CHG-137 control scientific closure.
- REPORT-017 and DOC-001 remain open display-integration work, not unfinished science.
- All current principal and supplemental output roles remain provisional pending serial renders and author visual review.
- The REPORT-017 queue was not interrupted, entered, or modified.

## Phase 1 validation

- Quarto 1.9.37 and Pandoc 3.8.3 produced the self-contained blueprint in an execution-disabled standalone render.
- R 4.6.1 structural validation passed.
- The validated corpus contains 54 claim records, 14 reviewer concerns, and 43 legacy-to-new section decisions.
- Fourteen relative links and four Quarto table cross-reference targets resolve.
- The rendered HTML contains the expected title, 17 second-level headings, 27 third-level headings, and four tables.
- All required files are non-empty, and bibliography keys match evidence-matrix keys exactly.
- No scientific computation was performed.

Phase 2 manuscript validation also passed under R 4.6.1 after a manuscript-only render with Quarto 1.9.37. All 28 citation keys resolved, the placement-preprint DOI and five-author record rendered correctly, the HTML contains the expected Article structure, and no citation-warning marker was found.

Automated browser inspection of the local blueprint and manuscript HTML was blocked by the browser's `file:` URL policy. No workaround was used. Both HTML files are available for direct author inspection, and no automated visual-layout claim was recorded.

## Shared-change status

The coordinator confirmed through a read-only R 4.6.1 audit that biological sex and gender were separate collected variables, while only biological sex entered the accepted models. The Phase 3 manuscript wording is evidence-supported and remains unchanged. The conflicting H10 reader statement is a source-only wording defect that the coordinator will route through its serial REPORT-017 turn; it is not an open manuscript or scientific issue.

## Active next action

Return the integrated manuscript to the lead author for the requested write-over. When the rewritten source is handed back, perform the final scientific, numerical, structural, citation, display, and editorial overview. Do not treat the current author-review subtitle, AI-assistance wording, archive version, or journal-production formatting as final submission text before that review.

## Current author-handover snapshot, 2026-09-01

This section supersedes earlier manuscript identity pins for the current author-review handover.

The final pre-handover editorial pass is complete. The abstract is 149 words; Introduction, Results, and Discussion total 4,157 words; and Methods contains 3,046 words. The active `clarify-scientific-writing` workflow improved flow and terminology without changing the scientific argument. The active `quarto-authoring` workflow preserved citations, cross-references, included display sources, and bounded rendering.

The author's table-layout feedback is resolved:

- every native `gt` table in the integrated manuscript and standalone Supplementary Information has a 12 px body-text base;
- all main and supplementary table wrappers use a wider 894.5 px page-column region at the inspected desktop viewport and contain their own horizontal scrolling;
- neither rendered document has page-level horizontal overflow;
- Table 3 preserves the approved 1,160 px width, seven fixed column widths, and 145 by 82 px density thumbnails; and
- the manuscript-owned and harmonizer-owned Table 3 sources are byte-identical at SHA-256 `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0`.

The responsible Descriptives, H01 to H11, H06 daily, and Brown Stage 3 and Stage 4 owners received executable source-only correction requests and returned 12 px table-source convergence. None of those tasks rendered a report or changed a scientific value, label, sample, statistic, hierarchy, claim, figure, or accepted analysis output. The exact current source identities are recorded in `audit/manuscript_nature_health/phase3_brown_editorial_pass_2026-09-01.md`. Their later report renders remain serialised through the coordinator and harmonizer.

R 4.6.1 validation passed with 76 audited paragraphs, 61 protected-number rows, 90 resolved citation keys, nine ethics-site records, nine canonical health-evidence records, and 83 of 98 original Nature Medicine references retained. A separate R 4.6.1 comparison found the full numerical token sequences identical before and after editing: 628 tokens in the main QMD and 60 in the Supplementary Information QMD. Browser inspection found all 20 integrated-manuscript and 17 standalone-supplement native tables at 12 px, no missing images, no unresolved cross-reference marker, and no page-level horizontal overflow.

Current manuscript-owned identities:

| Artifact | SHA-256 |
|---|---|
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd` | `b3bd9f22d7d31c850011599457fcf6130a9f30772829469248021ff2e0e6bbb7` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html` | `a122c5a9afba023bb23bf62666f51bdef918a12fbeb7c4f7e433ff3fdfdede22` |
| `manuscript/R0_NatHealth/supplementary_information_outline.qmd` | `a3f2da00710a965fa06ccac2bd9bde2e0f6605ad948b3fc208dcf5aab7698af2` |
| `manuscript/R0_NatHealth/supplementary_information_standalone.qmd` | `84b88515af524e78f66ba947017afa195a000fa57663aa715d113fe1dab91f3b` |
| `manuscript/R0_NatHealth/_output/supplementary_information_standalone.html` | `20d8361c20e8167c24c973c9806b448660ed0f33ed3b7f89676bcc508095993f` |
| `manuscript/R0_NatHealth/manuscript_displays.css` | `e990b471a30a52ba83d86ad0867edc3dd89bae0b5e0c9b7d8f91d376ba6096ea` |
| `manuscript/R0_NatHealth/display_assets/table3_metric_context.html` | `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0` |
| `tests/manuscript_nature_health/validate_phase3_brown.R` | `b10ea3f1014062544f5afb095a8a99d72fcb84f3c3479ce8b6720120ca049c47` |
| `audit/manuscript_nature_health/phase3_brown_editorial_pass_2026-09-01.md` | `330baecb5a2f906724e77683967e871ca682ea8cc88c364bc0b8c6e9847a0d60` |

The author can now perform the planned write-over on the current QMD. The next writer action remains a final scientific and editorial overview after that revised source is returned.

## Independent revision candidate and scientific/display holds, 2026-09-11

This update supersedes the earlier active-next-action wording for the current request. The writer has finished the independent Abstract/Introduction heading changes, new-page Word section formatting, additional Türkiye and Ghana site-data-note citations, and 19 separate native editable Word table exports. The title and abstract wording remain unchanged pending author approval of the proposals in `audit/manuscript_nature_health/revision_2026_09_11/editorial_proposals.md`.

The revised QMD is SHA-256 `bda9f4ad9c974c6e23cc358d687cc05848df06b5c614f6f564c07c46dee71d09`; the bibliography is `fa7454dedb2f84e5bf49fb9c590d1eadbaef2756dae05aa4bc2c2beceecc00a0`. The isolated HTML candidate is under `audit/manuscript_nature_health/revision_2026_09_11/manuscript_render/`, SHA-256 `6a9b6b5707b8848cd4b3134528ede4b6ce0817c345352d5b52ed431f0cda6b0f`. The separate Word review candidate is `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_revision_2026_09_11.docx`, SHA-256 `acb6548997c29e96a065dfd5a26a682a3f0fb08170185e0c57aab3b1b0b256c0`.

The editable tables are in `manuscript/R0_NatHealth/editable_tables/`, including one native table per DOCX and a ZIP archive. All 28 table pages and all 109 manuscript pages were visually reviewed. The structural validator passed 150 of 150 checks, with no removed manuscript citation keys, unchanged scientific text except the added site-data-note citation sentence, retained declarations, exact source table strings and intact internal links. Source display media in the review candidate remain identical to the accepted production Word file. No scientific computation was performed.

Two coordinated dependencies prevent final release:

1. The author-directed Brown grouping amendment must use preceding sleep, the ensuing complete daytime interval and the following pre-sleep window, with all three assigned the work/free label of the wake-start date. The Brown owner is preparing the bounded replacement analysis and reporting. The current main Brown results have not been relabelled or replaced by the writer.
2. The later author instruction requires actual SVG OOXML image parts, not manually rasterized figure replacements. The coordinator has reconciled the current 20-figure inventory and seven missing SVG equivalents, and is routing export-only owner work. The older supplementary numbering is obsolete. H06_daily remains excluded. No figure source was changed during this independent revision.

The coordinator explicitly withheld production resynchronisation. `_build/nathealth/index.html` and its accepted Word download remain unchanged. The candidate is not a final scientific or SVG-integrated package. Full commands, identities, QA scope, bibliography verification, and the pre-existing local/production Word identity distinction are in `audit/manuscript_nature_health/revision_2026_09_11/artifact.md`.
