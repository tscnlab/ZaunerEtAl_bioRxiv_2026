# REPORT-017 Phase 4 render order 00b verification

Date: 2026-08-13  
Scope: exact landing-page link repair and `index.qmd` target render only  
Status: **verified; DOC-001 remains open**

## Accepted inputs

- pre-edit `index.qmd`: `bde8b03095bc4d4a47a8398f4cf565b1d1aa6f1d1dc4989b81d91b9453898022`
- `_quarto-nathealth.yml`: `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`
- unchanged deviation-page source: `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`
- H01 companion source containing the target table:
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`

All accepted input identities matched before editing.

## Exact source change

Only line 546 of `index.qmd` changed. The visible link text and every byte of
the surrounding prose were preserved.

Before:

```text
[Research Question 1, Hypothesis 1](RQ1.qmd)
```

After:

```text
[Research Question 1, Hypothesis 1](audit/hypotheses/H01/H01_analysis_preparation.qmd#tbl-h01-prep-metric-contract)
```

The source has the same line count as before. The target substitution adds
exactly 71 bytes. Replacing the new target with `RQ1.qmd` in the complete
post-edit byte stream reproduces the accepted pre-edit SHA-256 exactly.

Post-edit `index.qmd`:

- SHA-256: `86766c377e7ee1dcfea6b1ada8704b04320bbc231630c4044cd9c9d93aa0bf80`
- bytes: 91250

## Target render

Quarto 1.9.37 ran exactly one command:

```text
quarto render index.qmd --profile nathealth --no-execute
```

The render completed through Pandoc without R or knitr execution. No other QMD
or full project was rendered.

Post-render landing page:

- path: `_build/nathealth/index.html`
- SHA-256: `d4c795294e45b1c7badc9cb69c3b4162f30348449c22517eecb2ab802e4c1871`
- bytes: 406136

## Link and anchor verification

Read-only R 4.6.1 and `xml2` checks establish that:

- the rendered landing page contains exactly one link to
  `./audit/hypotheses/H01/H01_analysis_preparation.html#tbl-h01-prep-metric-contract`;
- no rendered `RQ1.qmd` link remains;
- the target H01 companion HTML exists with SHA-256
  `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`;
- `tbl-h01-prep-metric-contract` occurs exactly once in that HTML;
- the landing-page link to the central preregistration-deviation page remains
  `./notebooks/preregistration_deviations.html`;
- the rendered deviation page remains byte-identical at
  `c033c1b8110e58375757e8ef8ac5c5d0dbf5f402a651454b247c1a622ded6880`;
- all accepted companion navigation additions remain present;
- the three removed internal pages and H06_daily remain absent; and
- the navigation, 86-anchor reader-link, and country-coded site-name contracts
  all pass.

The visible link text did not change, so the landing-page typography and line
geometry are unchanged by this repair.

## One-target preservation

Complete pre-render and final inventories were compared by path, byte count,
SHA-256, and file modification time.

- QMD/YML/YAML sources: 93 before and 93 after. Only `index.qmd` differs. The
  92 invariant rows are byte- and metadata-identical, with canonical inventory
  SHA-256 `c457710d02385d297d1502599035eede995b329a9151c2662db11ae044791f8c`.
- Nature Health build outputs: 827 before and 827 after. Only `index.html`
  differs. The 826 invariant rows are byte- and metadata-identical, with
  canonical inventory SHA-256
  `6f61d58d16753d448aa0ef0c48bb1bbc11ea1f1d3e9ced00d4e19d43b16a129a`.

Quarto transiently refreshed the landing-page timestamp in `sitemap.xml` and
the modification time of one byte-identical Bootstrap stylesheet. The exact
sealed pre-render sitemap bytes and both original modification times were
restored. The final `sitemap.xml` again has pre-render SHA-256
`33b60141a091d90c06553ba98ea0bb272f8c44518eb337d382ebcce50901146e`.
This makes the final build-output delta strictly `index.html` only.

`git diff --check` passes for `index.qmd`, the shared configuration, and the
preserved deviation-page source.

## Boundary

No claim, numerical value, table, figure, scientific artifact, ledger,
configuration file, other reader source, or other final build output changed.
No commit or push was performed. DOC-001 remains open pending the remaining
serial renders and final integrated audit.
