# REPORT-017 Preparation 06 independent acceptance

Date: 2026-08-13

## Disposition

Preparation 06 is independently accepted for source and targeted Nature
Health HTML integration. The only report-source change after the first visual
stop was `flowchart LR` to `flowchart TB`. Replacing that one declaration with
`flowchart LR` reproduces the accepted pre-repair source SHA-256
`2067db45d46b49bec34985f68eb9e10d5e35377548c5103218321261d50f4c5b`
exactly.

Preparation 07 remains held pending a separate serial release. Principal and
supplemental output roles remain provisional for author review. DOC-001 remains
open.

## Accepted identities

| Path | SHA-256 |
|---|---|
| `notebooks/preparation/06_model_ready_datasets.qmd` | `23b201c404f3b30918d49459ce54a3155a26b758ff10872bc0be4264bd386f87` |
| `tests/test_preparation06_report.R` | `03017c71915194335422f538f72750b914855310f5045d893b71a346961112ec` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `_build/nathealth/notebooks/preparation/06_model_ready_datasets.html` | `7306d9d51e9a20da1e09ffd8a3147f7bdf1f8b6b3b1c80e0e23455ad43d96565` |
| Owner verification record | `c0913c1dcccc93059d0dffea94168e929970a4d8b9a6ab7fc50872f7c448d8ac` |
| Owner 60-entry non-circular manifest | `51308ca5ac4a72a07c37f7939a34f86003038ce073c9e9c6b567df41283a8af2` |

## Independent verification

The following checks were rerun independently:

- The focused command `Rscript tests/test_preparation06_report.R` completed
  under the normal project R 4.6.1 profile with exit status 0. It confirmed the
  bounded-render, terminology, native-`gt`, figure, and provenance contract.
- An R 4.6.1 audit verified all 60 owner-manifest paths, byte counts, and
  SHA-256 identities with no duplicate path or mismatch.
- An R 4.6.1 audit verified all 168 protected paths at their current
  identities. Exactly 166 are unchanged. The other two are the authorized
  diagram-only QMD change and the authorized focused-test wording changes.
- An independent R 4.6.1 DOM audit found 19 unique native `gt` endpoints,
  exactly one native table per endpoint, 19 nonempty Quarto captions, source
  notes, nonempty main-content link labels, the resolved DEV-056 link, and no
  forbidden internal `.qmd`, `_build`, `file:`, or absolute-local link.
- The first temporary DOM command stopped at R parsing because of a regular
  expression escape in the audit harness. It did not inspect or modify project
  files. The fixed-string version then completed successfully.
- The post-render and post-QA 829-file build inventories are byte-identical at
  SHA-256
  `0132c31e5423fc8c43e87d1eb6daea884711e9ed0676a5b793f017f679199590`.

## Independent visual review

The retained desktop and 708-pixel screenshots were reviewed at original
resolution. The repaired top-to-bottom diagram is readable, balanced, and
unclipped. Its measured effective label size is 12.0 points at desktop width
and 10.76 points at 708 pixels.

All 19 native HTML tables were reviewed at normal desktop width. Titles,
captions, headers, bodies, source notes, and surrounding explanations are
readable. At 708 pixels, the page remains contained. The three tables wider
than their wrappers provide working horizontal scrolling, and retained left
and right endpoint screenshots show that their complete content is reachable.

The exported site-composition PNG was reviewed directly at original
resolution and in its retained final-display screenshots. It has country-coded
site names, the approved site order and colours, readable labels, no clipping,
and no overlap. The PNG remains byte-identical at
`058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`;
its paired source-data CSV remains byte-identical at
`809d109d3647ef4ac1798ef9eb59c06e2c7db41f5b9ce1dade4d0a8b583f0a22`.

## Loopback and browser-created duplicates

The read-only server was bound only to `127.0.0.1:55856` with
`_build/nathealth` as its document root. It was stopped after QA. Independent
`lsof` verification returned no listener on that port.

Browser finalization created two new Finder-style duplicate paths that were
absent from the sealed pre-QA inventory. Only those two paths were moved
intact to `/private/tmp/report017_p06_browser_extras.m6VHKJ/`. Their original
paths, byte counts, hashes, mtimes, and recovery paths are recorded in
`audit/preparation_reports/report017_preparation06_browser_duplicate_recovery.csv`.
Independent checksum verification confirmed both recovery copies. All
pre-existing `* 2*` paths remain untouched.

## Scientific boundary

No data, sample, model frame, estimate, interval, p-value, diagnostic,
sensitivity, source-data value, scientific figure content, or claim changed.
No model was fitted or refitted. No project-wide render, commit, push, package
change, lockfile change, or manuscript edit occurred.
