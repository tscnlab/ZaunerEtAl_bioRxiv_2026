# REPORT-018 H10 order 59a companion independent acceptance

Date: 2026-08-22

Status: `ACCEPTED_RESULT_AND_COMPANION`

## Independent disposition

H10 result and companion integration is independently accepted after the
order 59a no-render recovery. The owner ran the preparation-manifest helper
exactly once after the file-state gate, obtained the truthful 269-row current
manifest, ran the strict preparation test exactly once, and completed the
already rendered companion's structural, semantic, link, protected-state, and
secure-loopback visual checks. Order 59a did not invoke Quarto, execute a QMD,
change either QMD or HTML endpoint, or recompute a scientific result.

## Accepted identities

- Result QMD: `0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d`, 49,224 bytes.
- Companion QMD: `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`, 58,446 bytes.
- Result HTML: `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`.
- Companion HTML: `dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9`.
- Preparation helper: `26619260657ec0cb1d7ac7614af9e3e349a524ee242dd5645b27e31f4cb142f0`.
- Current 269-row preparation manifest: `4ebb3e9a32a09f3b289920aea325fadf3eaf0f727087d457f3f568b910a39fe0`.
- Owner completion record: `cc4768d579ca48c2fbd3b2d4fd663e7f30bb2e4dfc9a7fc8c228d593ee8eee80`.
- Owner 114-row evidence manifest: `84ccc551255ffe366bd6dc6040f13ebd2f6530f2887440f266aed458885dc2ca`.

## Independent R 4.6.1 replay

The independent checker initially rehashed all 114 owner-manifest members. At
the final release audit it reproduced 113 live-exact rows plus the sole
authorized coordination-matrix transition from the sealed pre-dispatch
snapshot to the H10-closed and H11-released state. All 269 current
preparation-manifest members are live exact. Every manifest is unique and
non-circular. The checker reproduced 12 static checks, 20 visual observations,
and 10 loopback lifecycle checks. The page contains 19 native `gt` tables, two
figures, 1,050 scoped table-header tokens, 23 local links, and six fragments,
with zero duplicate document IDs. All 57 H10 scientific assets remain exact.

Desktop, 708-pixel narrow, 720 by 500 200-percent-equivalent, and exact
642-pixel figure checks pass. The build and protected inventories are
byte-identical before and after QA. The browser surface was closed, the server
was stopped, and no listener remains.

The durable checker is
`scripts/report_harmonization/check_report018_h10_order59a_and_h11_result_preflight.R`.
Its preflight returned:

```text
REPORT018_H10_H11_PREFLIGHT=PASS phase=preflight checks=13 H10_owner=113/114+matrix_transition H10_manifest=269/269 H11_stage3=2_transitions H11_preparation=4_transitions tests=2/2 tables=15 figures=8 science=193 build_resources=34 R=4.6.1
```

## Final boundary

H10 result and companion are closed under REPORT-018. No H10 source, test,
helper, current or historical manifest, HTML, profile, or scientific artifact
requires further mutation or rendering. H11 result may proceed only under its
separately sealed result-only order. The H11 companion and sensitivity battery
remain held.
