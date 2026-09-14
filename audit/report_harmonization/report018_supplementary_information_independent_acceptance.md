# REPORT-018 Supplementary information independent acceptance

Date: 2026-08-20

Disposition: **INDEPENDENTLY ACCEPTED**

## Accepted endpoint

The unchanged static source was rendered exactly once with the released
command:

```text
quarto render supplementary_information.qmd --profile nathealth
```

The render completed with exit status 0 under Quarto 1.9.37 and R 4.6.1. No
knitr execution or scientific computation occurred. The configured semantic
hook returned `NO_GT`, with zero tables, zero ID changes, and zero header
changes.

| Artifact | SHA-256 | Bytes |
|---|---|---:|
| `supplementary_information.qmd` | `8d013e4d37ca5ff438988e82907a26d65b98a9a47cc2d62ec3ddcd0e2b3862fa` | 993 |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` | 7,480 |
| `_build/nathealth/supplementary_information.html` | `a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb` | 49,234 |
| `audit/report_harmonization/phase4_corpus_manifest.csv` | `bd3e06250bd981ed6ebadc3708f7dcc393c7373e738e0994e5857411eeb3fc6f` | 11,937 |

This accepts successful integration of the current Supplementary information
outline. It does not accept the outline as the final journal Supplementary
Information narrative.

## Independent verification

The independent R 4.6.1 checker
`scripts/report_harmonization/check_report018_supplementary_acceptance.R`,
SHA-256
`3cdcb23cbd325f05983efeaa304bf9fdd7fb8dd47ffe3d0b22dabd84403b7ca8`,
passes. It reproduced:

- 30 live-stable owner-manifest members and the separately classified
  execution-time coordination-matrix row;
- all 16 render-execution fields, including exactly one command and `NO_GT`;
- the exact title and 20 source headings, with zero table, figure, error,
  warning, or stderr nodes;
- 60 of 60 internal links resolved inside the retained site, with all 124
  links classified by origin;
- 17 of 17 protected identities unchanged before render, after render, and
  after visual QA;
- the complete six-entry allowed build delta and byte-identical post-render
  and post-QA build inventories;
- 37 of 37 reader-source identities and 37 of 37 expected HTML identities in
  the rebuilt corpus manifest; and
- the exact execution-time and coordinator-resealed order identities without
  rewriting the historical dispatch record.

The existing R 4.6.1 navigation, reader-link, and country-coded site tests
were independently rerun and pass. They cover all 37 reader-facing QMD
sources and all 86 registered deviation anchors.

## Build and preservation disposition

The pre-render inventory contained 822 files, 302 directories, and no
symlinks. The post-render inventory contains 823 files, 302 directories, and
no symlinks. Content changes are limited to:

- the new Supplementary target HTML;
- the expected `search.json` refresh; and
- the expected `sitemap.xml` refresh.

One Bootstrap CSS file and two directories had allowed mtime-only changes.
There is no unclassified content change. The post-render and post-QA build
inventory identity is
`c2ab9a69dca6f4ecf890312f0ea65fe788ab07e834dbac2ce1f4fff3a27c8c1c`.
The protected-pin inventory identity is
`bd9e5f448242cbec204c1d41f3dd55ab32b436842bc209c6de749b81645fd223`
at all three checkpoints.

The owner completion record is
`b76fee1c7a7e5db50056218d7ba2853a7aeaf954445555ed8a39c2588836cc4b`.
Its 31-row non-circular evidence manifest is
`9d1dd062f9e8ffc57ca4d21dceeaea44c8ec8d354902133da1c37e2cf98c9fdc`
and was reproduced independently.

## Visual acceptance and teardown

The retained screenshots were inspected at their original resolution. At
1440 x 1000 and 708 x 1000, the title, all outline headings, prose, active
navigation, bottom navigation, and footer are readable and usable. Both
viewports have page scroll width equal to client width, with no measured
overflow elements or content-block overlaps. The narrow navigation opens,
scrolls independently, identifies Supplementary information as active, and
does not obscure the final page controls after closing.

The loopback server was rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1:54200`, and used for the exact target. PID 80460 stopped cleanly.
An independent listener check confirms that port 54200 has no listener. The
browser console contains no warning or error entries.

## Order-record transition

The immutable execution-time dispatch manifest remains
`c28c7751fcc77e6ef098238ad6ff2c5f01aa884c885744d989105d7a8bbd9ef0`
and truthfully pins the executed order as `3e59a5f9...`, 5,311 bytes. The
coordinator later resealed the same order path to
`c93c21082427412a22657aebca3b533a8f2aa675fbe723c701b4ceec7f4480d7`,
6,189 bytes. Both roles are retained in the owner evidence. No rerender
followed the handoff.

## Queue disposition

The technical DOC-001 missing-target condition is resolved for the current
37-page corpus. Final DOC-001 closure still requires the later whole-corpus
integration audit after every remaining page is refreshed.

The H02 result remains accepted. Its companion is now eligible for a separate
serial REPORT-018 render order, but no companion render is active merely by
this acceptance. Every later render remains held until separately released.

The coordination matrix records this disposition at SHA-256
`8758a136ca070df1c9660d40294bfc1bafbfa1ff35ab0e033fc87511a8a0f63e`.
