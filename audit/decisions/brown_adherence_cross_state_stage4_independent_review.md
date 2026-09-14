# Brown adherence cross-state Stage 4 independent review

Date: 2026-08-21  
Controlling authority: `BA-016 / CHG-155`  
Gate: `BA-CS-G4-REVIEW`  
Disposition: `INDEPENDENTLY_VERIFIED_STOPPED_SEMANTIC_DEFECT`

## Review disposition

The Stage 4 preparation and provenance package is scientifically and
provenance-complete within its authorized scope. Its source, stored data,
single render, visual presentation, links, privacy boundary, protected
identities, and teardown evidence independently reproduce.

The package is not yet accepted at `BA-CS-G4-REVIEW`. Independent DOM review
found one bounded HTML accessibility defect, `BA-CS-G4-SEM-001`, that the
task's 17-table structural check did not test. The author gate therefore
remains open. No Stage 4 provenance follow-up may yet be sent to the Nature
Health writer, and no shared navigation or reciprocal Stage 3 link is
authorized.

This review creates no new Brown decision or change ID. `BA-016 / CHG-155`
remains controlling until the repaired Stage 4 package is independently
accepted and the author explicitly accepts `BA-CS-G4-REVIEW`.

## Reproduced package

The following task endpoints are exact:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd` | 24,147 | `642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29` |
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html` | 4,323,083 | `697ec3a5627b082e293ed9a3d15a8a1a5329d2149befd4930a18621ae0ab8716` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv` | 35,088 | `b2e3e079747c6ad90c5f26c6c0c5b85f682404203bde2e77e1f2a4e320f17150` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest_verification.csv` | 20,514 | `aeaacd2f04fb7e70e6fdea6787f85f900d4c0bcb2c4ace4d9445cd683fc276f6` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/stage4_handoff.md` | 4,989 | `3aa14b8a04fb3504f245ea59a69046c16a777cef140bf0afb216d0da5635d32f` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/author_gate.md` | 805 | `2d6550d72c91058a566b30e1ed6187b45da6ab873f8a6b91a8ed885ea99133ba` |

R 4.6.1 independently rehashed all 79 final-manifest members by path, byte
count, and SHA-256. Paths are unique and the manifest is non-circular. The
review also reproduced:

- 25 of 25 finalization checks;
- 26 of 26 source checks;
- 28 of 28 render checks;
- 17 of 17 structural table checks;
- 18 of 18 deterministic narrow-layout checks;
- 18 of 18 native visual-inspection records;
- 806 of 806 protected identities; and
- 6 of 6 central authority pins.

The QMD contains only frozen-source loading, verification, and `gt` display
code. No model fit or refit, prediction, contrast, p-value, confidence
interval, multiplicity adjustment, resampling, simulation, or new scientific
calculation is present. The accepted Stage 3 package and all central authority
files remain exact.

All 18 retained native screenshots were independently inspected. They confirm
readable prose, the full analysis-path diagram, all 17 tables, the main and
exploratory tabsets, contained horizontal scrolling for the one wide table,
the main-versus-exploratory hierarchy, the day-level claim hold, the separate
multiplicity families, and the final provenance limitations. Port 50370 has
no listener and the temporary served directory is absent.

## BA-CS-G4-SEM-001

The standalone render did not pass through the accepted Nature Health
post-render `gt` semantic repair. The task's `semantic_table_audit.csv`
verifies table containers, captions, `thead`, `tbody`, and cell presence, but
does not verify document-wide ID uniqueness or the HTML `headers` IDREF
relationships.

Independent XML inspection of the accepted HTML found:

- 17 native `gt` tables and 100 table-internal IDs;
- zero within-table duplicate IDs;
- 15 ID names duplicated across the document, creating 26 occurrences beyond
  the first;
- 552 `headers` attributes;
- 228 invalid `headers` attributes across 10 tables; and
- 738 of 1,183 whitespace-delimited IDREF tokens that do not resolve exactly
  once inside their own table.

This is an HTML accessibility and semantic-integration defect. It does not
change any visible value, caption, note, row, column, order, scientific claim,
source data, QMD source, or visual layout.

## Temporary repair proof

A temporary-copy-only R 4.6.1 prototype established that a bounded no-rerender
repair is feasible with the accepted engine:

`scripts/report_harmonization/repair_gt_html_semantics.R`  
SHA-256: `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`

One table uses an HTML entity inside a generated ID and three corresponding
`headers` attributes. The prototype normalized only these four attribute
values in temporary bytes before invoking the unchanged accepted engine:

- one `id="a&gt;=80%-difference,-pp"` attribute; and
- three `headers="&gt;=80% difference, pp"` attributes.

The engine then rewrote exactly 100 IDs and 552 `headers` attributes across 17
tables, for 652 reversible substitutions. The candidate had zero duplicate
document IDs. All 683 resulting header tokens resolved exactly once to a `th`
inside the intended table. The engine preserved full visible text, table
counts, rows, cells, header cells, element order, and all non-`id` and
non-`headers` DOM structure. Composed reversal, including the four entity
normalizations, reproduced the accepted HTML SHA-256
`697ec3a5627b082e293ed9a3d15a8a1a5329d2149befd4930a18621ae0ab8716`
exactly. The temporary candidate SHA-256 was
`c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f`.

The prototype did not edit the task QMD, HTML, final manifest, handoff, gate,
source data, shared configuration, or any accepted artifact. Its candidate is
not an accepted output.

## Authorized bounded continuation

The Brown task may perform one no-rerender semantic continuation under the
existing Stage 4 root only:

1. Preserve the current QMD, HTML, 79-member manifest, manifest verification,
   handoff, gate, all stopped evidence, all source data, and all 806 protected
   identities as the exact pre-repair baseline.
2. Create a Stage 4-owned wrapper and focused accessibility test that pin the
   accepted repair-engine hash and the current HTML preimage.
3. Normalize only the exact one ID attribute and three `headers` attributes
   listed above in temporary bytes, then invoke the unchanged accepted repair
   engine.
4. Require an exact composed reverse to the current HTML, zero duplicate
   document IDs, every explicit header token resolving exactly once to the
   intended `th` inside its own table, and no change to visible text, table
   counts, rows, cells, captions, notes, order, or nonsemantic DOM structure.
5. Replace only the Stage 4 HTML once after the candidate passes. Do not run
   Quarto and do not execute the QMD.
6. Reseal only directly dependent Stage 4 evidence, the final manifest,
   manifest verification, handoff, and author gate. Preserve the pre-repair
   manifest and semantic finding as historical evidence. Do not edit the QMD,
   source data, accepted Stage 3 package, central ledgers, shared profile,
   navigation, manuscript, package, or lockfile.
7. Rerun all source, render-structure, link, privacy, protected-identity, and
   finalization checks that remain applicable. Add the complete ID and IDREF
   accessibility contract. Visual screenshots may be retained because the
   accepted engine proves visible text and nonsemantic DOM identity; do not
   claim a new browser QA run.
8. Return one sealed package for independent review. Stop on any additional
   mismatch or if the repair cannot remain exactly reversible and invisible.

No render, fit, inference, writer follow-up, shared integration, commit, push,
or upload is authorized. After independent repair acceptance, the author must
still explicitly accept `BA-CS-G4-REVIEW` before the gate closes.

## Author-gate wording after repair acceptance

Once the repaired Stage 4 package is independently accepted, request:

> Approve Brown cross-state Stage 4 as written

Until that wording or another unambiguous explicit Stage 4 acceptance is
received, the provenance-only Nature Health writer follow-up remains held.
