# REPORT-018 H09 order 57c rendered-stop independent acceptance

Date: 2026-08-22

Disposition: `ACCEPTED_RENDERED_NO_RERENDER_FINALIZED`

## Scope and authority

This record independently adjudicates the fail-closed H09 companion stop after the sole order 57c render. The audit was read-only with respect to H09 source, science, current manifests, tests, helper, profile, lockfile, result page, and rendered companion. It used R 4.6.1 for the source replay and all consequential identity, manifest, semantic, and protected-state checks. Secure loopback browser QA used the existing fresh companion HTML. No Quarto command, helper execution, scientific computation, broad manifest rebuild, source repair, or second render occurred.

The owner stop is accepted exactly at:

- `audit/hypotheses/H09/report018_order57c_companion_retry/ORDER57C_FAIL_CLOSED.md`, SHA-256 `87f92fe75d8c7378275ec5a51147ae580166f1ebc228ce7ae59f98adc09b3bd4`, 5,195 bytes.
- `audit/hypotheses/H09/report018_order57c_companion_retry/order57c_fail_closed_evidence_manifest.csv`, SHA-256 `8090069f94b1cf891fd7644c53f161ab11ec7958be21c7d86a1293974e13b63c`, 19,010 bytes, 63 of 63 members exact, unique, and non-circular.

## Accepted endpoints

- Companion QMD: `audit/hypotheses/H09/H09_analysis_preparation.qmd`, SHA-256 `394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f`, 51,736 bytes.
- Companion HTML: `_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html`, SHA-256 `09b604b011ef14c138c15720b419a9ca200e15f71ce3e40a9b85c23f6803f96d`, 631,401 bytes.
- Current preparation manifest: `artifacts/12_manifests/H09/H09_preparation_report_manifest.csv`, SHA-256 `90a47a6070a692d0089ef68f821b781998428f189d2718e12a8cdda046868ae2`, 158,291 bytes, 553 of 553 live-exact rows.
- Accepted result QMD and HTML: `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6` and `901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16`.
- Profile and lockfile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` and `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

## Independent adjudication

### Current preparation manifest

The helper's 553-row output is truthful and complete. Relative to the 554-row pre-helper inventory, the audit found 535 byte-identical common paths, two expected target transitions, 17 expected source-side removals, and 16 canonical page-asset additions. The manifest is live-exact, unique, excludes itself, and excludes order 57c evidence. The helper must not be rerun for this finalization.

### Canonical-output cleanup and build synchronization

Quarto's removal of the historical source-side companion HTML and its 16 support files is accepted canonical-output cleanup. All 16 support files have one source-identical counterpart under `_build/nathealth`. The build inventory changed from 851 to 871 files with exactly four expected changed paths and 20 expected additions, zero missing paths, and zero symlinks. The four changed paths are the companion HTML, source-identical build QMD, `search.json`, and `sitemap.xml`. The 20 additions are the 16 canonical page assets and four linked source-identical provenance resources. This is target-owned synchronization, not scientific or reader drift.

### Semantic repair

The semantic repair is exact and reversible. The accepted post-hook page contains 19 native `gt` tables, 102 repaired IDs, 591 `headers` attributes, and 693 substitutions. All 831 header tokens resolve exactly once to an intended `th` in their own table, and there are no duplicate document IDs.

The three substitutions beyond the held-page replay are structurally valid. They are the net result of six additional header references in the accepted six-row reader-manifest table and three fewer header references in the accepted nine-row key-output table. Raw reversal recovers the pre-hook HTML exactly, and reapplication recovers the accepted companion HTML exactly. No semantic defect is present.

### Source, links, privacy, and protected state

All 22 R chunks parse and source under R 4.6.1. The immutable Stage 3 manifest reconciles as exactly 87 live rows plus 19 accepted historical identities. The page contains the exact source-ordered 19 tables, one figure, and one top-down Mermaid diagram. All captions and the figure alt text are nonempty. All 23 source-link occurrences and 25 rendered local links resolve, including fragments. No embedded error, unresolved reference, or privacy token was found.

The protected inventory reconciles as exactly 524 historical-exact paths, 17 accepted canonical-output removals, and four accepted target transitions. The historical preparation test remains byte-identical and is not executed or edited here. Its three stale assumptions are classified as REPORT-018 history: hard-coded internal HTML result links and absence of the active profile. This classification fails on any additional historical mismatch.

## Visual acceptance and teardown

Secure loopback QA passed at 1,440 by 1,000, 708 by 1,000, and 720 by 500 200-percent-equivalent viewports. The 19 tables, figure, top-down Mermaid, source links, result navigation, code disclosure, captions, and narrow layout were complete and readable. The page had no horizontal overflow, clipping, overlap, missing content, or browser-console warning or error. The exported figure displayed completely at 642 by 480 pixels in the narrow view. The companion, result, and representative source-data endpoints returned HTTP 200.

The server was bound only to `127.0.0.1:49321`, the QA tab was closed, the viewport was reset, the server exited after `SIGINT`, and a final listener check found no listener. A post-QA R 4.6.1 replay reproduced the complete audit and all accepted endpoint identities.

## Final boundary

The H09 result and companion are accepted under REPORT-018. No H09 source, test, helper, current or historical manifest, HTML, profile, lockfile, scientific artifact, or result page requires mutation. No rerender is authorized. Historical order 57 through 57c evidence remains immutable. Any later target requires its own serial release.
