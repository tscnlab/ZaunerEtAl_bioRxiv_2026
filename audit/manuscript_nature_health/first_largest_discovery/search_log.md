# Search log: near-eye, international-scope, and harmonized-protocol positioning

## Frozen search brief

- **Discovery mode:** live discovery, supplemented by candidate generation from the repository bibliography and the previous Nature Medicine submission.
- **Search date and time zone:** 2026-08-13, Europe/Berlin.
- **Research question:** Within a bounded current literature search, is the MeLiDos study defensibly described as first, largest, or otherwise distinctive for harmonized, international, free-living measurement of personal ocular light exposure near the eye?
- **Intended decisions:** decide whether the working title *The international architecture of personal light exposure* is defensible; determine whether any first or largest claim may enter the manuscript; and identify literature supporting the methodological significance and participant burden of near-eye measurement.
- **Population and context:** humans measured during ordinary free-living activities. All ages and health states are eligible for candidate generation, but healthy or community samples are the closest comparators.
- **Construct:** personal ocular light exposure, including melanopic or photopic exposure when measured at or close to the corneal plane. Broader personal-light studies using wrist, chest, pendant, or fixed sensors are eligible only as contextual comparators.
- **Measurement chain and placement:** direct candidates include spectacle-, eyewear-, head-, or near-eye-mounted light loggers and dosimeters intended to approximate incident ocular light. Contextual candidates include other body placements, ambient or satellite estimates, and validation or reporting methods.
- **Comparison:** number and geographic spread of sites or countries; participant and observation counts; common protocol and device chain; sensor placement; temporal coverage; contextual data; and whether the work jointly analyses multiple sites.
- **Outcomes and metrics:** daily exposure profiles, physiologically weighted quantities, duration, timing, dose, regularity, recommendation-range summaries, placement comparison, wearability, compliance, acceptance, and data-quality implications.
- **Eligible designs:** original empirical field studies, protocols for an eligible cohort, measurement or validation studies, relevant reviews, reporting or methodological guidance, and consensus recommendations. Preprints are retained as related versions, with published versions preferred as canonical.
- **Publication and language bounds:** English-language records available through 2026-08-13. No lower date bound. Journal articles, conference papers, protocols, reviews, datasets, preprints, corrections, expressions of concern, and retractions are in scope.
- **Exclusions:** laboratory-only acute light-response studies; animal work; fixed-environment, remote-sensing, or simulation-only studies without personal measurement; device papers without a human free-living use or direct methodological relevance; and studies measuring non-light constructs only.
- **Novelty rule:** absence from this bounded search cannot establish priority. Any priority wording requires a verified, directly comparable literature set and must remain narrower than the searched construct and placement.
- **Requested artifacts and new output directory:** `search_log.md`, `candidate_ledger.csv`, `evidence_matrix.csv`, `library.bib`, `frontier_map.md`, `reading_queue.md`, `positioning.md`, and `verification_report.md` under `audit/manuscript_nature_health/first_largest_discovery/`.

## Post-freeze author-supplied source

After the initial package was completed, the author supplied the public bioRxiv v2 preprint **Sensor placement causes outcome-dependent bias in ambulatory light-exposure estimates**, DOI `10.64898/2026.07.28.741277`, and directed that it should be cited for structured wearing-position differences. The source was added without changing the frozen priority-search question. Its role is related placement evidence from an overlapping MeLiDos cohort, not an independent comparator for the target study's novelty.

## Planned query families frozen before live retrieval

1. `("personal light exposure" OR "ocular light exposure") AND (near-eye OR "near eye" OR corneal OR "eye level" OR spectacle* OR glasses OR eyewear OR head-worn)`
2. `("wearable light" OR "light logger" OR light dosimeter OR daysimeter) AND (corneal OR near-eye OR glasses OR spectacle* OR eyewear)`
3. `"corneal light" AND (field OR free-living OR wearable OR personal)`
4. `"personal light exposure" AND (international OR multicountry OR "multi-country" OR multisite OR "multi-site" OR multicentre OR multicenter)`
5. `("personal light exposure" OR "ocular light exposure") AND (review OR framework OR protocol OR measurement)`
6. `("near-eye" OR corneal OR eyewear) AND (wearability OR acceptance OR burden OR occlusion) AND light`
7. `"Recommendations for daytime, evening, and nighttime indoor light exposure"`
8. Backward and forward citation chaining from verified high-proximity records, labelled best-effort supplementary discovery.

## Retrieval log

Rows are added contemporaneously as searches are run. Result counts are reported only when the service exposes a stable count.

| Search ID | Discovery mode | Service or file | Date | Exact query or import action | Filters and bounds | Results reviewed | Candidates imported | Follow-up and limitations |
|---|---|---|---|---|---|---:|---:|---|
| LOCAL-01 | supplied-source candidate generation | `bibliography.bib` | 2026-08-13 | Keyword scan for `personal light exposure`, `ocular light`, `near-eye`, `corneal`, `wearable light`, `light dosimeter`, `spectacle`, `glasses`, and `recommend` | Repository bibliography as found; candidate-only | not applicable | pending | Existing entries are not treated as verified metadata. |
| EPMC-Q01 | live discovery | Europe PMC | 2026-08-13 | `("personal light exposure" OR "ocular light exposure") AND (near-eye OR "near eye" OR corneal OR "eye level" OR spectacle* OR glasses OR eyewear OR head-worn)` | English-language human and methods candidates through search date; no lower date bound | 60 | 8 | Title and abstract screening. Candidate metadata required independent verification. |
| EPMC-Q02 | live discovery | Europe PMC | 2026-08-13 | `("wearable light" OR "light logger" OR light dosimeter OR daysimeter) AND (corneal OR near-eye OR glasses OR spectacle* OR eyewear)` | Same date and language bounds | first 100 of 195 | 8 | Retrieval was capped at the first 100 service-ranked records. |
| EPMC-Q03 | live discovery | Europe PMC | 2026-08-13 | `"corneal light" AND (field OR free-living OR wearable OR personal)` | Same date and language bounds | first 100 of 348 | 4 | Many ophthalmic records used corneal in a non-placement sense. |
| EPMC-Q04 | live discovery | Europe PMC | 2026-08-13 | `"personal light exposure" AND (international OR multicountry OR "multi-country" OR multisite OR "multi-site" OR multicentre OR multicenter)` | Same date and language bounds | 48 | 6 | All returned titles were screened. |
| EPMC-Q05 | live discovery | Europe PMC | 2026-08-13 | `("personal light exposure" OR "ocular light exposure") AND (review OR framework OR protocol OR measurement)` | Same date and language bounds | first 100 of 182 | 7 | Used mainly to identify reviews, protocols, and reporting frameworks. |
| EPMC-Q06A | live discovery | Europe PMC | 2026-08-13 | `("near-eye" OR corneal OR eyewear) AND (wearability OR acceptance OR burden OR occlusion) AND light` | Same date and language bounds | first 100 of 48,447 | 0 | Query was too nonspecific because corneal and eyewear terms retrieve broad clinical literatures. It was replaced by EPMC-Q06B. |
| EPMC-Q06B | live discovery | Europe PMC | 2026-08-13 | `("wearable light logger" OR "light dosimeter") AND (wearability OR acceptance OR usability OR compliance)` | Same date and language bounds | 33 | 5 | All returned titles were screened. |
| EPMC-Q07 | live discovery | Europe PMC | 2026-08-13 | `"Recommendations for daytime, evening, and nighttime indoor light exposure"` | Same date and language bounds | 6 | 2 | Located the canonical consensus article and related version records. |
| WEB-Q01 | live discovery | web search, publisher and PubMed domains | 2026-08-13 | The seven frozen query families, plus exact-title searches for high-proximity candidates | No stable result count exposed; English-language records through search date | not available | 8 | Used as supplementary discovery and for publisher full-text access, not as identity verification by itself. |
| CHAIN-01 | best-effort supplementary discovery | backward and forward citation links from verified high-proximity records | 2026-08-13 | Citation chaining from Okudaira 1983, Hubalek 2010, Read 2018, Balajadia 2023, Stefani 2024, the 2024 protocol, and the 2025 wearable-logger review | Bounded to links visible in inspected publisher, PubMed, PubMed Central, and repository records | not available | 8 | Not a complete cited-by search. Paywalled reference lists and databases without current access were not exhaustively covered. |
| VERIFY-01 | live verification | Europe PMC REST API | 2026-08-13 | Batched exact-DOI query for 25 selected candidate identifiers with `resultType=core` | Exact DOI matching; page size 100 | 24 records plus duplicate version records | 24 | Confirmed identity, PubMed and PubMed Central links, publication dates, preprint relations where exposed, and retraction or correction fields. One non-indexed DOI was verified through Crossref. |
| VERIFY-02 | live verification | Crossref REST API | 2026-08-13 | Exact DOI lookup for 21 selected canonical works | One work per DOI; current Crossref metadata | 21 | 21 | Confirmed title, author order, source, publication date, volume, issue, pages or article number, DOI relations, and update relations where registered. |
| VERIFY-03 | live verification | official publisher records | 2026-08-13 | Exact DOI or title lookup for Brown 2022, Hartmeyer 2022 and 2023, Balajadia 2023, Stefani 2024, Frontiers Clouclip 2023, and other priority records | Publisher pages and full text where available | 7 priority records | 7 | Established access-level-specific study details and found the 2023 publisher typographical-errata note attached to Brown 2022. |
| AUTHOR-URL-01 | supplied-source candidate generation | public bioRxiv v2 URL | 2026-08-13 | `https://www.biorxiv.org/content/10.64898/2026.07.28.741277v2` | Exact author-supplied record | 1 full-text record | 1 canonical source | Verified the title, authors, DOI, v2 posting date, full text, overlap with the target cohort, structured placement findings, and public data and code statements. The downloaded temporary PDF had SHA-256 `dd8f47c141c1b36e11b5c83a9665e5101d61054038e4f8f7b673a76a34cbab0a`. |
| VERIFY-04 | live verification | official bioRxiv metadata API | 2026-08-13 | Exact DOI lookup for `10.64898/2026.07.28.741277` | All versions returned by the official endpoint | 2 versions | 1 canonical v2 record and 1 prior-version record | Version 1 was posted 2026-08-01 under an earlier title. Version 2 was posted 2026-08-11 under the cited title. The endpoint reported no journal publication. Version 2 controls citation and claim extraction. |

## Retrieval interpretation

- This is a bounded discovery exercise, not a systematic review. Europe PMC coverage is strong for biomedical records but incomplete for lighting, engineering, conference, and non-indexed literature.
- Large hit sets were rank-capped as logged. Citation chaining was best effort and did not include subscription citation indexes.
- Search failure is not used to prove novelty. Priority language is adjudicated against the verified direct comparators and the explicit search bounds.
- The candidate ledger preserves target-study versions, protocol relations, and the publisher errata note rather than treating them as independent studies.
