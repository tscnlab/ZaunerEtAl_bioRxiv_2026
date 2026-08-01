# Preparation reports: scoped stable-input decision

Date: 2026-08-01

Decision owner: coordinating task

Status: **Authorized for Preparations 01–07**

## Why the protection scope changed

The original 2,094-path checksum inventory deliberately covered every
accepted preparation artifact and every downstream H01–H11 source, result,
test, and handoff. It proved that the Preparation 06 showcase render did not
alter downstream science, but it also stopped documentation work whenever an
independent hypothesis task legitimately changed its own files in the shared
checkout. Those downstream files are not analytical inputs to the preparation
reports.

The coordinating task therefore replaced the whole-checkout gate with a
page-specific stable-input gate. The earlier baseline, failed comparisons,
and reconciliation evidence remain unchanged in the audit record.

## Files that block a preparation-page render

For each page, the scoped read set contains:

1. the Quarto source in its final pre-render state;
2. every stored file read by an executable chunk;
3. every accepted preparation artifact named by a manifest that the page
   checks or reports;
4. every production script or function module whose operation the page
   describes;
5. relevant shared preparation decisions and reporting contracts;
6. the R environment identity; and
7. the shared Quarto configuration and stylesheet used for the HTML render.

Every path is hashed by size and SHA-256 immediately before the bounded page
render and compared immediately afterward. A missing or changed read-set file
is a blocking failure. The render may read and summarize stored values but may
not recreate an accepted preparation or analytical artifact.

The reusable foundational baseline is
`audit/preparation_reports/preparation_reports_scoped_continuation_baseline.csv`
(13 paths; SHA-256
`35835f8cc46fd0790f9d0d9c6d3d0fa6550a9b84c4b68cf25954f548f7b82691`).
Page-specific pre-render baselines extend that foundation with the exact
source, artifacts, manifests, registries, and production code used by the
page.

## Final settled-profile continuation baseline

After the H01 and H05 closures were accepted, the coordinator authorized one
refreshed union of the exact page read sets. The resulting baseline is
`audit/preparation_reports/preparation_reports_final_scoped_baseline.csv`
(538 paths; SHA-256
`4b1ece912e6385ae3aa0a76efea296f54cf965df4f7599c384c28c45db4980f9`).
It includes Preparation 06's eight manifest bundles, the production drivers
and function modules described by that page, and the settled shared render
configuration. Its final handoff comparison found 538 unchanged paths and no
mismatch.

The settled coordinator-owned identities used for the rerenders were:

- `_quarto-nathealth.yml`:
  `4b7ce91614a6d8f76f2526ced5aed3e2064fd2a70113018057b7a11b3916c803`;
- `audit/decisions/model_reporting.md`:
  `41fb454e42d9def6b905601ed9544d5cb447f8b38c3862723c07fd1834037134`;
- `audit/ledgers/finding_register.csv`:
  `7ad1fcfc6975226039fa7c4357e07e32615c5f91e821d884f05bf16f03ebe86b`.

Preparations 01–06 were then rendered sequentially with the `nathealth`
profile. Preparation 07 retained its already verified render, as explicitly
directed by the coordinator. Each page passed its own pre/post identity gate;
unrelated downstream changes outside these read sets remained non-blocking.

## Concurrent work excluded from the blocking gate

Unless a preparation page reads or summarizes an exact downstream file, the
following are recorded as excluded concurrent work rather than preparation
failures:

- H01–H11 model, prediction, diagnostic, figure, table, source-data, test,
  manifest, notebook, audit, and handoff files;
- descriptive-analysis outputs and their active source files;
- coordinator ledgers that are not read by the preparation page; and
- rendered pages and other generated review artifacts outside the page being
  rendered.

If a page later cites or summarizes a downstream artifact, that exact path
must first be added to its read set. No such downstream scientific result is
required for Preparations 01–05 or 07.

## Computation boundary retained

The scope change affects provenance checking only. It does not authorize any
preparation rebuild, metric calculation, model fit, prediction, resampling,
simulation, Shapley calculation, H01–H11 rerun, full-project render, package
installation, or scientific artifact write.
