# REPORT-014 Preparation 07 provenance implementation test stop

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Target: `notebooks/preparation/07_example_days.qmd`

Outcome: **STOP. The authorized provenance-only source revision parses under
R 4.6.1, but the source-only focused test retains a pre-existing literal that
was already absent from the released pre-edit QMD.**

No Quarto or knitr command was run. No QMD chunk was executed. No HTML,
configuration, manifest, scientific data, display artifact, strict verifier,
production script, decision, ledger, lockfile, or handoff was edited.

## Authority and preflight

The controlling order was
`audit/report_harmonization/owner_orders/26_preparation07_provenance_only_implementation.md`,
SHA-256
`cee5cb8654ee3d6a295e646c30db34703a1690d047bfa157069196d1e8168971`.
The author-approved implementation package was
`audit/report_harmonization/preparation07_provenance_implementation_approval_package.md`,
SHA-256
`ee04570314579b724cb91faec30164b1b455586832caa8c533d5bdf643ea28dc`.

Every required starting pin matched before editing:

| File | Pre-edit SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/07_example_days.qmd` | `2293d2520dabaacc7394a39c00b5ac62911da1d34fb489ecf4bf232c55a2998f` | 33,032 |
| `tests/test_preparation07_report.R` | `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f` | 8,317 |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` | 7,404 |
| Audit report | `870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164` | 9,342 |
| Structured evidence | `0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97` | 4,824 |
| Non-circular equivalence seal | `01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c` | 538 |

The earlier stopped-render record remained exact at
`1e482a14f95cb23a4bbc80669b4619ad21ee8ce7e957f498fc88ac0d01bfa1ad`.
Its 23-entry manifest remained exact at
`bb05d47604b26e0082c9059a22a5ff2dd091410dc153f60702d55fb9056df591`.

## Authorized source delta

Only the released QMD and focused test were edited. Their current identities
are:

| File | Post-edit SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/07_example_days.qmd` | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` | 39,361 |
| `tests/test_preparation07_report.R` | `707139e3c19e3ed10308a04876e6c2c2b08cf03a5f5c1faf16d4739d18220bcd` | 11,431 |

The QMD delta is limited to the order-26 boundary:

1. the existing setup chunk now hashes and reads the sealed audit report,
   17-row evidence CSV, and two-entry non-circular seal;
2. the setup replaces the stale three-file exact-match assertion with two
   exact file-identity checks and the sealed historical-to-current
   site/daylight equivalence disposition;
3. the approved reader explanation is added verbatim in the existing
   technical-provenance section;
4. `tbl-example-day-inputs` now displays manifest-recorded and current hashes
   separately and uses `Equivalent values, different file version` for the
   site/daylight row; and
5. `tbl-example-day-current-checks` reports exact identity and sealed
   equivalence without claiming that all historical and current hashes match.

No table endpoint was added. The source still contains seven `tbl-*` labels,
three `fig-example-days-*` labels, and the unchanged `flowchart LR`
declaration. Chunk-level hashing found exactly three changed chunks:
`setup-preparation-07`, `tbl-example-day-inputs`, and
`tbl-example-day-current-checks`. The other eight chunks were byte-identical:
`tbl-example-day-selection`, `tbl-example-day-availability`, all three figure
chunks, `tbl-example-day-rules`, `tbl-example-day-scripts`, and
`tbl-example-day-artifacts`.

The focused-test delta adds only the order-26 source and later-HTML assertions
for the sealed paths and hashes, historical and current pins, approved prose,
plain equivalence label, 17-row evidence contract, two-entry seal, and future
HTML output. Its existing forbidden-execution, seven-table, three-figure,
country-code, source-data, link, and rendered-error assertions remain.

## Reversibility and source integrity

Pre-edit copies were retained outside the author project in a temporary
directory. Unified pre-to-post patches were generated for each edited file,
then reverse-applied to separate post-edit copies. The reconstructed identities
were exact:

- reconstructed QMD:
  `2293d2520dabaacc7394a39c00b5ac62911da1d34fb489ecf4bf232c55a2998f`;
- reconstructed focused test:
  `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f`.

This reproduces both released pre-edit files exactly and proves that the
current changes are fully reversible. `git diff --check` passed for both
edited files.

## R 4.6.1 static checks

Normal project startup initially stalled before reporting an R version at the
known sandbox boundary for the user-owned renv cache and was interrupted. A
narrowly elevated normal-profile retry reached R 4.6.1. Two initial inline
parser harnesses then failed on shell-to-R escaping of `{` and `|`; neither
failure parsed or executed project source. The final regex-free parser used
`startsWith()` and returned:

```text
R version 4.6.1 (2026-06-24)
test_parse=PASS
qmd_chunks=11
qmd_chunk_parse=PASS
```

The parser removed Quarto hashpipe option lines and parsed all 11 R chunk
bodies. It did not evaluate any chunk.

## Exact focused-test stop

The authorized source-only command was run without an HTML argument:

```text
Rscript tests/test_preparation07_report.R
```

It reached the focused assertions and returned exit status 1 with:

```text
Error: Missing statement: None of the Preparation 07
Execution halted
```

The literal occurs in the released pre-edit focused test and the current test.
It does not occur in either the released pre-edit QMD or the current QMD. The
accepted QMD instead preserves the scientific meaning through its existing
statements that the fixed display is illustrative only, none of it enters an
H01-H11 model, and there is no hypothesis-analysis handoff from Preparation
07. The authorized provenance implementation did not change those statements.

This is therefore a pre-existing stale visible-literal assertion, not a
failure of the sealed equivalence checks and not evidence of a scientific,
data, display, or provenance discrepancy. Order 26 does not authorize changing
that unrelated assertion or adding prose outside the bounded technical-
provenance section, so no repair was made and no additional test was run.

## Protected identities and held actions

The following protected identities remained exact after editing, parsing, and
the stopped test:

| Protected file | SHA-256 |
|---|---|
| Strict showcase verifier | `9a39ce7ab8e99187fdf14f2b750c3e3f9aa308de127e75a4923639dfb84d49b6` |
| Historical showcase manifest | `c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322` |
| Current site-context RDS | `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0` |
| Current site-context CSV | `7dc64cc5026947ef96d6e4ab112bb767414420be97817f022082248db68d7028` |
| Selected days | `36490be48ae13b5da8f7534af35652b90a3ee4b4c83ab595c5deb28c1f4c5481` |
| Eligible-day counts | `c80e41ddc53ad1d5a68d4dafd2adfc6c939b947b875d0286c6ebb6291fd833a4` |
| Selection settings | `807039893f3a464472ab490fac192d1d8e5b4882fc78129ac29ab4834d926121` |
| Paired source-data CSV | `15e12011effbdf8fdbf7835be235b7b50406838278d411df023e924e81bea1e4` |
| Durable PNG | `a35e8189bdbdb450411bfe7f71d52964c17e45a7a26fdb44e82776d201b00ff3` |
| Durable SVG | `5ad003220cb1d5a1d2b223af206f4a1e608b4e1fa0e695d656989dde62b0ea4a` |
| Profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Stale HTML | `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The lockfile identity and 603,493-byte size match the established preparation
baselines; its filesystem modification time remains 2026-07-31. The R startup
did not change it.

No scientific RDS value was opened or compared. The strict verifier was not
run. No builder, fixed-seed selection, artifact regeneration, model,
prediction, bootstrap, simulation, Shapley calculation, Quarto command, knitr
command, HTML check, or render occurred. Preparation 07 and every later render
remain held pending a separately bounded disposition for the stale focused-
test literal.
