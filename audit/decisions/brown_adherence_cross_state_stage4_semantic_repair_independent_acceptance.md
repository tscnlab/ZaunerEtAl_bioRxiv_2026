# Brown adherence cross-state Stage 4 semantic repair independent acceptance

Date: 2026-08-21  
Controlling authority: `BA-016 / CHG-155`  
Gate: `BA-CS-G4-REVIEW`  
Disposition: `ACCEPTED_REPAIR_PENDING_AUTHOR_APPROVAL`

## Decision

The bounded no-rerender continuation for `BA-CS-G4-SEM-001` is independently
accepted. The repaired HTML now satisfies the complete native-`gt` document-ID
and `headers`-IDREF contract. The repair is exactly reversible to the accepted
pre-repair HTML and changes no visible or scientific content.

This closes the semantic blocker identified in the central Stage 4 review. It
does not close `BA-CS-G4-REVIEW`. The author gate remains open until the author
explicitly approves the repaired package. The provenance-only Nature Health
writer follow-up remains held until that author approval.

No new Brown decision or change ID is created. `BA-016 / CHG-155` remains the
controlling authority.

## Reproduced endpoints

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd` | 24,147 | `642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29` |
| `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html` | 4,340,432 | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv` | 54,203 | `80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest_verification.csv` | 29,804 | `60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/stage4_handoff.md` | 7,248 | `2a7e132879c499d9d312b63c9a11a9a32fdc977d08eb43f1fda2ae7cdd11bebe` |
| `audit/analyses/brown_adherence/stage4_cross_state_association/author_gate.md` | 1,437 | `7c6e1b3bcc267ec527fbb8a52b753c41b3258edf7bc80ff4f7f63bb50c167453` |
| `semantic_repair/semantic_repair_finalization_checks.csv` | 1,663 | `83da4a1e42fc4732809ec396a4a56e739df77c49f8056af41085a93ae71e4232` |
| `semantic_repair/semantic_repair_finalization_execution_record.csv` | 1,489 | `c29cd6795b29adb120d144d539aa45c54c879409ab6d0308c2ad77143a077a91` |

The QMD retains its accepted pre-repair identity. `renv.lock` remains 603,493
bytes at SHA-256
`3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

## Independent package audit

R 4.6.1 independently verified the renewed final manifest as 113 of 113 exact
members by relative path, absolute path, byte count, and SHA-256. Paths are
unique and the manifest excludes both itself and its verification file. The
113-row verification file also passes in full.

The independent audit further reproduced:

- 12 of 12 semantic-repair preflight checks;
- 24 of 24 temporary-candidate checks;
- 12 of 12 post-repair source checks;
- 28 of 28 post-repair render, structure, link, and privacy checks;
- 17 of 17 repaired native-table checks;
- 8 of 8 responsive-preservation checks;
- 26 of 26 repair-finalization checks;
- 7 of 7 live central authority pins;
- 806 of 806 protected identities; and
- all 79 historical package members, comprising 76 unchanged live members and
  three exact historical-to-current transitions with retained baseline copies.

The three authorized current transitions are exactly the Stage 4 HTML,
handoff, and author gate. Their accepted pre-repair identities remain
recoverable in the task-owned baseline directory. The original 79-member
manifest and its verification are retained exactly as historical evidence.

## Independent semantic and reversal audit

The accepted repair engine remains:

`scripts/report_harmonization/repair_gt_html_semantics.R`  
SHA-256: `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`

The repair ledger contains exactly 652 substitutions across 17 tables:

- 100 generated `id` substitutions; and
- 552 generated `headers` substitutions.

Independent XML inspection of the repaired HTML found 963 document IDs, all
unique. The 552 `headers` attributes contain 683 IDREF tokens. Every token
resolves exactly once to a `th` element inside its intended table. There are
zero unresolved, nonunique, or non-header targets.

Independent composed reversal first reversed the 652 repair-ledger entries and
then restored the exact one generated ID entity and three matching `headers`
entities. The result reproduced the pre-repair HTML byte-for-byte at SHA-256
`697ec3a5627b082e293ed9a3d15a8a1a5329d2149befd4930a18621ae0ab8716`.

The pre-repair and post-repair documents have identical visible XML text and
identical normalized DOM after excluding only the values of `id` and
`headers`. Rows, cells, header cells, captions, notes, element order, links,
CSS, and all other DOM structure are therefore unchanged. The retained visual
evidence remains applicable without a new browser run.

## Execution and warning disposition

The records confirm exactly one canonical HTML replacement and zero Quarto
commands, additional renders, browser-QA reruns, model fits, predictions, or
new inferential calculations. The temporary candidate directory is absent and
port 50370 has no listener.

The finalization console's 19 base-R warnings are nonconsequential verifier
warnings. Each arose because one fixed-string reader-token check supplied both
`fixed = TRUE` and `ignore.case = TRUE`; base R used fixed matching and ignored
case folding. All 19 checks passed. The independent checker validates the
repaired package without this redundant argument combination, so no output,
identity, or acceptance conclusion depends on the warnings. No evidence-only
correction loop is required.

## Remaining gate

The Brown task may now present the repaired Stage 4 package for author review.
The required wording is:

> Approve Brown cross-state Stage 4 as written

Until that approval is received and centrally recorded:

- `BA-CS-G4-REVIEW` remains open;
- the provenance-only writer follow-up remains held;
- shared navigation and the reciprocal Stage 3 link remain held; and
- no commit, push, upload, or additional render is authorized by this record.

The task should not edit or reseal the accepted repair package merely to change
its internal status from pending independent review to pending author review.
This central acceptance record supplies that transition without another
artifact loop.
