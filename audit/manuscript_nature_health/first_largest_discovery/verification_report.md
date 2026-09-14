# Verification report

Overall result: **verified within stated bounds**

## Source bounds and discovery mode

- Mode: live literature discovery with repository and legacy-manuscript candidate generation, followed by claim-specific verification of one author-supplied public preprint.
- Search date: 2026-08-13, Europe/Berlin.
- Live services: Europe PMC search and core-record API, Crossref work API, PubMed and PubMed Central records, official publisher pages, and best-effort backward and forward citation links.
- Publication bounds: English-language records available through the search date, with no lower date bound.
- Topic bounds: free-living personal ocular or near-eye light measurement, international and multisite personal-light comparison, harmonized protocols, wearability and measurement position, relevant methods frameworks, and the Brown melanopic recommendations.
- Candidate-only local sources: the repository bibliography, legacy manuscript references, and target-study identifiers.

This was not a systematic review. The exact query families, caps, and access limitations are recorded in search_log.md.

## Counts

### Candidate ledger

- Candidate rows: 35
- Verification status: 34 verified, 1 unverified
- Primary status:
  - 11 verified_direct_empirical
  - 7 verified_methods
  - 7 verified_contextual
  - 5 duplicate_or_version
  - 3 excluded
  - 1 unverified
  - 1 correction_or_retraction
- Access level:
  - 22 full text
  - 6 abstract
  - 7 metadata

### Evidence matrix and bibliography

- Verified canonical works in the evidence matrix: 25
- Evidence-matrix status:
  - 11 direct empirical
  - 7 methods
  - 7 contextual
- Evidence-matrix access:
  - 20 full text
  - 5 abstract
- Reading priority:
  - 10 Tier A
  - 15 Tier B
- BibTeX entries: 25, one per evidence-matrix citation key

These counts are structural package counts, not scientific results.

## Identity and metadata verification

Exact DOI queries against Crossref verified the selected canonical titles, author order, publication source, date, volume, issue, pages or article number when registered, version relations, and update relations. Exact DOI or PMID queries against Europe PMC verified biomedical indexing, PubMed Central access, preprint links where exposed, and retraction or correction fields.

Publisher records were inspected for the highest-priority sources, including the Brown recommendations, the two Hartmeyer framework papers, the corneal-plane acceptability studies, the Frontiers Clouclip study, and the published target protocol.

The author-supplied placement record was verified against the official bioRxiv metadata API and the complete public v2 PDF. The API returned version 1, posted 2026-08-01 under an earlier title, and version 2, posted 2026-08-11 under **Sensor placement causes outcome-dependent bias in ambulatory light-exposure estimates**. Version 2 controls citation and claim extraction. The API reported no journal publication, and the inspected v2 record carried no withdrawal notice.

One target-linked Zenodo DOI remains unverified because its authoritative metadata were not independently inspected in this bounded pass. It is absent from the evidence matrix and bibliography and does not affect the positioning decision.

## Deduplication and version decisions

- The published BMC Public Health protocol is canonical; its medRxiv version is retained as preprint_of.
- The published Digital Biomarkers corneal-plane usability article is canonical; its medRxiv version is retained as preprint_of.
- The published Clocks & Sleep field-compliance article is canonical; the Europe PMC preprint record is retained as preprint_of.
- The published Open Research Europe placement-wearability article is canonical; its medRxiv version is retained as preprint_of.
- The public bioRxiv placement version 2 is canonical for citation; version 1 is retained as prior_version_of under the same DOI.
- The target preprint and target-linked Zenodo artifact are not external evidence for the target's own novelty.
- The Kumasi report is a verified publication from one site of the same programme. It is retained but excluded as an independent comparator.

No superseded preprint appears in library.bib.

## Correction, concern, and retraction checks

Europe PMC did not flag any selected canonical work as retracted. Crossref exposed no update-to relation indicating a correction, expression of concern, or retraction for the selected canonical records.

The official PLOS Biology page for Brown et al. carries a publisher note titled “Typographical Errata,” posted on 2023-04-04. The candidate ledger attaches that note to the Brown canonical record. The current publisher article is used for thresholds and caveats. The note is not treated as an independent study and does not receive a separate BibTeX entry.

No expression of concern or retraction was found for Brown et al. or the other selected canonical works. This statement is limited to the services and records inspected on 2026-08-13.

The official bioRxiv API reported two active versions of the placement preprint and no journal publication. No withdrawal, removal, correction, or other post-publication notice was present in the inspected version 2 record. This is a preprint-status check, not a peer-review assessment.

## Proximity-score verification

Each evidence-matrix row has six independent 0-to-2 relevance scores for construct, measurement chain, population, design, temporal handling, and analysis. The stored total equals the sum of those axes. Scores prioritize reading only and do not represent methodological quality, certainty, validity, or authority.

## Output-to-ledger cross-checks

- Every evidence-matrix canonical record occurs in a verified candidate-ledger row.
- Every evidence-matrix citation key occurs once in library.bib.
- Every BibTeX DOI maps to one canonical evidence-matrix record.
- No excluded, unverified, correction-only, or superseded version appears in the bibliography.
- The Brown publisher note is linked to its affected record.
- The placement preprint's prior version is retained in the ledger, while only version 2 appears in the bibliography.
- Numerical sample-size statements used in the positioning decision were taken from inspected authoritative records or full text, not calculated from search snippets.
- The target study's accepted sample and recommendation-context values remain mapped to accepted repository artifacts rather than to this external literature package.

## Strongest verified positioning

The bounded literature supports:

> a harmonized near-eye study across nine sites in seven countries

and, with a clear definition of architecture:

> The international architecture of personal light exposure

It does not support an unqualified “first” or “largest” claim. Larger spectacle-mounted samples were verified, and near-eye field measurement has a long prior history. No exact external match for the combined nine-site, seven-country, harmonized near-eye melanopic and contextual design was verified, but search failure is not treated as proof of novelty.

The public placement preprint supports a separate measurement claim: differences among glasses, chest, and wrist records are structured by analytical scale, metric class, context, site, day, and participant, so they cannot be reduced to one universal offset or correction. Because that analysis uses an overlapping MeLiDos cohort, it is related evidence rather than independent replication or novelty support.

## Health-relevant connection

Brown et al. provides a verified expert-consensus benchmark supported by human circadian, neuroendocrine, and alerting-response evidence. The target study may compare fractions of valid measured minutes with its daytime, pre-sleep, and sleep-environment ranges.

The benchmark does not authorize:

- person-level labels of adherent or non-adherent;
- claims that a participant was healthy or unhealthy;
- estimates of benefit, harm, or risk;
- claims of measured biological response; or
- causal interpretation of contextual exposure associations.

## Limitations and unsearched sources

- Scopus, Web of Science, Embase, ProQuest, IEEE Xplore, and other subscription indexes were not searched.
- Large Europe PMC results were capped at the first 100 service-ranked records where logged.
- Citation chaining was best effort and incomplete.
- Non-English publications were outside scope.
- Abstract-only sources could not support unreported implementation details.
- No dual independent screening, registered review protocol, formal risk-of-bias appraisal, or certainty assessment was performed.
- Device reviews and author novelty statements were not treated as exhaustive study registries.
- The placement preprint was verified for the author-requested qualitative claim, but no independent peer-review appraisal or full risk-of-bias assessment was performed.

## Recommended explicit handoffs

If manuscript drafting needs sequential, claim-level extraction from a selected article, explicitly authorize the read-paper skill. If it needs one narrow threshold, placement, sample, or caveat lookup in a long source, explicitly authorize the search-pdf skill. Neither skill was invoked during this discovery pass.
