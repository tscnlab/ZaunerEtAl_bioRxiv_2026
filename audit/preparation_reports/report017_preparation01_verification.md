# REPORT-017 Phase 4 verification: Preparation 01

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Order: Phase 4 render order 02a, Preparation 01 only  
Branch: `rewrite/NH`

## Disposition

The Preparation 01 target render, focused source test, semantic HTML audit, link audit, and protected-input checks passed. Final-size visual inspection remains blocked because the in-app browser could neither navigate directly to the local `file://` target under its URL-safety policy nor attach to the exact target that was already open in the user's browser. No display defect was inferred from that limitation, but desktop and narrow-viewport acceptance was not claimed.

The source was not edited during this order. Preparation 02 was not rendered or otherwise started.

## Dispatch identities

| Item | Immediate pre-render SHA-256 | Immediate post-render SHA-256 | Result |
|---|---|---|---|
| `notebooks/preparation/01_import_state_alignment.qmd` | `74f32890d53fb39e38126764737486327cea0826d82ea3ea8e12a9cfbf1fb85a` | `74f32890d53fb39e38126764737486327cea0826d82ea3ea8e12a9cfbf1fb85a` | unchanged |
| `_quarto-nathealth.yml` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | unchanged |

The accepted handoff was read at SHA-256 `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640`. The environment-startup repair record used for this order is `audit/report_harmonization/report017_environment_startup_repair_verification.md`, SHA-256 `2b8a24115ce9e187abcf57f0f9b52d643c917db57d2cd8d08f3d65e96983f249`.

## Bounded execution review

Static inspection found 15 R chunks: one setup chunk and 14 display-table chunks. Searches for builders, production verifiers, import or write calls, model fitting, prediction, resampling, simulation, and other result-producing calls returned no matches. An empty `rg` result with exit status 1 was treated as the expected no-match pass.

The page has no empirical principal figure, and none was created. The accepted chunks read stored outputs, check identity or schema, and construct lightweight documentation displays. No preparation builder, production scientific verifier, hypothesis computation, model, prediction, bootstrap, simulation, or accepted-artifact regeneration was invoked.

## Render execution

The only Quarto command was:

```text
quarto render notebooks/preparation/01_import_state_alignment.qmd --profile nathealth
```

The command ran once, completed all 33 knitr steps, exited with status 0, and took 38.404 seconds. The runtime was Quarto 1.9.37 and R 4.6.1 (2026-06-24). Normal project startup was preserved: `R_PROFILE_USER` was unset, the repository `.Rprofile` activated renv 1.2.3, and the first library path was the project library `renv/library/macos/R-4.6/aarch64-apple-darwin23`. The user-owned renv sandbox cache was the second library path. No package was installed or updated, and `renv.lock` was not edited.

Relevant startup identities were:

| Item | SHA-256 |
|---|---|
| `.Rprofile` | `3f9d62fc3f1bf5888a09816101b705f9844ef4cd44ee5ad157f4168dac4af4d4` |
| `renv/activate.R` | `51798a35c2772b94b4a73ae7a7cc928975ff6e628a17bad1bc73d30defca82e6` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

## Rendered target

| Output | SHA-256 | Bytes |
|---|---|---:|
| `_build/nathealth/notebooks/preparation/01_import_state_alignment.html` | `03a18638500185707fa29b47981aeca4093d32f1d5efdcc8c54c5658df9c8465` | 371,295 |
| `_build/nathealth/search.json` | `7a3b2e48bcf53bb18da7e91c35cbe8c2fa987f7b18e027ab0e52957e0ede51e3` | 1,535,924 |
| `_build/nathealth/sitemap.xml` | `9aa9d28fa79b8529e65c4a7c7410ad13b61ddf3b6e3caff0ad5db372ebe2bebd` | 5,219 |

## Focused source test

Command:

```text
/usr/local/bin/Rscript tests/test_preparation01_report.R _build/nathealth/notebooks/preparation/01_import_state_alignment.html
```

The test ran under R 4.6.1 with normal project startup, exited with status 0 in 16.418 seconds, and reported:

```text
PASS: Preparation 01 source satisfies the bounded-render, gt-table, terminology, and provenance contract.
```

The test source had SHA-256 `0237de70ff1659326b99e068d134b01d1927536fc6a805548ff3749a1160a337`.

## Protected-input comparison

The current scoped read set contains 149 paths. The immediate pre-render check found 149 unchanged paths and zero mismatches. The immediate post-render check again found 149 unchanged paths and zero mismatches. Every stored scientific or preparation input in the page's read set was therefore unchanged.

| Record | SHA-256 | Rows |
|---|---|---:|
| `audit/preparation_reports/report017_preparation01_prerender_scoped_readset.csv` | `d27066db44dba439a092c9f09315ea96ac66de6615ca6f20a5d4e580eec1b78b` | 149 |
| `audit/preparation_reports/report017_preparation01_postrender_scoped_verification.csv` | `38fb7dc92eca109a9abfa7fe96297d237a8708d64537571db9ab49176c1cf633` | 149 |

This is a scoped preparation-input assertion, not a claim that the shared checkout was globally static. Concurrent downstream work outside the exact read set was not used as a gate.

## Semantic HTML audit

The audit passed with the following results:

- The exact page title was present.
- The information hierarchy contained 12 second-level headings in the expected order, including the automatically generated References heading.
- The render-boundary information note occurred once.
- The active navigation item occurred once and was labelled `01 Import and state alignment`.
- All 14 expected reader-facing tables were native `table.gt_table` elements with nonempty captions, nonempty column labels, and at least one body row.
- The 14 tables contained, in source order, 9, 6, 3, 6, 9, 7, 2, 6, 9, 7, 2, 5, 5, and 5 body rows.
- Seven source-note blocks were present. No `tab_footnote()` call or reader-facing table footnote was expected in this source.
- Country-coded labels were present for Borås (SE), Delft (NL), Dortmund (DE), Tübingen (DE), Munich (DE), Madrid (ES), Izmir (TR), San José (CR), and Kumasi (GH).
- Raw console, tibble, and kable output hits were zero.
- Internal identifiers and worker or coordinator terminology hits were zero.

## Link and navigation audit

The main content contained 12 links. All internal paths and anchors resolved. There were zero rendered hrefs containing `.qmd`, `file://`, `_build`, a build-directory path, or an absolute local filesystem path. The Preparation 01 navigation entry was active and uniquely identified.

## Final-size visual QA

Desktop and narrow-viewport inspection was attempted but not completed. The in-app browser rejected direct navigation to the local `file://` output under its safety policy. A read-only tab inventory confirmed that the exact rendered Preparation 01 page was already open, but the browser controller timed out while attaching to that existing tab. The temporary controlled blank tab was closed, and the existing user tab was left untouched.

Accordingly, table overflow, wrapping, clipping, final-size typography, callout layout, and link usability at desktop and narrow widths remain unverified. No source repair was made because the order prohibited source edits and required unresolved display QA to be returned as evidence.

## Final build delta

The build inventory contained 827 files before and after rendering. No file was added or deleted. Exactly three files changed in content:

| Path | Before SHA-256 | After SHA-256 |
|---|---|---|
| `_build/nathealth/notebooks/preparation/01_import_state_alignment.html` | `6c45e5d23a25808c74f60677f5e3873bfdb2926cc0bfc8a6a9f4411e8d0ddeec` | `03a18638500185707fa29b47981aeca4093d32f1d5efdcc8c54c5658df9c8465` |
| `_build/nathealth/search.json` | `797b7ffd3f0c002d9b9327ffe539a3846fe80508abf5c279e1232feb42b3310a` | `7a3b2e48bcf53bb18da7e91c35cbe8c2fa987f7b18e027ab0e52957e0ede51e3` |
| `_build/nathealth/sitemap.xml` | `81225707d58d848986845a332ae62e15485681f1afce1c06da39b589d3a9107c` | `9aa9d28fa79b8529e65c4a7c7410ad13b61ddf3b6e3caff0ad5db372ebe2bebd` |

Quarto touched the mtime of `_build/nathealth/site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min.css` without changing its bytes. Its SHA-256 remained `b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c`, its size remained 498,438 bytes, and its original mtime `1786606094` was restored. The final build comparison found zero metadata-only differences.

## Ownership and scientific-change evidence

No QMD, shared configuration file, script, test, scientific artifact, preparation artifact, manifest, decision, ledger, bibliography, lockfile, manuscript file, or downstream hypothesis output was edited by this render order. The only newly authored evidence files are confined to `audit/preparation_reports/`. Git may show the source and configuration as modified relative to the repository commit because they contained accepted pre-existing work at dispatch; their accepted byte identities remained unchanged throughout this order.
