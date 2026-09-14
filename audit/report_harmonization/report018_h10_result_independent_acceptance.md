# REPORT-018 H10 result independent acceptance

Date: 2026-08-22

Status: `ACCEPTED_RESULT_PAGE`

## Independent disposition

The H10 result page is independently accepted after order 58 and its no-rerender order 58a completion. The only order 58a source transition was the exact reader-test caption correction. The corrected test ran once and passed. Order 58a did not invoke Quarto, rerender a page, execute a preparation test, change a QMD, alter an analysis, or recalculate a scientific result.

## Accepted identities

- Result QMD: `0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d`, 49,224 bytes.
- Result HTML: `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`, 359,702 bytes.
- Reader test: `dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af`, 25,803 bytes.
- Held companion QMD: `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`, 58,446 bytes.
- Normal profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`, 7,480 bytes.
- Owner acceptance record: `2dc529b968d0080e00e52a0c6af9a3f27f2089d6252d21022d648cfcd9f5d9c7`.
- Owner 30-row manifest: `68caeae3f4e473151ba0080812e35be5d471f63e89178b782509a543072ff532`.

## Independent R 4.6.1 replay

The independent checker reproduced all 30 owner-manifest identities, all 11 static checks, and all 22 visual observations. It confirmed 15 native `gt` tables, eight figures, 1,038 scoped table-header references, 26 rendered links to 24 targets, exactly six accepted historical Stage 3 transitions, and all 57 scientific assets. Pre-QA and post-QA build inventories are byte-identical. The corresponding protected inventories are also byte-identical.

The retained desktop, 708-pixel narrow, 200-percent-equivalent, and exact 170-mm figure observations pass. The loopback server and QA tab were closed, and no listener remains.

Independent checker:

`scripts/report_harmonization/check_h10_order58a_result_and_companion_preflight.R`

It returned:

```text
REPORT018_H10_RESULT_AND_COMPANION_PREFLIGHT=PASS checks=12 owner=30/30 prospective=269/269 tables=19 figures=2 headers=1050 build=4 protected=1 science=57 R=4.6.1
```

## Next serial boundary

The result page is accepted. H10 companion integration may proceed as the sole next serial target under a separately sealed order. H11 and every later target remain held.
