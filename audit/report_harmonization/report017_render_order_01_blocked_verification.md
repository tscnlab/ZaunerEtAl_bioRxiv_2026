# REPORT-017 Phase 4 order 01 blocked verification

Date: 2026-08-13  
Scope: Descriptives target render only  
Status: **blocked before knitr by project R-profile and renv startup**

## Authorized boundary

REPORT-014 and REPORT-017 authorized one targeted normal-execution render of
`notebooks/descriptives.qmd` through the Nature Health profile. Normal
execution was required because the accepted source constructs four native
`gt` displays from sealed stored inputs. The order did not authorize a full
project render, scientific reconstruction, package change, lockfile change,
or a second render attempt.

The accepted preflight identities were:

- `notebooks/descriptives.qmd`:
  `b631936d9e47c4988dd453ea22184090b076705e3716e8f037e1953e3309cd4c`;
- `_quarto-nathealth.yml`:
  `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`;
- existing `_build/nathealth/notebooks/descriptives.html`:
  `2d88888c888bc6f89374bd43753c239329bb1b9dd33f0f6e466d5cece5556ce0`.

All three identities matched immediately before the command.

## Blocked render record

The owner ran exactly one command:

```text
quarto render notebooks/descriptives.qmd --profile nathealth
```

Environment:

- R 4.6.1, `aarch64-apple-darwin23`;
- Quarto 1.9.37;
- renv 1.2.3;
- gt 1.3.0;
- knitr 1.51.

The R child started at `2026-08-13 07:42:26.571 CEST`. The first
post-interrupt confirmation was at approximately
`2026-08-13 08:54:55 CEST`. Observed duration was approximately 4,348.4
seconds, or 72 minutes 28 seconds. The command exited with status 1 after the
owner interrupted the nonproductive startup loop. No second render was
attempted.

A two-second read-only stack sample at `08:51:59.693 CEST` inspected R PID
81850. All 1,663 samples remained below `R_LoadProfile`; 1,268 were in
`do_dircreate()` and 129 were in `file.info()`. The process was still using
approximately 99.9% CPU. It had loaded `.Rprofile` and the project `renv.so`,
but it had not loaded knitr, gt, dplyr, or the QMD. The temporary raw sample
had SHA-256
`004853e94533ac1a6219befd2b9ee47d917c8a8f4b84338c94466b0143a671c6`.

This evidence localizes the blocker to project-environment activation before
document execution. No QMD cell, Descriptives builder, scientific
calculation, table construction, or writer ran during the attempted render.

## Exact no-change evidence

The owner compared path, byte count, modification time, and SHA-256 before
and after the command:

- the protected Descriptives inventory contained 125 files and 105,158,438
  bytes both times, with zero content changes and zero timestamp changes;
- its pre-render and post-render inventory files were byte-identical, each
  with SHA-256
  `b9d7103880040a7bfb653b744e454bfb3c4c9dbebeab224621ec5b331ae20879`;
- `_build/nathealth` contained 827 files and 294,689,985 bytes both times,
  with zero content changes and zero timestamp changes; and
- its pre-render and post-render inventory files were byte-identical, each
  with SHA-256
  `8f4cf016a7ce3ddf67974e245c08ed0057a3e861eaf62f26d37749a7991e9b87`.

An independent harmonization-worker inventory of the required table, figure,
source-data, manifest, and audit directories contained 101 files and
104,084,718 bytes before and after the command. Its sorted SHA-256-list digest
remained
`853c3c08ee9eb3484d16a9c2bdf1da591a335083e8a5d5f0bbaca4a12a9e015e`.

Consequently, the accepted source and configuration identities above, the
existing HTML identity, `search.json`, `sitemap.xml`, stored scientific
inputs, source data, manifests, tables, and figures all remained unchanged.
Targeted `git diff --check` passed. The owner wrote no project file; only
temporary `/private/tmp/report017_*` diagnostic files were created.

## Display-only object contract

After the blocked command, the owner ran a narrow R 4.6.1 display-only check
without loading the project profile. It put the existing project library
first, read only the sealed render inputs, and constructed the current display
objects without writing a project file. It established that:

- all four converted support endpoints are native `gt_tbl` objects;
- `tbl-participant-site` remains a native `gt_tbl`;
- sample flow is 8 by 5;
- comparison summary is 6 by 3;
- visual exports are 10 by 6;
- the figure contract is 6 by 12, with exactly 11 non-stub displayed values;
- accepted keys and row order are preserved;
- loaded input-object hashes are identical before and after display
  construction; and
- the QMD contains no call to the prohibited Descriptives builders,
  `ggsave()`, `gtsave()`, or publication-export writers.

This check validates the source-level display contract only. It is not a
substitute for a successful target render through the project profile.

## Stale-HTML limitation

The unchanged HTML predates the current accepted source. It contains the main
figure and the native `gt` participant table, but its four support endpoints
remain generic tables and its new Preparation 01 and Preparation 02 links are
absent. It therefore cannot serve as Phase 4 acceptance evidence. No current
rendered screenshot or semantic-HTML proof exists for the four converted
tables.

The stale page has no error or warning element, its active sidebar is correct,
and it contains all nine country-coded site labels. These facts do not change
the blocked disposition.

## Separate reader-text defect

Static inspection of the accepted participant-table PNG and the current
display formatter found two reader-only wording defects in
`build_participant_site_publication_gt()` in
`scripts/descriptives/build_publication_tables.R`:

- lines 188 to 189 begin with `Near-eye`; the approved reader term is
  `Near eye`;
- line 213 says `near-eye only`; the approved reader term is
  `near eye only`; and
- lines 230 to 231 say `Employment categories reproduce the submitted
  grouping`. The value-neutral replacement is `Employment categories:
  Full/studying, Part/marginal, and Not employed.`

These are display-text corrections only. They must not alter table values,
rows, columns, denominators, the stored PNG, or any scientific artifact. They
were not applied during this blocked order.

## Disposition

Render order 01 is not accepted and the serial Phase 4 queue remains held.
The accepted source remains eligible for a fresh target render only after the
scoped environment-startup repair in
`report017_environment_startup_repair_request.md` passes its smoke gate. The
principal and supplemental Descriptives output roles and appearance remain
provisional pending the author's later visual review.

