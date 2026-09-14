# REPORT-018 H05 order 45a integrity-stop independent acceptance

Date: 2026-08-20

Disposition: **accepted as a bounded provenance/render-gate stop**

Independent R 4.6.1 verification reproduces the owner stopped record at
SHA-256
`7f474471b2c221e8e66f8b67e5cbfb1b583b30da8e158de78daeb53aa65ba07b`
and its 25-row non-circular manifest at SHA-256
`643931c04ff3b8ce421f36aa65c72a5ba1968c74fa45889a133afe9b7ec1bc27`.
All 25 paths, hashes, byte counts, and R-version fields are exact and unique.

The repaired input table proves exactly 16 direct `PASS` rows, one exact
`PASS_ACCEPTED_TRANSITION` row for the historical-to-current H01 contract,
and zero failures. Its 17-row by six-field metric-registry comparison is exact.
The following integrity table nevertheless requires all 17 verification codes
to equal the literal `PASS`, so its first status is necessarily false. This is
finding H05-45A-INT-001, a low-severity stale classification. It is not an
analytical or scientific discrepancy.

The sole Quarto invocation reached this check under R 4.6.1 and Quarto 1.9.37
and exited 1 before Pandoc or the semantic hook. The fresh semantic directory
is empty. The helper and preparation test were not executed. The complete
836-file build and 150-path protected inventories are byte-identical before
and after, with zero symlinks. The accepted H05 result, stale companion output,
profile, helper, test, manifest, lockfile, and all scientific artifacts retain
their sealed identities.

The smallest safe continuation may change only the first row of
`tbl-h05-prep-integrity-checks` so that:

1. the expected display is 17 accepted inputs;
2. the observed count includes exactly `PASS` and
   `PASS_ACCEPTED_TRANSITION`;
3. the status passes only when every code is one of those two accepted values;
4. the existing preceding 16-plus-one exact stop conditions remain unchanged.

After exact reverse and source checks, one fresh H05 companion target render,
the existing helper and test, semantic verification, and secure loopback QA
may run under a separately sealed order. No other source, scientific, result,
profile, package, lockfile, ledger, or page may change.

