# H06_daily pre-commit whitespace normalization

- Date: 2026-08-13
- Scope: H06_daily-owned source and provenance files only
- Authorization: coordinator pre-commit disposition after the author's commit
  request
- Scientific computation: none

`git diff --cached --check` identified trailing spaces used for Markdown hard
breaks and one extra blank line at the end of several task-owned files. The
metadata lines were converted to ordinary Markdown lists, and the extra final
blank lines were removed. No model, model frame, estimate, interval, p-value,
multiplicity field, diagnostic value, table value, figure, or scientific prose
was changed.

The 18 direct before-and-after identities are stored in
`H06_daily_precommit_whitespace_normalization.csv`. Because earlier H06_daily
manifests and focused tests pinned several of those files byte-for-byte, the
bounded R reseal updated only corresponding checksum, byte-count, preservation,
and exact embedded checksum fields. The complete dependency closure is stored
in `H06_daily_precommit_whitespace_reseal_manifest.csv`: 18 direct files and
140 dependent identity records.

The direct-file ledger also records a canonical SHA-256 comparison after
removing trailing whitespace, final blank lines, Markdown list markers used to
replace hard breaks, and exact checksum tokens updated by the reseal. All 18
canonical comparisons are identical. The focused verifier is
`tests/hypotheses/H06_daily/test_h06_daily_precommit_whitespace_normalization.R`.

The accepted Stage 3 and Stage 4 reader QMDs and rendered HTML files are
excluded from the rewrite and remain byte-identical. Generated scientific
artifacts and all substantive analytical values remain unchanged.

The normalization verifier, Stage 3 reader verifier, Stage 4 preparation
verifier, Stage 4 acceptance verifier, and exploratory joint-context verifier
all pass under R 4.6.1 after the reseal.
