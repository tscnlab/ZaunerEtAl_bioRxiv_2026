# REPORT-018 selection scientific-scope audit

Date: 2026-08-31  
Status: **PASS WITH ONE ACTIVE SCIENTIFIC GATE**  
Method: adversarial, read-only audit under `$measurement-methods-audit`  
Scientific computation: R 4.6.1 only

## Executive disposition

The corrected MDER definition has been implemented centrally and has already reached accepted production reporting for H05, H06_daily, and H10. H01 is the only MDER-fitting hypothesis that remains between recalculation and accepted production integration.

For H01, the corrected metric inputs and eight isolated point refits are complete. During this audit the author explicitly accepted that point-result baseline and authorized the separately stored 50-successful-refit pilot. Production bootstrap outputs, final multiplicity fields, Stage 2 through Stage 4 replacements, and report integration remain held for a separate approval after pilot review. Therefore the current selection table is correct to show the definition-aligned descriptive MDER value while leaving the H01 model cells pending.

The Descriptives Supplementary Table S2 issue is not an H02 issue. Eleven cells currently rendered as `Not applicable` mix three different situations: structurally inapplicable cells, values derivable from frozen coverage artifacts, and one paired-minute field whose estimand is not yet defined. The table should be restructured or selectively completed, not filled indiscriminately.

The Brown cross-state within-person and between-person results must remain separate from the main Brown adherence table. They are an exploratory extension with a withheld day-level claim and limited, non-causal between-participant interpretation. If displayed, all four prespecified contrasts belong in a compact Supplementary block with their single BH family and explicit claim status.

The requested H03 and H04 temporal composites are scientifically coherent as selection-only assemblies. Each temporal figure already provides panels a through c. The corresponding accepted factorization table may be added as panel d, with its support table retained as provenance.

## Findings

### SEL-MDER-001: H01 is recalculated at point-estimate level, but not yet accepted at production-report level

- Severity: High
- Confidence: Confirmed
- Domain: Scientific computation, multiplicity, and reporting
- Evidence: the accepted H01 model tests contain 32 `mder_ratio_of_integrals` rows and the accepted model manifest contains 72 such rows. The isolated corrected point artifacts contain 32 and 72 `mder_mean_of_viable_ratios` rows, respectively. The gate records eight isolated runs, zero major diagnostic failures, three primary MDER support changes, one primary non-MDER family consequence, and required bootstrap intervals.
- Current authority: the author has now accepted the point-result baseline and authorized the 50-successful-refit pilot. The separate production approval remains open.
- Consequence: do not populate or promote the H01 MDER model cells in Table 3 from isolated point results. Do not replace accepted H01 scientific or reporting artifacts until the pilot is reviewed and production is explicitly authorized.
- Verification: exact R 4.6.1 row-level reconciliation plus source/report footprint audit.

### SEL-FLOW-001: Descriptives Table S2 conflates structural absence with derivable counts

- Severity: Medium
- Confidence: Confirmed
- Domain: Sample flow and denominator communication
- Evidence: 11 missing cells were classified. Two roster cells are structurally inapplicable at roster grain. Eight near-eye/chest cells are derivable from frozen daily coverage, with four source-minute values conditional on retaining the existing source-real-minute definition. The paired one-minute count remains undefined until a paired-minute estimand is declared.
- Consequence: replace the blanket `Not applicable` presentation with stage-specific labels or a table structure that respects grain. Any insertion of candidate counts requires a separately accepted Descriptives owner return.
- Verification: R 4.6.1 derivation from the frozen near-eye and chest daily coverage artifacts.

### SEL-BROWN-001: Cross-state associations do not belong in the main Brown table

- Severity: High
- Confidence: Confirmed
- Domain: Claim role and multiplicity
- Evidence: the frozen BA-CS-M1 family contains exactly four contrasts. Both within-person contrasts are not FDR-supported and the day-level claim remains withheld. Both between-participant inverse contrasts are FDR-supported but are explicitly exploratory, limited, non-causal, and not stable-trait evidence.
- Consequence: keep Table 2 focused on the approved main endpoint-inflated Brown model. If desired, place the four cross-state contrasts in one compact Supplementary block with all limitations and no ranking language.
- Verification: R 4.6.1 audit of the frozen four-row multiplicity file and accepted role records.

### SEL-COMP-001: H03 and H04 temporal figure-plus-table composites are supported

- Severity: Low
- Confidence: Confirmed
- Domain: Selection-only display assembly
- Evidence: H03 near-eye support is 140 participants, 801 participant-days, 17,935 observations, nine sites, and 4,977 exact-zero hours. H04's selected five-category near-eye contract is 126 participants, 724 participant-days, 16,135 unique and effective weighted hours, 16,875 long rows, nine sites, and 4,746 exact-zero hours. Both interaction gates pass.
- Consequence: the accepted factorization table can serve as panel d beneath each accepted temporal figure without any hypothesis refit or source-data change.
- Verification: R 4.6.1 audit of model-frame indexes and interaction-architecture gates.

## Cross-hypothesis MDER status

| Hypothesis | Fits MDER | Current status | Report integration |
|---|---|---|---|
| H01 | Yes | Corrected shared inputs and eight isolated point refits; point baseline accepted; 50-successful-refit pilot authorized | Pending pilot review and separate production approval |
| H05 | Yes | Corrected primary and gap MDER models and multiplicity fields accepted | Result and companion accepted |
| H06_daily | Yes | Corrected primary and gap MDER branch accepted | Result and companion accepted |
| H10 | Yes | Corrected primary and gap MDER models and tests accepted | Result and companion accepted |
| H02, H03, H04, hourly H06, H07, H08, H09, H11 | No | No MDER scientific fit | No scientific rerun required; provenance-only refresh may apply |

The queued H06_daily removal of the MDER-specific legend class is display-only. It does not reopen the accepted MDER estimates, tests, or multiplicity decisions.

## H01 evidence and gate boundary

Controlling evidence:

- METRIC-010 decision: `audit/decisions/mder_mean_of_viable_ratios.md`, SHA-256 `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`.
- H01 point-result gate: `audit/hypotheses/H01/mder_METRIC-010/H01_METRIC-010_author_gate.md`, SHA-256 `c4d9842dc59b51afcc7fc50426903ab9b656fc29beac9e9cba2dcf4372f142cc`.
- Gate summary: `audit/hypotheses/H01/mder_METRIC-010/author_gate_post_repair/H01_METRIC-010_gate_summary.csv`, SHA-256 `0d7876c800b4862b22a4ab92c4cc7dde3b4aa77273137eb74f9d883bbe1e1b92`.
- Accepted H01 result QMD: SHA-256 `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`.
- Accepted H01 companion QMD: SHA-256 `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`.

The accepted H01 Stage 3 source-data layer still contains the superseded definition in 10 CSV files and 80 matching lines. This is expected under the gate. It is not permission to perform a partial replacement.

## Descriptives Table S2 disposition

The audit-only candidate reconstruction produced these pre-screen and all-zero-screen values:

| Placement | Stage | Participants | Participant-days | Source-real minutes |
|---|---|---:|---:|---:|
| Near eye | Eligible before all-zero screen | 141 | 818 | 1,178,040 |
| Near eye | Excluded all-zero | 1 | 2 | 2,880 |
| Near eye | Main after all-zero screen | 141 | 816 | 1,175,160 |
| Chest | Eligible before all-zero screen | 154 | 905 | 1,303,200 |
| Chest | Excluded all-zero | 2 | 3 | 4,320 |
| Chest | Main after all-zero screen | 154 | 902 | 1,298,880 |

These are audit candidates, not accepted table values. They may be promoted only after the Descriptives owner confirms the denominator labels and exact intended table grain. Roster participant-days and roster minutes should remain structurally inapplicable. The paired-minute value should remain undefined unless a paired-minute estimand is prospectively declared.

Frozen inputs:

- `artifacts/03_coverage/light_glasses_daily_coverage.csv`, SHA-256 `d1fdc38d7d8f15b8f978d532341694e5837463a8cf7e298492fca18b60af7860`.
- `artifacts/03_coverage/light_chest_daily_coverage.csv`, SHA-256 `ae2d0f890ec7b5db59a61e1687b629bf228fe0ec4a6166b8ffe202f66fb874b4`.
- `audit/descriptives/sample_count_contract.csv`, SHA-256 `034e449164d617431e149b9ab28867ba4cc52830620e7acd606e756de61f1dd3`.

## Brown role boundary

The four-row BA-CS-M1 file is SHA-256 `c86a119f0bd272c54088024a8e7fdf660f865bc697316f41521c6e0aad19e47f`. The two within-person estimates are exploratory with the day-level claim withheld. The two between-participant estimates are exploratory with limitations. They must not be merged into Table 2 in a way that makes them appear co-primary with the accepted main Brown model.

## Accepted main-display scientific order

1. Figure 1: study overview.
2. Table 1: short participant and site summary.
3. Table 2: main Brown adherence results.
4. Figure 2: H02 daily display.
5. Table 3: Descriptives plus H01 synthesis, with H01 MDER model cells pending until production acceptance.
6. Figure 3: H03 temporal panels plus the accepted factorization table as panel d.
7. Figure 4: H04 temporal panels plus the accepted factorization table as panel d.

Person-level synthesis belongs in Supplementary information. The redundant descriptive Figure S1 may be removed. The accepted Brown Work-day and Free-minus-Work forests may be paired side by side as a selection-only composition.

Selection-only table treatments are scientifically safe if values and endpoint identities remain exact: conventional horizontal `gt` layout, row groups and column spanners, three-decimal display, one definition of median (IQR), taller distribution panels, and a wider metric-name column in the full Supplementary metric table.

## Reproducibility

Commands:

```text
env RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla /private/tmp/report018_selection_scope_audit_20260831.R
env RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla /private/tmp/report018_mder_hypothesis_status_audit_20260831.R
```

Execution environment: R 4.6.1, aarch64-apple-darwin23, macOS Tahoe 26.5.2, base R only.

Temporary audit script identities:

- Selection-scope audit: SHA-256 `560b46272695be930364df492aa6cf05e2b410ced97844c3268305828906dfb2`.
- Cross-hypothesis MDER audit: SHA-256 `8a372238fa9e79c1fa151a8701e3ddbe91167d7ff36e6e9491db10a5dd89dcc5`.

The audit created no model, prediction, bootstrap, scientific artifact, QMD, HTML, or manuscript change. The live planning QMD observed during the audit was `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`, SHA-256 `b749f349d5876c1ef482ebbaf0d9083037343db84b776b9ca3efcc2091bed418`; it was not edited by this audit.

