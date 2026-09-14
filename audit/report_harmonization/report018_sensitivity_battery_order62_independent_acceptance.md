# REPORT-018 sensitivity-battery independent acceptance

The sensitivity-battery reader target is independently accepted under Order
62.

## Accepted endpoints

- Source: `notebooks/sensitivity_battery.qmd`, SHA-256
  `d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70`.
- Reader HTML: `_build/nathealth/notebooks/sensitivity_battery.html`, SHA-256
  `875f53995f5f47ec30b630a5cf47edfef1d0fe925034d3fab4944be8c6c6b4be`,
  54,637 bytes.
- Profile: `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Lockfile: `renv.lock`, SHA-256
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

## Independent disposition

R 4.6.1 independently passes all 16 acceptance checks. The six historical
manifests contain 89 rows in total. Every row is live-exact except the
authorized held-to-current HTML transition and one stopped-check transition
whose sealed preimage remains preserved. The target was rendered exactly once
with Quarto 1.9.37. Its single R chunk remained nonexecuting.

The semantic hook returned `NO_GT` with zero tables, IDs, headers, or
substitutions. The accepted page has exactly one reader `main` element, the four
expected headings, no table or figure endpoint, no generated code output, no
duplicate document ID, and no rendered error element. All 44 internal links and
fragments resolve.

The bounded loopback review passed at 1440 x 1000, 708 x 1000, and 720 x 500.
The code disclosure was inspected open, navigation was exercised at narrow
width, all four served routes returned HTTP 200, and the browser console had no
warning or error. Six retained screenshots pass byte-signature and identity
checks. The in-app browser encoded them as JPEG while retaining the requested
`.png` filenames, which is recorded explicitly. The QA tab was closed, the
viewport was reset, the server was stopped, and a final `lsof` check found no
listener on `127.0.0.1:53762`.

The post-render and post-QA inventories are byte-identical: 1,180 build
members, including 871 files and 309 directories, and 12,991 protected files.
All current members rehash exactly and no symlink is present. The copied
decision resource is source-identical. No analysis, scientific artifact,
profile, package, lockfile, or unrelated target changed.

The two visual-sealer stops and the earlier post-render checker stop are
accepted as evidence-only harness classifications. They did not establish a
reader-page, source, or scientific defect.

## Coordination transition

The shared coordination row moved from
`active_order62_sensitivity_battery_target_render` to
`idle_sensitivity_battery_order62_independently_accepted_awaiting_final_corpus`.
The matrix transitioned from SHA-256
`7a6ce0ee4b2c97dea27d18ad3fed9759f580484ea046a2cf645ab5993f714842` to
`01b3438ff097c7ea31486f20932ec3fed72e2eac0361732ada3bedc69408d960`.
The separate final 37-page corpus rebuild and integrated audit remain pending.

Independent checker:
`scripts/report_harmonization/check_report018_sensitivity_order62_acceptance.R`,
SHA-256
`e2dc580ee8302b54f5b7472a5232b50957aacf55bd7899b7b5385fb745daf928`.

