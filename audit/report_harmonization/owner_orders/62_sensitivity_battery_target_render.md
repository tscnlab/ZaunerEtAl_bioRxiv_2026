# REPORT-018 Order 62: shared sensitivity-battery target render

Status: `AUTHORIZED_SINGLE_TARGET_RENDER`

Owner: shared-page coordinator task `019faf58-3df3-7383-8034-f715cdfdd154`

## Authority and purpose

REPORT-018 requires completion of the remaining reader-facing `notebooks/sensitivity_battery.qmd` target after H11 result and companion acceptance. The H11 closure is sealed at:

- `audit/report_harmonization/report018_h11_order61a_result_companion_independent_acceptance.md`, SHA-256 `54e83ea5bdddf2fa6758b9b3d3a502a6d321a5b67f15aefa4bddd0cf95ad9810`;
- its 37-row non-circular manifest, SHA-256 `9c2222d88b7fb69ed15245d672bb81df7599f3114d88218106512706c55800cc`.

The complete read-only preflight passes 10 of 10 domains under R 4.6.1. The target source is explicitly a planned-checks page. It contains one R chunk with `eval: false`, no inline R, no table or figure endpoint, and one resolving relative decision link. This render therefore presents the already accepted planning text and navigation without calculating a scientific result.

The earlier recommendation to hide the unfinished planning shell is superseded for scheduling by the later author-approved REPORT-018 instruction to render every remaining reader-facing target without opening another content or language loop. This order does not reclassify the page as a completed sensitivity analysis.

## Exact pre-render pins

- source: `notebooks/sensitivity_battery.qmd`, SHA-256 `d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70`, 3,623 bytes;
- held historical HTML: `_build/nathealth/notebooks/sensitivity_battery.html`, SHA-256 `b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780`, 37,775 bytes;
- normal profile: `_quarto-nathealth.yml`, SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- lockfile: `renv.lock`, SHA-256 `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`;
- semantic wrapper: SHA-256 `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine: SHA-256 `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- accepted Supplementary information HTML: SHA-256 `a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb`;
- historical 37-row corpus manifest: SHA-256 `73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334`.

The historical corpus manifest is a valid non-circular registry, not the current final seal. Its sensitivity row is still exact before rendering. The accepted later H06 through H11 transitions account for its current 31 of 37 source and 23 of 37 HTML live identities. Do not rebuild it inside this target order. The final whole-corpus integration step will rebuild and verify all 37 current rows once.

## Mandatory pre-render gate

Immediately before the render:

1. reproduce the complete Order 62 dispatch manifest;
2. rerun `scripts/report_harmonization/check_report018_sensitivity_battery_preflight.R` and require 10 of 10 PASS;
3. require exactly 1,180 existing build members and zero symlinks below `_build/nathealth`;
4. capture content inventories for the complete build tree and protected source, scientific, configuration, and acceptance paths after all Order 62 evidence files exist;
5. confirm no competing sensitivity-battery, Quarto, Pandoc, semantic-hook, or loopback process;
6. confirm R 4.6.1, Quarto 1.9.37, `gt` 1.3.0, the accepted R library, and the existing user-owned Sass cache identity; and
7. create one fresh semantic-audit directory under `/private/tmp`, outside the project and build trees.

Any failed pre-render gate stops the order without invoking Quarto.

## Sole render command

From the project root, invoke exactly once:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh absolute /private/tmp directory> \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library \
quarto render notebooks/sensitivity_battery.qmd --profile nathealth
```

Use the established narrow filesystem access to the existing user-owned Quarto and R caches. Do not change `HOME`, redirect or reset a cache, install or restore packages, bypass the profile, add `--no-execute`, choose another target, or run a full-project render. If this sole command fails, stop and seal the complete attempt. No retry is authorized by this order.

## Successful-render contract

On exit status zero, continue without another render:

1. require the configured semantic hook to return exactly `NO_GT`, with zero native `gt` tables, zero substitutions, and no semantic ledger;
2. require one `main#quarto-document-content`, title `Planned sensitivity checks`, the three accepted level-two headings in source order, zero tables, zero figures, zero duplicate IDs, no embedded error or warning output, and the disabled code block remaining disclosed as nonexecuted source;
3. require the decision link and all generated navigation, stylesheet, script, and local reader routes to resolve;
4. require the active sidebar entry to be the sensitivity page and preserve the accepted H11 and Supplementary information routes;
5. classify the exact content build delta. The only anticipated changed files are the target HTML, `search.json`, and `sitemap.xml`. Any additional content change requires a fail-closed return;
6. require every protected source, scientific artifact, profile, lockfile, accepted page, test, manifest, decision, and handoff identity to remain exact;
7. serve only `_build/nathealth` on `127.0.0.1` after repeating the zero-symlink preflight;
8. inspect the exact route `/notebooks/sensitivity_battery.html` at 1440 by 1000, 708 by 1000, and 720 by 500 as the 200-percent-equivalent surface. Check navigation, content completeness, local code containment, link behavior, page overflow, clipping, and console errors;
9. close all task-created browser tabs, reset any viewport override, stop the loopback server, prove no listener remains, and require post-QA build and protected inventories to match their post-render identities; and
10. return one non-circular completion or fail-closed seal.

## Prohibitions and next stop

No source edit, language pass, content completion, scientific computation, model fit, prediction, simulation, bootstrap, resampling, Shapley or dominance computation, scientific artifact regeneration, phase4 corpus-manifest rebuild, profile edit, package or lockfile change, alternate render, commit, push, upload, or publication is authorized.

The mandatory next stop is independent acceptance of the single rendered sensitivity page or the complete one-attempt failure package. The final 37-page corpus rebuild and integrated navigation, links, semantics, country-label, download, and build-manifest audit remain separately held until this target is accepted.
