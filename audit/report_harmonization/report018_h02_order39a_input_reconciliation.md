# REPORT-018 H02 order 39a input reconciliation

Date: 2026-08-20

Status: **ACCEPTED AS A PROVENANCE-ONLY LIVE-CONTRACT TRANSITION**

## Disposition

Order 39a resolved the restricted renv-cache startup problem and reached the
H02 companion's knitr setup. It then stopped, before target execution, because
`h02_validate_inputs()` found four live identities newer than the frozen H02
contract. The mismatch set is complete and predates orders 39 and 39a.

The current 30-minute inputs reconstruct all four frozen H02 main model frames
exactly. No H02 model refit, prediction, bootstrap, simulation, dominance
allocation, Shapley allocation, inferential update, or scientific artifact
regeneration is required. The smallest safe repair is to update the four live
hash literals in `scripts/hypotheses/H02/h02_contract.R`, while preserving the
historical fit-time inputs and their manifests as historical provenance.

## Stopped render state

The sole order-39a render attempt used the normal project profile and reached
knitr setup at cell 2 of 51 under R 4.6.1 and Quarto 1.9.37. It exited 1 at the
input validator. The fresh semantic directory
`/private/tmp/H02-order39a-semantics.pa61CA` is empty. The earlier order-39
semantic directory `/private/tmp/H02-order39-semantics.NAwzt6` is also empty.

The pre-render `_build/nathealth` inventory remains exact: 823 files, zero
missing paths, zero added paths, and zero content or byte-count changes. The
companion and result sources and HTML, profile, preparation manifest,
`.Rprofile`, `renv/activate.R`, and `renv.lock` retain their dispatch
identities. The authorized preparation-manifest helper remains unexecuted at
SHA-256
`3e69748ad3b3ef3dde7dcd0dc3c913d21971c1c5ef5098e44452d3f2f37111b1`.

## Accepted upstream transition

The later upstream change is the accepted METRIC-011 numerical-zero
normalization recorded in
`audit/decisions/l10_numerical_zero_normalization.md`, SHA-256
`23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`.
Its invariance summary, SHA-256
`34ddcd418be07d50484bad2b62411e6c8961788af0b45d0ff436708ed3d0c213`,
states that all 30-minute, hourly, and participant-level scientific values are
unchanged. The scientific cell changes are confined to eight daily L10 mean
values normalized from positive roundoff to exact zero.

The current submitted-manuscript identity is separately explained by accepted
REPORT-017 order 00b. That order changed only one internal link target in
`index.qmd`; reverse substitution reproduces the historical manuscript bytes.
Its verification record is SHA-256
`14be1395553e08e61697d231f62b6c5d27d31a8a0efa4c85dd299a5623eb1687`.

## R 4.6.1 equivalence audit

A read-only R audit sourced the existing H02 data construction functions,
loaded the current accepted 30-minute near-eye and chest inputs and temporal
links, rebuilt the two all-available and two paired-common H02 model frames in
memory, and compared each column with the corresponding frozen H02 RDS.

| Frame | Rows | Columns | Frozen SHA-256 | Result |
|---|---:|---:|---|---|
| near-eye, all available | 37,756 | 26 | `8420e7a5c1d1b89eda29807abf1c339c5d3b43095ae5d297ebed85f13f6de11e` | exact |
| chest, all available | 41,842 | 26 | `5826c426d127c096a381e4b894c514b95552672fa12b59b28d6fd26c9b655c90` | exact |
| near-eye, paired common sample | 29,786 | 26 | `4c69dc4219220662628377fe2d9e71195f65080409c300eedd48be64464238b1` | exact |
| chest, paired common sample | 29,786 | 26 | `a5ab949b605e7fb0730baea601b2fedecd469231435e97a34199ea4873a71c67` | exact |

For all four frames, column names, row counts, and every column value are
identical. The current base-data manifest independently reports `PASS` and the
exact current identities for both 30-minute inputs.

The audit ran with R 4.6.1, dplyr 1.2.1, readr 2.2.0, and digest 0.6.39. Its
temporary output identities are:

- frame comparison:
  `3310b5cafa4f37152a1e58816e32521ce6f2880f8e902b388098d81292c25526`;
- input identities:
  `5b951718f11f87b037dd9576026ac7457a9ac361b5f2b31dd9b1206b97a384bb`;
- manifest check:
  `913ab9847c70aff9c80e3cdae9e849a6d95ec76d43c2c512a90dd55ea7fcdaa4`;
- version record:
  `772166b707520d747e3c03366a2ecfaa8d553a2c72f01e451e848409131de636`.

The first temporary audit invocation reached and passed every frame comparison
but stopped at its final manifest-vector `identical()` assertion because one
vector retained names. The only correction was to remove vector names in that
temporary assertion and write the second output to a fresh directory. No
scientific calculation or project file changed between the two invocations.

## Prospective live contract

An in-memory prospective copy changed only these four hash literals:

| Input | Historical contract | Accepted live identity |
|---|---|---|
| near-eye 30-minute input | `afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5` | `85a927003c54821ae9ed5d9b4266e07f75488c743b570ec67b48a14ecfa88920` |
| chest 30-minute input | `01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2` | `b2c0290c3eff5ef5ae5e92af6d8c693043f3ad0409392e80652e97ffcac8ef15` |
| base-data manifest | `142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4` | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |
| submitted manuscript | `aa24170aa24cb6a39f2a1e3cf6d33ead9d1a20c6cfe2860674d20802ca28ec9e` | `86766c377e7ee1dcfea6b1ada8704b04320bbc231630c4044cd9c9d93aa0bf80` |

The prospective contract is SHA-256
`48fef63abda50e1189b019254d56d588d539c40a984fde66502ec468878c72f0`,
11,946 bytes. Reversing exactly those four substitutions reproduces the
current historical contract SHA-256
`76a72eb8a164f93756796ac593c76c09d5aff983167861ae39efac45974ee025`.
The complete unchanged H02 contract test passes against the prospective
contract under R 4.6.1.

## Preservation and next gate

The following remain frozen historical fit-time evidence and must not be
rewritten: `artifacts/06_model_data/H02/input_hashes.csv`, the frozen H02 model
frames, all fitted models, predictions, diagnostics, tables, figures,
scientific manifests, earlier REPORT records, and figure-replication input
manifests. The live contract transition does not claim that the current base
files produced those historical artifacts. It records that the current inputs
are scientifically equivalent for H02 and reconstruct the accepted frozen
frames exactly.

One consolidated continuation may now apply the four-literal live-contract
repair, run the unchanged contract test, execute one fresh H02 companion
target render, and finish the already authorized helper, manifest, semantic,
link, and visual integration. No H02 refit or other scientific rerun is
authorized.
