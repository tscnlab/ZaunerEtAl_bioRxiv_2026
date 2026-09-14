# Order015a verification handoff

14 September 2026. Harmonizer. Status: **browser acceptance pending independent classification**, not an unqualified visual PASS. The existing SVG-based candidate was verified without rebuilding or modifying it. No production release is requested or exercised by this handoff.

Project root is `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026`. Recovery root is `audit/report_harmonization/final_site_a4_delta_2026_09_14/verification_recovery_015a/`. Relative evidence references below resolve within its `evidence/` directory.

## Preserved candidate and completed nonbrowser checks

The original Order015 build remains historically stopped at its ordering assertion. Its 959-member failure manifest and separate seal, all 961 original files, all 13 original helpers, the original eleven-helper checkpoint, and started packaging marker remain exact. The recovery made no second candidate and no candidate writes.

The candidate still has 914 files: the six exact proposed postimages, 908 unchanged files, no additions or removals, and all 35 report pages unchanged. `website_promotion_manifest.csv` binds the six identities; `seven_backup_manifest.csv` binds all seven live preimages. The live 914-file site and live corpus remain unchanged. The prospective corpus remains a two-HTML-hash-cell change only. This handoff is not a production promotion.

| Check | Observed result |
| --- | --- |
| Complete static verifier | 53,724 PASS; 942 search records, 37 routes, exactly four inherited font exceptions, 19 native table downloads, 20 revision rows |
| R content reconciliation | 75 PASS |
| Targeted R checks | 15 PASS for index and 15 PASS for Supplementary Information |
| GET/HEAD download verification | All 22 resources returned the exact expected identities |
| Single post-teardown protected closure | 4,617 exact file-hash checks; live 914 and candidate 914 exact |
| Post-teardown release/original-package guards | 1,096 exact checks; original 961 preserved; additions confined to the recovery prefix |

R checks used R 4.6.1, xml2 1.6.0, digest 0.6.39 and jsonlite 2.0.0. Commands, accepted inputs, hashes and session information are recorded in `content_R_provenance.txt`, `content_R_sessionInfo.txt` and the targeted session files. No scientific estimates were calculated, reinterpreted or refitted. Python handled bytes, paths, HTTP and evidence serialization only.

## Browser observations

One read-only GET/HEAD server served only the unchanged candidate at `127.0.0.1:56572`, after the full symlink preflight. The supported in-app browser inspected index and standalone Supplementary Information at 1440 x 1000, 708 x 1000 and 390 x 844.

The six revised endpoints, Tables S4 and S7 and Figures S15 to S18, were inspected at all six route/viewport combinations. The complete S8 SVG, its panels and caption were inspected, not a cropped composite. S2 was preserved on both routes and Table 2 on index. Wide-table left/right edges, notes, captions and horizontal scrolling were inspected. Phone SVGs remain complete, although dense artwork labels require enlargement. The accepted S2 secondary typography and S8 internal whitespace remain unchanged.

Representative menu, Contents, search and download-utility interactions are enumerated in `browser_observations.json`. Contents navigation and phone search navigation demonstrably worked. These observations do not imply every navigation control was activated in every route/viewport combination.

The archive contains **131 exact, already-inspected CUA JPEG screenshots and 63 CUA output records**. `browser_capture_manifest.csv` records each image's bytes, SHA256, capture time, within-call position, corresponding metadata, and an observation ID where unambiguous. `browser_tool_output_index.json` includes the full recorded DOM bounds and action evidence. The separately exported 117-row index starts after the earlier browser-binding recovery; the first desktop captures remain in the complete screenshot manifest. No screenshot was edited, resized, cropped or re-rendered. The initial evidence-serialization parse error and exact-preserving continuation are recorded in `browser_archival_first_attempt.txt`; no verifier or browser check was rerun for that correction.

### B1: desktop search overflow, pending independent classification

At 1440 x 1000, search for `chronotype` returned eight matching documents. The result panel extended beyond the right edge: left 1215.25, right 1615.25, width 400, top 49, bottom 699, height 650. Document scroll width was 1615. Inline positioning was `top: 115px; left: 1215.25px;`.

Exact screenshot: `browser_captures/2026-09-14T152223140Z_call_kVh8oHnRGQGQDxRWgRLOcjL4_2.jpg`, SHA256 `644b840c45071c87389db24fb48b6e5508f9ecd28c8248fb87589b96e27d3a12`. Exact DOM bounds: `browser_captures/2026-09-14T152253204Z_call_lvevbBLjGrRN5EvLext0OqXg.json`.

Harmonizer did not start an accepted-baseline browser comparison. Coordinator subsequently reported independently reproducing the same bounds on accepted live, with a fitting mobile panel. That reported classification is distinguished from this task's observations and awaits its durable independent record.

### B2: ordinary Results-link activation, negative candidate observation preserved

The raw candidate contains `<a href="#fig-s15">Supplementary Figure S15</a>` and the corresponding S16, S17 and S18 fragment links. At the required loopback origin, the runtime S15 anchor became an absolute link with `target="_blank"`, `rel="noopener"` and `data-original-href`.

After the candidate S15 pointer activation, the URL remained `http://127.0.0.1:56572/#person-level-correlates-are-selective`. **The tab list was checked, not merely the same-tab URL: it contained only tab 4**, both immediately after the click and in the next read-only observation. The S15 target remained far below the viewport at x 215.5, y 47800.1953125, width 849, height 625.8515625.

The historical capture ID `I1440-S15-activated` is misleading and must not be counted as a destination success. Its screenshot shows Results, not S15: `browser_captures/2026-09-14T151827995Z_call_QabxB1qFWR96nSCm6P6mu1Rb_1.jpg`, SHA256 `8b8682af83ed8458ac1522d3bca283fa8f83d591df401067b35f2516e9455053`. The matching JSON records the immediate URL and tab list; `browser_captures/2026-09-14T151840861Z_call_8pbwObnWM4zlAweNSzZQYSdc.json` records the second tab list and runtime anchor.

The source mechanism is **shared generated Quarto code, not browser injection**. The 1,310-byte handler beginning at accepted-live index line 11181 and candidate line 11174 is identical, SHA256 `8ced769c9ccd7d2e301b2ea57979822416f20a9dab2e291d5099662316ab039f`. It recognizes the published site URL and `localhost`, but not `127.0.0.1`, and adorns non-navigation links with `target="_blank"`. Exact raw anchors, handler text and source hashes are in `browser_link_source_evidence.json`.

Coordinator subsequently reported a successful accepted-live S15 click opening a new tab, while the original tab stayed unchanged. This is useful independent evidence, but it does not retroactively turn the candidate's recorded no-new-tab observation into pointer-link success. The four destinations were separately opened and visually inspected on both routes at all widths. Working Contents/search navigation and those direct destination checks are explicitly separate from ordinary pointer-link activation. No claim is inferred from the earlier timed-out link batch.

### Console and inherited qualifications

The supported console-log API returned empty arrays at 15:49:28 UTC and 15:50:26 UTC, with a requested limit of 1,000 each. This does not prove a complete error-free historical console across earlier navigations. Exact responses are archived in the corresponding CUA JSON records.

The accepted Word S18 converter footnote/right-edge qualification remains. No new Office conversion or Word visual acceptance is claimed. No source, artwork, SVG payload, typography, table value, Results claim or display order was changed in recovery.

## Teardown and scope

The exact preview process, PID 36162, was confirmed before SIGTERM and exited 0 at 15:51:07 UTC. A permission-correct socket check at 15:51:27 UTC returned `ECONNREFUSED` (61) on port 56572, not a sandbox-denied result. Task-created tab 4 was closed; the task-browser tab list was empty. The viewport override was reset and 1280 x 720 observed. No alternate browser, policy bypass, second server or baseline session was started by Harmonizer.

The single final protected closure completed at 15:59:18 UTC and the original/release guards at 15:59:19 UTC, both exact. Evidence is in `post_closure_summary.json`, `post_protected_checks.csv`, `post_live_inventory.csv`, `post_candidate_inventory.csv`, `post_recovery_guard_summary.json` and `post_recovery_guard_checks.csv`.

The pre-checkpointed `finalize.py` was not invoked because its all-scoped-checks-PASS requirement would misstate the unresolved browser findings. It remains byte-identical. This return uses an explicitly pending non-circular manifest and separate seal, not an unqualified completion claim. All original/new helper pins remain exact. Writer and scientific tasks were not woken. Candidate writes, live writes, builds, renders, commits and uploads are all zero. Any subsequent acceptance or six-file production replacement plus prospective-corpus update remains a separate Coordinator decision and release.
