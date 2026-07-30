# Nature Health requirements audit

Audit date: **2026-07-29**

Target: **identified Nature Health Article**

Scope: current journal-facing requirements that affect manuscript structure, submission files, reporting forms, disclosures, data and code availability, related manuscripts, and final artwork. Only official Nature Health, Nature Portfolio, and Springer Nature sources were used. The machine-readable companion is `nature_health_compliance.csv`.

## Status vocabulary

- `PASS`: current project evidence appears to meet the requirement, subject to final author verification.
- `PARTIAL`: relevant material exists, but required content or verification remains incomplete.
- `OPEN`: the required artifact or verification has not yet been produced.
- `NOT_VERIFIED`: no sufficient current-state evidence has been gathered.
- `FAIL`: the current artifact visibly conflicts with the requirement.
- `GATE`: an editorial-fit condition that cannot be solved by formatting alone.
- `REMOVED`: the publisher has withdrawn the formerly required artifact.

Requirement stages are:

- `gate`: journal-scope or editorial-fit criterion;
- `initial`: applies to the initial submission;
- `review`: applies if the manuscript is selected for peer review or the editor requests it;
- `AIP`: applies at acceptance in principle or final submission.

## Consequential findings

### Participant and community engagement is a fit gate

Nature Health states that it “requires meaningful engagement with research participants and their communities,” with reference to the 2024 revision of the Declaration of Helsinki. The project records no formal participant or community involvement beyond participation and site collaboration. A negative involvement statement is necessary for candour but does not itself satisfy this stated criterion. Site collaboration must not be relabelled as meaningful engagement without supporting evidence. This is a potential eligibility and desk-rejection risk. See [Nature Health Aims & Scope](https://www.nature.com/naturehealth/aims).

### The absence of a health outcome remains an editorial-fit gate

Environmental health and observational studies are expressly in scope, but Nature Health’s consideration criteria are originality, timeliness, and impact on health policy and practice. The study characterizes personal light exposure without a health outcome. This is not an explicit formatting violation, but health-policy or practice relevance must be demonstrated without implying an unmeasured health effect. See [Nature Health Aims & Scope](https://www.nature.com/naturehealth/aims).

### The Editorial Policy Checklist has been removed

The current canonical [Editorial Policy Checklist endpoint](https://www.nature.com/documents/nr-editorial-policy-checklist.pdf) says that the form “is no longer required for Nature Portfolio submissions and has been removed.” The April 2023 flat checklist is obsolete and must not be staged by default. If the live submission system or editor requests a replacement, follow that contemporaneous instruction and record the exception.

This conflicts with stale references on the Nature Health double-blind page and within the older flat Reporting Summary. The removal notice is the most direct current instruction.

## Article format and manuscript

| ID | Requirement | Stage and force | Current project status | Evidence required for closure |
|---|---|---|---|---|
| NH-001 | Originality, timeliness, and impact on health policy/practice; observational and environmental-health research are within scope. | `gate`; fit gate | `GATE` — named scope fit is plausible, but policy/practice impact without a health outcome is not established. | Final fit assessment and cover-letter rationale that do not imply a measured health effect. |
| NH-002 | Meaningful participant/community engagement is required. | `gate`; fit gate | `GATE` — no formal engagement is documented. | Factual involvement statement, author confirmation, and explicit treatment as a desk-rejection risk. |
| NH-003 | Abstract is unreferenced and no longer than 150 words. | `initial`; mandatory | `NOT_VERIFIED` | Reproducible abstract word count and citation scan from the rendered manuscript. |
| NH-004 | Main text is no longer than 4,000 words, excluding abstract, Methods, references, and figure legends. | `initial`; mandatory | `NOT_VERIFIED` | Section-aware word-count report from the final DOCX or authoritative Quarto source. |
| NH-005 | No more than six combined main figures and tables. | `initial`; mandatory | `NOT_VERIFIED` | Final display manifest showing the combined main-item count. |
| NH-006 | Unheaded introduction, followed by Results, Discussion, and Methods; Results and Methods use topical subheadings; Discussion has no subheadings. | `initial`; mandatory | `FAIL` — `index.qmd` currently contains an explicit `Introduction` heading. | Heading-tree check on final source and DOCX/PDF. |
| NH-007 | Approximately 60 references is a guideline, not a hard cap. | `initial`; guideline | `NOT_VERIFIED` | Final resolved-reference count and justification if materially above 60. |
| NH-008 | Title, abstract, and manuscript must be accessible to non-specialists; jargon and abbreviations should be minimized or defined. | `initial`; mandatory/editorial | `PARTIAL` — current prose defines some specialist terms, but final broad-audience review is pending. | Final editorial review and terminology/abbreviation audit. |
| NH-009 | Identified submissions include author names and affiliations in the manuscript; primary affiliation is where most work was done. | `initial`; mandatory | `PARTIAL` — author metadata are present, but final author/affiliation verification is pending. | Author-approved title page, affiliations, corresponding-author details, and current addresses where applicable. |

Primary sources: [Content Types](https://www.nature.com/naturehealth/content), [Writing and language](https://www.nature.com/naturehealth/submission-guidelines/writing-and-language), and [Preparing your material](https://www.nature.com/naturehealth/submission-guidelines/preparing-your-submission).

## Submission files, related work, and references

| ID | Requirement | Stage and force | Current project status | Evidence required for closure |
|---|---|---|---|---|
| NH-010 | Initial submission includes a manuscript and cover letter; Supplementary Information is optional. Initial manuscript may be PDF, Word, or TeX/LaTeX and need not be specially formatted. | `initial`; mandatory | `OPEN` — `manuscript/R0_NatHealth/` does not yet exist. | Submission inventory with one authoritative manuscript file and cover letter. |
| NH-011 | Cover letter explains importance and fit for Nature Health’s diverse readership, discloses related manuscripts, and identifies prior discussions with a Nature Health editor. | `initial`; mandatory | `OPEN` | Final author-approved cover letter. |
| NH-012 | Related material under consideration or in press is disclosed, uploaded as a clearly marked copy, and described in the cover letter; later related submissions must also be reported. | `initial`; mandatory | `OPEN` — the placement manuscript is known but not staged. | Related-manuscript copy, status/date record, overlap/distinction statement, and cover-letter disclosure. |
| NH-013 | Public preprints may be cited and must be disclosed with DOI and licence. Work under review without a public preprint should not be a numbered reference. | `initial`; mandatory | `OPEN` — companion-paper public-preprint status requires final preflight. | Live DOI/status check, bibliography scan, and cover-letter disclosure. |
| NH-014 | Final manuscript source is Word or TeX/LaTeX; PDF is not accepted as the final manuscript source. | `AIP`; mandatory | `OPEN` | Authoritative DOCX that opens cleanly and matches the review PDF. |

Primary sources: [Preparing your material](https://www.nature.com/naturehealth/submission-guidelines/preparing-your-submission), [Initial formatting](https://www.nature.com/naturehealth/submission-guidelines/initial-formatting), [Editorial Policies](https://www.nature.com/naturehealth/editorial-policies), [Plagiarism and duplicate publication](https://www.nature.com/naturehealth/editorial-policies/plagiarism), [Preprints](https://www.nature.com/naturehealth/editorial-policies/preprints-conference-proceedings), and [AIP and formatting](https://www.nature.com/naturehealth/submission-guidelines/aip-and-formatting).

## Figures, tables, Extended Data, and Supplementary Information

| ID | Requirement | Stage and force | Current project status | Evidence required for closure |
|---|---|---|---|---|
| NH-015 | Final tables appear at the end of the text document; complex tables may be Excel files; statistical table legends describe error-analysis standards and ranges. | `AIP`; mandatory | `NOT_VERIFIED` | DOCX inspection and table/legend inventory. |
| NH-016 | Figures are cited in sequence; maximum width 180 mm; bitmap content is at least 300 dpi; labels are editable 5–7 pt sans serif; original-research artwork is RGB; graphs/charts/schematics are supplied as editable vector AI/EPS/PDF. | `AIP`; mandatory | `NOT_VERIFIED` | Per-figure technical inspection at final physical size, file-format/resolution manifest, and rendered-page inspection. |
| NH-017 | Legends briefly title each figure, describe panels in order, identify centre and error values and their calculation, report sample size, statistical test, and P values, and avoid unnecessary methods detail. | `AIP`; mandatory | `NOT_VERIFIED` | Figure-legend audit against exact analysis outputs. |
| NH-018 | At most ten Extended Data display items; each is cited and fits one PDF page. | `initial`/`AIP`; mandatory if used | `NOT_VERIFIED` | Combined Extended Data figure/table manifest and final-size page check. |
| NH-019 | Supplementary text, simple tables, figures, and legends are combined in one PDF; items use separate sequential numbering, are cited in sequence, and each Supplementary Figure plus legend fits one page. | `initial`/`AIP`; mandatory if used | `OPEN` | Final combined SI PDF, citation-order check, and visual page inspection. |
| NH-020 | Statistical source data should be supplied in Excel, one file per relevant figure, with the linked figure identified. | `AIP`; strongly recommended/expected | `OPEN` | One journal-facing `.xlsx` per main and Extended Data figure, reconciled to exact tracked CSV producers. |

Primary sources: [AIP and formatting](https://www.nature.com/naturehealth/submission-guidelines/aip-and-formatting) and the [Nature-branded final-artwork guide](https://www.nature.com/documents/NRJs-guide-to-preparing-final-artwork.pdf).

## Reporting forms and study-design guidance

| ID | Requirement | Stage and force | Current project status | Evidence required for closure |
|---|---|---|---|---|
| NH-021 | Life-, clinical-, behavioural/social-, and environmental-science research selected for review must provide the Nature Portfolio Reporting Summary. | `review`; mandatory | `OPEN` | Completed interactive Reporting Summary, reconciled to the manuscript and analysis ledgers. |
| NH-022 | Editorial Policy Checklist. | `review`; removed | `REMOVED` — do not stage the obsolete April 2023 form. | Current endpoint still states removal at final preflight; otherwise record editor/system instruction. |
| NH-023 | Observational cohort, case-control, or cross-sectional studies must be reported according to STROBE. Nature Health does not explicitly require uploading the completed checklist. | `initial`; mandatory reporting standard | `OPEN` | Completed STROBE checklist and manuscript page/section map; upload only if requested or accepted by the portal. |
| NH-026 | A software submission checklist is required before review only when newly developed code/software is central to the main claims. | `review`; conditional | `OPEN/CONDITIONAL` | Editorial classification plus, if triggered, code version, README, install guide, dependencies, demo/test data, runtime, repository/DOI, and licence. |
| NH-027 | Details of study and analysis-plan preregistration should be provided with submission. | `initial`; mandatory disclosure where applicable | `PARTIAL` — a preregistration/deviation section exists; full contract and deviation audit are in progress. | Identifier/link, final deviation register, and agreement across Methods, SI, and Reporting Summary. |

Official current files:

- [Interactive Nature Portfolio Reporting Summary](https://www.nature.com/documents/nr-reporting-summary.pdf) — use this fillable PDF in Adobe Reader.
- [Flat Reporting Summary reference copy](https://www.nature.com/documents/nr-reporting-summary-flat.pdf) — reference/audit copy only.
- [Code and software submission guidance](https://www.nature.com/documents/GuidelinesCodePublication.pdf).
- [Removed Editorial Policy Checklist endpoint](https://www.nature.com/documents/nr-editorial-policy-checklist.pdf).

No current Nature Health Word template, cover-letter template, Nature-hosted STROBE file, or blank Inventory of Supporting Information template was located. Nature Health links to the external STROBE statement from its [Clinical Research policy](https://www.nature.com/naturehealth/editorial-policies/clinical-research).

## Data, code, ethics, and disclosures

| ID | Requirement | Stage and force | Current project status | Evidence required for closure |
|---|---|---|---|---|
| NH-024 | Every original research manuscript includes a Data Availability statement covering access to the minimum dataset, identifiers, and restrictions; supporting data must be available to editors/reviewers on request. | `initial`; mandatory | `PARTIAL` — a data-availability section exists but has not passed final dataset/access reconciliation. | Verified statement, durable identifiers, controlled-access details where needed, and correspondence with deposited data. |
| NH-025 | Central custom code is available to editors/reviewers on request and has a separate `Code availability` section after Data Availability and before references. | `initial`; mandatory | `FAIL` — no distinct Code Availability section was located in `index.qmd`. | Versioned repository/release, access/licence details, and exact end-matter section placement. |
| NH-028 | Human-participant work states Declaration of Helsinki compliance, ethics committee name and reference number, and informed consent. | `initial`; mandatory | `PARTIAL` — TUM approval and consent are stated, but all local committee names/reference numbers require verification. | Author-verified ethics matrix and exact manuscript statements for every site. |
| NH-029 | Sex and gender are distinguished and their determination/categorization described; relevant disaggregated data and prespecified analyses are reported, and omitted analyses are justified in the Reporting Summary. | `initial`/`review`; mandatory where relevant | `NOT_VERIFIED` | Construct/coding audit, disaggregated sample counts, analysis trace, and Reporting Summary justification. |
| NH-030 | All authors approve the manuscript/list/order and accept accountability; every author’s contribution is specified; corresponding-author ORCID is linked before final acceptance. | `initial`/`AIP`; mandatory | `PARTIAL` — contributions and ORCID metadata exist, but final author approval is pending. | Signed or recorded author confirmation, contribution statement, and ORCID verification. |
| NH-031 | A financial/non-financial competing-interests declaration appears in the submission system and article end matter, including a negative declaration where applicable. | `initial`; mandatory | `PARTIAL` — a statement exists but awaits final author verification. | Corresponding-author declaration covering every author and matching manuscript/system text. |
| NH-032 | Relevant funding appears in a separate statement; funder/sponsor role is explicitly stated, including no role where appropriate. | `initial`; mandatory for this human health submission | `PARTIAL` — funding text exists; complete sponsor-role verification is pending. | Author-verified grants-by-author statement and explicit role/no-role text. |
| NH-033 | LLMs are not authors; substantive LLM use is documented in Methods; copyediting-only use need not be; humans remain accountable. | `initial`; mandatory | `FAIL` — the current AI statement describes language editing only and says AI was not used to analyse or interpret data, which will not accurately describe the substantive audit workflow if retained through completion. | Accurate Methods disclosure naming the substantive assistance categories, safeguards, human verification, and accountability. |
| NH-034 | Generative-AI publication images are generally prohibited; non-generative ML image manipulation must be disclosed in the caption. | `initial`/`AIP`; mandatory | `PASS/PENDING FINAL SCAN` — no generative-AI artwork is planned. | Asset provenance scan and author confirmation. |

Primary sources: [Reporting standards and availability](https://www.nature.com/naturehealth/editorial-policies/reporting-standards), [Research Ethics](https://www.nature.com/naturehealth/editorial-policies/ethics-and-biosecurity), [Authorship](https://www.nature.com/naturehealth/editorial-policies/authorship), [Competing interests](https://www.nature.com/naturehealth/editorial-policies/competing-interests), [Funding Statements](https://www.nature.com/naturehealth/editorial-policies/funding), [Clinical Research](https://www.nature.com/naturehealth/editorial-policies/clinical-research), and [Artificial Intelligence](https://www.nature.com/naturehealth/editorial-policies/ai).

## Stale and inconsistent official text

1. The [Content Types page](https://www.nature.com/naturehealth/content) still contains the placeholder `[Please edit list as appropriate, we will update the formatting details with standard text for the article types listed]`. Its Analysis section also mistakenly says “Resource should be divided…”. The Article block is internally coherent, but limits must be rechecked immediately before submission.
2. The current [Editorial Policy Checklist endpoint](https://www.nature.com/documents/nr-editorial-policy-checklist.pdf) says the form has been removed, while the Nature Health double-blind page and older Reporting Summary still mention it. Do not stage the obsolete checklist unless the editor or live portal expressly overrides the removal notice.
3. The preparation page permits ten Extended Data “display items,” while the AIP page refers to ten Extended Data “figures.” Use the conservative limit of ten combined Extended Data figures and tables.
4. Initial submission accepts PDF, Word, or TeX/LaTeX, whereas the AIP page excludes PDF as the final manuscript source. The DOCX must be authoritative.
5. Source data are described as encouraged and then as something statistical papers “should” provide, rather than an explicit initial-submission requirement. Providing complete figure-linked Excel workbooks remains the prudent submission-ready interpretation.

## Preflight rule

Immediately before staging:

1. revisit every official URL recorded in `nature_health_compliance.csv`;
2. record whether its text changed and the new access date;
3. inspect the live submission system’s requested file types;
4. do not add the removed Editorial Policy Checklist unless the system/editor expressly requests it;
5. treat unresolved participant/community engagement and health-outcome fit as explicit desk-rejection risks, not as passed compliance items.
