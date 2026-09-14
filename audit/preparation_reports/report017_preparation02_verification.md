# REPORT-017 Phase 4 verification: Preparation 02

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Order: Phase 4 render order 03, Preparation 02 only  
Branch: `rewrite/NH`

## Disposition

The bounded Preparation 02 render, focused R test, protected-input gate, native-table audit, scientific-text assertions, and main-content link audit passed. Final visual acceptance did not pass. Desktop inspection exposed three duplicated Quarto cross-reference prefixes in visible prose:

- `Table Table 1` for the coverage-rule reference;
- `Table Table 3` for the site-coverage reference; and
- `Table Table 6` for the sample-flow reference.

The source places the word `Table` immediately before each `@tbl-*` reference, while the rendered cross-reference already supplies `Table N`. The exact rendered HTML evidence occurs at lines 461, 1512, and 3249. The corresponding source occurs at lines 511, 562, and 667 to 668.

The stop-on-display-defect rule was applied. The source was not edited, the 708 by 1000 narrow-viewport pass was not started, and Preparation 03 was not rendered or otherwise started. A separate source-repair authorization and a fresh targeted render are required.

A full-page link inventory also found that the global sidebar link `../../supplementary_information.html` has no target in the current nathealth build. The target was not generated because this order prohibited a full-project or supplementary-information render. The eight main-content and page-navigation links all resolve, including DEV-055. This missing global navigation target remains separate from the three duplicated reference labels.

## Dispatch identities

| Item | Immediate pre-render SHA-256 | Final SHA-256 | Result |
|---|---|---|---|
| `notebooks/preparation/02_coverage_sample_flow.qmd` | `1bc72ab367443ef48727c7069ad9f58d950b00264e7ea78b5a72d05b4a979c50` | `1bc72ab367443ef48727c7069ad9f58d950b00264e7ea78b5a72d05b4a979c50` | unchanged |
| `_quarto-nathealth.yml` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | unchanged |
| `tests/test_preparation02_report.R` | `1a6fd5fb83fdefa7e7862c055fee71b6d6b9508a59b0a434b20936b51cea52c3` | `1a6fd5fb83fdefa7e7862c055fee71b6d6b9508a59b0a434b20936b51cea52c3` | unchanged |

The accepted handoff was read at SHA-256 `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640`.

## Bounded execution review

Static inspection covered the complete 793-line QMD and all 12 R chunks: one setup chunk and 11 native gt display chunks. Searches for builders, production verifiers, source or system execution, writes, downloads, model fitting, prediction, resampling, simulation, bootstrap, and Shapley calls returned no matches. The empty `rg` result with exit status 1 was the expected no-match pass.

The accepted executable code reads stored coverage outputs, checks manifest identities and required columns, and forms compact descriptive displays. No coverage builder, production scientific verifier, model, prediction, simulation, bootstrap, or accepted-artifact regeneration was invoked. Preparation 02 has no empirical principal figure, and none was created.

## Runtime and render

The only Quarto command was:

```text
quarto render notebooks/preparation/02_coverage_sample_flow.qmd --profile nathealth
```

The command ran once, completed all 27 knitr steps, exited with status 0, and took 40.496 seconds. The runtime was Quarto 1.9.37 and R 4.6.1 (2026-06-24). Normal project startup was retained: `R_PROFILE_USER` was unset, the repository `.Rprofile` activated renv 1.2.3, and the first library path was `renv/library/macos/R-4.6/aarch64-apple-darwin23`. The existing user-owned renv sandbox cache was the second library path. Installed versions used for verification included gt 1.3.0, knitr 1.51, and xml2 1.6.0.

No package was installed or updated. `renv.lock` was not edited.

| Startup or configuration input | SHA-256 |
|---|---|
| `.Rprofile` | `3f9d62fc3f1bf5888a09816101b705f9844ef4cd44ee5ad157f4168dac4af4d4` |
| `renv/activate.R` | `51798a35c2772b94b4a73ae7a7cc928975ff6e628a17bad1bc73d30defca82e6` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |
| `_quarto.yml` | `44e4a7435494d570baca6e7b0de75b15be015a52c811c076dd2b8b959d70f59c` |
| `styles.css` | `557cf99b617ba158611d5326a76716c871f7373357e11d0295012600c0e6994b` |

## Rendered outputs

| Output | SHA-256 | Bytes |
|---|---|---:|
| `_build/nathealth/notebooks/preparation/02_coverage_sample_flow.html` | `0f3307775eac905a7c2ffb34a46d15ae9e85e237e293553f2e3a60c204305c26` | 313,926 |
| `_build/nathealth/search.json` | `edd628df4791c1c98e39a6a38066f24f1969ea1967e60621cb6a3c2508f62dd0` | 1,535,476 |
| `_build/nathealth/sitemap.xml` | `5eab7c792ed5e055eecbd3329e2fb4ce85efa140f3a37d0b4505ba655ffcffcd` | 5,219 |

## Focused R test

Command:

```text
/usr/local/bin/Rscript tests/test_preparation02_report.R _build/nathealth/notebooks/preparation/02_coverage_sample_flow.html
```

The test ran under R 4.6.1 with normal project startup, exited with status 0 in 16.495 seconds, and reported:

```text
PASS: Preparation 02 source satisfies the bounded-render, terminology, gt-table, and provenance contract.
```

The focused test did not detect the duplicated visible `Table Table N` labels. That defect required inspection of the rendered page.

## Protected-input comparison

The exact current Preparation 02 scoped read set contains 32 rows. It includes the source, project environment and Quarto configuration, shared preparation contracts, site display registry, coverage manifest and all expanded output and input members, and the three described production or verification modules.

The immediate pre-render check found 32 unchanged paths and zero mismatches. The immediate post-render and post-loopback checks each again found 32 unchanged paths and zero mismatches.

| Record | SHA-256 | Rows |
|---|---|---:|
| `audit/preparation_reports/report017_preparation02_prerender_scoped_readset.csv` | `ea8f3d2e6684c4c4170db154c96a26cdf5a3f5a28d8433c7bf5f0dd9a418bdb8` | 32 |
| `audit/preparation_reports/report017_preparation02_postrender_scoped_verification.csv` | `adaf4aac8daa4ce6376a21300651c82f0de9511bb48d49e7f174c46321d4f84c` | 32 |
| `audit/preparation_reports/report017_preparation02_final_scoped_verification.csv` | `adaf4aac8daa4ce6376a21300651c82f0de9511bb48d49e7f174c46321d4f84c` | 32 |

Every stored scientific or preparation input in the page read set remained unchanged. This is a scoped assertion, not a claim that the shared checkout was globally static.

## Semantic HTML audit

The final semantic audit passed:

- The exact page title and all 10 second-level headings appeared in the accepted order.
- Exactly one render-boundary callout appeared with the accepted limitation text.
- All 11 expected displays were native `table.gt_table` elements with one nonempty caption, nonempty column labels, and the expected body-row and source-note structure.
- The exact 50% hourly threshold, 30 of 60 rule, 80% daily threshold, 1,152 of 1,440 rule, retained participant-day counts, eligible minute counts, direct-rule counts, and flat-zero count were present.
- All nine country-coded site labels were present.
- Raw tibble, console, error, and internal workflow output was absent.
- The Mermaid overview and caption were present.

| Table | Headers | Body rows | Source notes |
|---|---:|---:|---:|
| Coverage rules | 3 | 6 | 0 |
| Overall coverage | 3 | 13 | 0 |
| Site coverage | 8 | 17 | 0 |
| Daily distribution | 3 | 5 | 0 |
| Missing or unusable periods | 7 | 10 | 1 |
| Sample flow | 6 | 20 | 0 |
| Validation | 3 | 6 | 0 |
| Manifest identity | 5 | 1 | 1 |
| Producing scripts | 2 | 4 | 0 |
| Artifacts passed forward | 3 | 7 | 0 |
| Render environment | 2 | 5 | 0 |

## Links and navigation

The main content and page-navigation region contained eight internal href occurrences, all unique. All eight files and anchors resolved. There were zero internal `.qmd`, `file://`, `_build`, build-directory, or absolute-local hrefs in this region. The active sidebar entry occurred once and was labelled `02 Coverage and sample flow`.

The DEV-055 link occurred once, had visible text `DEV-055`, rendered as `../../notebooks/preregistration_deviations.html#dev-055`, and resolved to the `dev-055` anchor in `_build/nathealth/notebooks/preregistration_deviations.html`. That target had SHA-256 `c033c1b8110e58375757e8ef8ac5c5d0dbf5f402a651454b247c1a622ded6880`.

The broader global-navigation audit found one missing rendered target: `../../supplementary_information.html`. No repair or broader render was attempted.

## Loopback visual QA and teardown

Preflight found 827 files under `_build/nathealth` and no symlink. The temporary server command was:

```text
python3 -m http.server 0 --bind 127.0.0.1 --directory /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth
```

The server was rooted exactly at `_build/nathealth`, bound only to `127.0.0.1`, selected port 60597, and ran as PID 33788. It started at `2026-08-13T10:53:58Z`. The exact review URL was `http://127.0.0.1:60597/notebooks/preparation/02_coverage_sample_flow.html`.

At the 1440 by 1000 desktop viewport, the following passed before the stop condition was reached:

- title, navigation, opening prose, and the gap-timing-unaware explanation were readable;
- the Mermaid diagram occupied 1,148.5 by 150.8 CSS pixels, and its displayed single-line node text measured 16.3 CSS pixels in height;
- all 11 tables used 13 px cell type and had no horizontal wrapper overflow in DOM geometry;
- Tables 1 through 6 were visually sampled without clipping, overlap, or distorted type; and
- the DEV-055 link was legible.

The visual sample then exposed the three duplicated table-reference labels described above. Inspection stopped without repair. Tables 7 through 11, the callout at its final scroll position, and the 708 by 1000 narrow viewport therefore remain visually unverified. No overall visual PASS is claimed.

The server was interrupted immediately after browser cleanup. It stopped at `2026-08-13T10:56:59Z`. A final `lsof` check found no listener on port 60597, and PID 33788 no longer existed. The combined check returned exit status 1 with empty listener and process output, which is the expected no-match result. The server log contained successful GET requests for the exact page and its static assets plus a non-content `/favicon.ico` 404.

The full 827-file rendered-site inventory was byte-for-byte and mtime-for-mtime identical before and after loopback QA.

## Final build delta

The build inventory contained 827 files before and after the target render. No file was added or deleted. Exactly three files changed in content, and no metadata-only difference remained:

| Path | Before SHA-256 | After SHA-256 |
|---|---|---|
| `_build/nathealth/notebooks/preparation/02_coverage_sample_flow.html` | `54f0c716963d5ce5736eb2b10817cee78c7a733762cacc9eb65005d7dcb452d9` | `0f3307775eac905a7c2ffb34a46d15ae9e85e237e293553f2e3a60c204305c26` |
| `_build/nathealth/search.json` | `7374fb9fc7e20ac83f0a70d32dfec3d3f8eb592cf7f4af19a5dc880ec9f33ddc` | `edd628df4791c1c98e39a6a38066f24f1969ea1967e60621cb6a3c2508f62dd0` |
| `_build/nathealth/sitemap.xml` | `1126d501ee279da25eed02854986453631888888a2715dc1dd14d8fdd248e8b5` | `5eab7c792ed5e055eecbd3329e2fb4ce85efa140f3a37d0b4505ba655ffcffcd` |

No CSS or other asset mtime required restoration.

## Ownership and scientific-change evidence

No QMD, shared configuration file, script, test, scientific artifact, preparation artifact, production manifest, decision, ledger, bibliography, lockfile, manuscript file, or hypothesis output was edited during this order. The only newly authored files are the scoped verification evidence under `audit/preparation_reports/`. Existing source and configuration modifications shown by Git predated dispatch and retained their accepted byte identities.

