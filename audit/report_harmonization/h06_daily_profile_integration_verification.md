# H06_daily source-only profile integration verification

Date: 2026-08-13

Verdict: **ACCEPTED**

The coordinator added only the accepted H06_daily result and
preparation/provenance companion to the Nature Health render list and sidebar.
The configuration changed from
`b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`
to
`5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`.

In `project.render`, the accepted order is:

1. `notebooks/hypotheses/H06.qmd`;
2. `audit/hypotheses/H06/H06_analysis_preparation.qmd`;
3. `notebooks/hypotheses/H06_daily.qmd`;
4. `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`; and
5. `notebooks/hypotheses/H07.qmd`.

The sidebar uses the same adjacency with labels `H06 complementary daily
results` and `H06 complementary daily preparation and provenance`.

Independent R 4.6.1 YAML and text checks confirmed that each new QMD occurs
exactly once in both structures. Removing the exact two render entries and the
exact two labelled sidebar entries from the current bytes reproduces the
previous configuration SHA-256. Every other configuration byte is therefore
unchanged. `git diff --check` passes.

The integrated result and companion sources remain exact at
`01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`
and
`ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`.
No Quarto or R execution, target render, scientific calculation, source edit,
or asset regeneration occurred.

This source integration does not release an H06_daily render. Hourly H06
remains the main result, and H06_daily remains complementary evidence until
its separate REPORT-017 serial render and final-size visual QA are accepted.

The non-circular manifest is
`audit/report_harmonization/h06_daily_profile_integration_manifest.csv`.
