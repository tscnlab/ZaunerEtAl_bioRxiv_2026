# REPORT-018 owner order 49: H06_daily preparation companion render

Date: 2026-08-21  
Owner: H06_daily  
Scope: exactly one preparation/provenance companion target render  
Status: sealed for dispatch

## Authority

Execute the companion-only contract in
`audit/report_harmonization/report018_h06_daily_companion_release.md` exactly.
The accepted H06_daily result is frozen under central acceptance SHA-256
`eef994b2851d8b150719ce34f158ce46a77c7d49c8e12ed7ceeee6f7f1aac8d6`
and its 26-row seal SHA-256
`1bdcf80ac0d0adeaafa16a432efcdf3d9331271c20300b6728d0e0dcd9b612da`.

The companion preflight passes under R 4.6.1. Reproduce every hard row in
`audit/report_harmonization/report018_h06_daily_order49_dispatch_manifest.csv`
before execution. Treat the coordination-matrix row as dispatch-time evidence,
not as an owner execution pin.

## Frozen inputs

The controlling companion source is
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`, SHA-256
`ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`,
35,409 bytes. The current held build HTML is SHA-256
`7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`,
4,613,650 bytes. The result source and HTML must remain respectively
`8f696f3f...` and `74a63bd0...`. The profile must remain `80dd0557...`.

The historical preparation test and both historical preparation manifests are
evidence only. Do not edit or execute the historical test. Do not run a helper
or manifest builder. Preserve each historical file byte-for-byte and classify
only the exact transition sets recorded by the release checker.

## Preflight and sole command

Require:

- no active Quarto, Pandoc, semantic-hook, H06_daily, or loopback process;
- complete pre-render build and protected inventories;
- exactly 846 build files and zero symlinks;
- all 26 release pins and all 26 result-acceptance rows exact; and
- one fresh empty absolute semantic-audit directory under `/private/tmp`.

Then run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

Use normal R 4.6.1 and Quarto 1.9.37 startup with the established narrow
elevated access to the existing user-owned renv cache from process startup.
Do not bypass renv or the profile. If startup or rendering fails, stop without
a second render.

## Acceptance contract

After a successful render, verify directly against the new HTML:

1. exactly 17 native gt tables, one figure, one top-down Mermaid, and two
   dynamic `.qmd` links;
2. semantic repair with a complete reversible ledger, unique document IDs,
   and every table `headers` token resolving once inside its table;
3. all table bodies, captions, notes, labels, figure values and source mapping,
   links, anchors, active navigation, and country-coded sites;
4. zero execution errors, warning nodes, unresolved references, broken internal
   links, forbidden local paths, or page-level overflow;
5. exact preservation of the result page, all scientific inputs and artifacts,
   the source QMD, profile, lockfile, semantic tools, phase-4 corpus manifest,
   historical test, and historical manifests;
6. an exact build-delta account limited to target-owned companion output and
   expected search or sitemap integration; and
7. secure-loopback visual QA at 1440 by 1000, 708 by 1000, 720 by 500 as the
   200-percent-equivalent view, and the figure at 170 mm with essential text at
   least 7 points.

Exercise any narrow contained table scrollers, capture evidence, stop the
loopback server, prove no listener remains, reset or close the QA surface, and
rehash the build and protected sets.

Return one non-circular acceptance package or one consolidated fail-closed
defect list. Do not patch or rerender on a new defect. No model, inference,
scientific artifact regeneration, source edit, helper, test edit, manifest
builder, result render, H07 or later render, Brown action, full-project render,
commit, push, or upload is authorized.
