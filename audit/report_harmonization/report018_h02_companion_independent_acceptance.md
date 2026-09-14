# REPORT-018 H02 companion independent acceptance

Date: 2026-08-20

Status: **ACCEPTED**

The H02 preparation-and-provenance companion is independently accepted for
its provenance reconciliation, targeted render integration, semantic table
repair, links, navigation, and visual display. The accepted H02 result page
remained byte-identical. H02 now has accepted result and companion pages, so
the REPORT-018 serial gate may proceed to the H03 result page.

## Independent identity and test replay

The owner completion record is
`audit/hypotheses/H02/report018_order39_companion_render/completion_record.md`,
SHA-256
`ae695391b57b357f5d98ff05af89063b732cbc19cdfb9c402071e3c2a312d149`.
Its 22-row owner evidence manifest is
`audit/hypotheses/H02/report018_order39_companion_render/owner_evidence_manifest.csv`,
SHA-256
`4e4a66bfd64f1245a82f1ed881c1b7cbefe575ad09f3c202967c4f6825f985f8`.

R 4.6.1 independently verified all 22 owner-manifest paths, SHA-256 values,
and byte counts, with unique paths and no manifest self-row. It also verified
all 59 unique rows in
`artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`, SHA-256
`afc7a2f5458628b6e5950a5539f4d7f1b5d1984ec3afb960b19c1e147c8d721b`.

The following four tests were independently rerun through the normal project
profile under R 4.6.1 and passed:

1. `tests/hypotheses/H02/test_h02_contract.R`;
2. `tests/hypotheses/H02/test_h02_reader_report.R`;
3. `tests/hypotheses/H02/test_h02_preparation_report.R`;
4. `tests/hypotheses/H02/test_h02_paired_placement_display.R`.

The accepted four-literal current-input reconciliation is confined to
`scripts/hypotheses/H02/h02_contract.R`, SHA-256
`48fef63abda50e1189b019254d56d588d539c40a984fde66502ec468878c72f0`.
The historical fit-time input record remains unchanged at SHA-256
`aa1c2c9b63cbe080ced3862de904921c0c6112ed5050844294b4138a63317548`.
No model, prediction, resampling, dominance allocation, or scientific
artifact was regenerated.

## Render and semantic acceptance

The companion authoring and build QMDs are byte-identical at SHA-256
`92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`.
The accepted companion HTML is
`_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`,
SHA-256
`966f5556a637aece91ef2e2905dcfea8d0d0587ff8d4d61c47e89e9106bbc253`,
613,001 bytes.

The semantic hook repaired 16 native gt tables with 80 generated IDs, 517
header references, and 597 reversible substitutions. The retained summary
and ledger reproduce at SHA-256
`1197a5304b16269ea54ce719dbda68cd0dfea276a287d0090b18a38d383af19d`
and
`dff487e183d6d82bce042ec0f3531e9b775f1873037ce59b9d491553478d78dd`.
Exact reversal recovers pre-hook HTML SHA-256
`91033fb081d4f359beea691c310b4a41cb2f85109204d536896f74f59c7000c5`.

Independent checks confirm the owner's 21 nonvisual PASS rows: 16 table
endpoints, four figure endpoints, one top-down Mermaid diagram, complete
captions and alt text, unique document IDs, resolved table-header and other
ID references, reciprocal result and companion links, active navigation,
the Supplementary information target, 22 result links to 18 unique
preregistration anchors, all nine country-coded sites, zero embedded errors,
and zero unresolved or forbidden internal links.

The result source and accepted result HTML remain byte-identical at SHA-256
`4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`
and
`736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`.

## Visual and process acceptance

The owner's 13-row visual audit passes at 1440 x 1000, 708 x 1000, and the
720 x 500 200-percent-equivalent viewport. A separate secure-loopback browser
replay independently confirmed the same display contract. The desktop page
had 1,425 px client and scroll widths. The narrow page had 693 px client and
scroll widths. The 200-percent-equivalent page had 705 px client and scroll
widths. No inspected view had page-level horizontal overflow or embedded
error output.

All 16 tables, four figures, the Mermaid diagram, captions, callouts,
navigation, links, wrapping, clipping, and overlap were inspected. The three
wide tables use contained horizontal scrollers at narrow width. The script-map
table's scroller was exercised from its left edge to its complete 144 px right
extent. All four exported PNGs pass at their native sizes. The Mermaid renders
at 642 x 626 px at narrow width, with an effective label size of approximately
6.92 pt and no clipping or overlap.

The optional favicon request returned HTTP 404 and is deferred as a
nonblocking site cosmetic observation under REPORT-018. The owner's loopback
server was stopped, and an independent `lsof` check found no listener on
`127.0.0.1:48739`. The independent replay used a separate server rooted
exactly at `_build/nathealth`, bound only to `127.0.0.1:48741`; it was also
stopped and a final `lsof` check found no listener.

The final build inventory contains 825 files, 302 directories, and zero
symlinks. The classified build delta is confined to the companion HTML, the
source-identical build QMD, normal search and sitemap updates, and two
source-identical companion downloads. Concurrent central-ledger changes were
coordinator-owned and are not attributed to H02.

## REPORT-018 transition

H02 result and companion integration is complete. No additional H02 language,
style, test-literal, or cosmetic cleanup loop is opened. The next serial
render target is the H03 result page, subject to its separately sealed order.
