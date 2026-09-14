# REPORT-018 order 39a: H02 companion renv-startup retry and completion

Date: 2026-08-20

Owner: H02 task `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Status: **AUTHORIZED ONCE AS AN ENVIRONMENT-PERMISSION RETRY**

Order 39 stopped before target execution because restricted startup could not
create renv's transient lock in the existing user-owned cache. This
continuation preserves the valid unexecuted helper edit and retries the exact
H02 companion target once with the established narrow cache permission. It
does not authorize a second document cleanup cycle.

## Controlling stopped-state acceptance

- startup-stop acceptance:
  `audit/report_harmonization/report018_h02_companion_order39_startup_stop_acceptance.md`,
  SHA-256
  `d6f71c3f08f468c5a92b0ea74ae5507e634b9f80235aaa9f7609e08ce611a231`,
  5,551 bytes;
- non-circular 23-row acceptance manifest:
  `audit/report_harmonization/report018_h02_companion_order39_startup_stop_acceptance_manifest.csv`,
  SHA-256
  `a9430b8e8ce5a7fad4177b4eacafadeda7e0d16f905b9b36cef1a7284b898b3e`,
  3,471 bytes, R 4.6.1 audit 23/23 exact and unique;
- original order 39:
  `audit/report_harmonization/owner_orders/39_h02_companion_target_render.md`,
  SHA-256
  `21c0b6ca19651186955ea6fa19d7a7a033ae56774abd64fec0ed7fd25679918f`;
- accepted environment diagnosis:
  `audit/report_harmonization/report017_environment_startup_repair_verification.md`,
  SHA-256
  `2b8a24115ce9e187abcf57f0f9b52d643c917db57d2cd8d08f3d65e96983f249`.

The first command attempt did not reach knitr or the target `rmd.R` path. It
created no target output and no semantic-hook record. The old external audit
directory `/private/tmp/H02-order39-semantics.NAwzt6` is empty and must remain
untouched as stopped-state evidence.

## Exact continuation pins

- authorized unexecuted helper:
  `scripts/hypotheses/H02/build_h02_preparation_report_manifest.R`, SHA-256
  `3e69748ad3b3ef3dde7dcd0dc3c913d21971c1c5ef5098e44452d3f2f37111b1`,
  10,401 bytes;
- companion source:
  `audit/hypotheses/H02/H02_analysis_preparation.qmd`, SHA-256
  `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`,
  55,146 bytes;
- result source:
  `notebooks/hypotheses/H02.qmd`, SHA-256
  `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`,
  57,148 bytes;
- stale companion HTML:
  `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`,
  SHA-256
  `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`,
  580,722 bytes;
- stale build-side companion QMD:
  `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.qmd`,
  SHA-256
  `52a1b3b85c4a375c44c0a2a83f542ea2663c7d233a6de18ed689cb2b7a0be557`,
  51,475 bytes;
- accepted result HTML:
  `_build/nathealth/notebooks/hypotheses/H02.html`, SHA-256
  `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`,
  296,427 bytes;
- current preparation manifest:
  `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`, SHA-256
  `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7`,
  12,457 bytes;
- profile: `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- `.Rprofile`, `renv/activate.R`, and `renv.lock`: SHA-256
  `3f9d62fc3f1bf5888a09816101b705f9844ef4cd44ee5ad157f4168dac4af4d4`,
  `51798a35c2772b94b4a73ae7a7cc928975ff6e628a17bad1bc73d30defca82e6`,
  and
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

The original order-39 preinventory and all original dispatch records must
remain byte-identical.

## One retry, no diagnostic loop

1. Rehash every continuation and original order pin. Confirm that PIDs 86844,
   86858, and 86860 remain absent, the old semantic directory remains empty,
   and no Quarto render is active. Stop on drift.
2. Do not edit, format, or execute the helper before the target render. Do not
   run a preliminary R startup smoke, diagnostic `dir.create()`, package check,
   or other profile-dependent command. The accepted environment diagnosis is
   already sufficient.
3. Create one new empty absolute semantic-audit directory with `mktemp -d`
   under `/private/tmp`. Record its resolved path, permissions, and emptiness.
4. Run exactly one continuation render command:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=<new-absolute-directory> quarto render audit/hypotheses/H02/H02_analysis_preparation.qmd --profile nathealth
```

   Execute it with `sandbox_permissions=require_escalated`, or the exact
   task-equivalent narrow permission that allows transient writes to the
   existing user-owned renv cache. Retain the normal `.Rprofile` and
   `renv/activate.R` path. Do not bypass the project profile, set replacement
   library paths, remove a cache lock manually, edit the cache, install or
   update a package, or change `renv.lock`.
5. This is the only retry. If startup again loops, produces no progress, or
   fails, interrupt that same session, verify process teardown, and return one
   final environment-stop seal. Do not retry again.

## Completion after successful target execution

After exit 0, continue the already approved order-39 integration without a
new classification pause:

1. Require a nonempty semantic audit with the expected companion target and a
   valid `REPAIRED` or complete no-change disposition.
2. Run the unchanged current helper exactly once. Require the build-side QMD
   to equal the authoring QMD, the two approved source-data downloads to equal
   their protected sources, and exactly 59 unique live-exact preparation
   manifest rows.
3. Apply only the already authorized reader-test and preparation-test
   integration literal and historical mismatch-set changes from order 39.
   Keep the worker manifest byte-identical and require its exact ten-path
   historical-to-live mismatch set. Do not run its broad builder.
4. Run the complete reader, preparation, and paired-placement tests plus every
   semantic, link, navigation, country-code, no-error, build-delta, and
   protected-identity check specified in order 39.
5. Perform the complete secure-loopback QA specified in order 39 at 1440 x
   1000, 708 x 1000, 200-percent-equivalent, and intended final output sizes.
   Inspect all 16 native tables, four figures, the TD Mermaid, and exported PNG
   outputs. Stop the server and prove no listener and no post-QA drift.
6. Return one combined owner acceptance package. Under REPORT-018, record and
   defer nonblocking language, style, optional-link, test-literal, or cosmetic
   observations rather than opening another cleanup loop.

## Prohibitions

No QMD edit, result rerender, later target render, full-project render,
scientific computation, scientific artifact regeneration, full builder,
profile or shared configuration edit, ledger or manuscript edit, package or
lockfile change, cache deletion, commit, push, upload, or publication.

The H03 result and every later REPORT-018 target remain held pending
independent H02 companion acceptance.
