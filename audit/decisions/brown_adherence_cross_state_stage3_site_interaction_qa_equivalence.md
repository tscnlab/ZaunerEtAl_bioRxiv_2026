# Brown adherence Stage 3 site-interaction QA equivalence

Decision ID: `BA-013`  
Change ID: `CHG-152`  
Date: 2026-08-20  
Status: coordinator authorized; QA-method substitution only

## Decision

The sole `BA-012` environment-recovery render completed successfully under
R 4.6.1 and Quarto 1.9.37. The replacement HTML passed all 30 structural,
semantic, provenance, privacy, and protected-identity checks. The rendered
page is reachable through the secure loopback server and renders correctly
in the in-app browser's fixed native 1280 by 720 viewport.

The current Browser Use API does not expose viewport resizing or emulation.
A same-origin data-URL iframe harness was blocked by Browser Use security
policy with an explicit instruction not to work around the block. This is a
QA-harness limitation, not a page, source, render, or scientific defect.

`BA-013` and `CHG-152` authorize native 1280 by 720 served-page inspection
plus deterministic responsive and mobile structural verification as the
bounded equivalent to the unavailable 1440 by 1000 and 390 by 844 visual
emulation. This substitution applies only to the current Brown integrated
Stage 3 page and does not change the visual contract for another document.

No additional render, source edit, scientific calculation, display rebuild,
browser surface, CDP connection, iframe workaround, or external browser is
authorized.

## Controlling authority

| Artifact | SHA-256 |
|---|---|
| `audit/decisions/brown_adherence_cross_state_stage3_site_interaction_render_retry.md` | `d5f2955dbe16fe670f531ddf8ce5d782cccb2505400a97a789315a285f831e48` |
| `audit/decisions/brown_adherence_cross_state_stage3_site_interaction_render_retry_manifest.csv` | `d96199e3adb84b5598402e0d317881bd7d44e3d53f7f61259fdd485bd8c312aa` |
| `audit/ledgers/decision_register.csv` after `BA-012` | `514044cfb77d85557fbf23c47537a1244c911da5b7e569fcdea16e0285635061` |
| `audit/ledgers/change_log.csv` after `CHG-151` | `c592a39d91331302afb46805c7af240ceb60aa6861502a6301d9aa1edefeff0e` |

The continuing task must verify unique `BA-013` and `CHG-152` rows before
finalizing QA.

## Accepted completed-render identities

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 49,315 | `ef6ed62690afa30fe2801e559b487462a11c4130e903e3725bb164554bed191a` |
| replacement `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 4,330,019 | `c65cf33519723b8bcc9f83550d1e0509099c9f6ffa1a37d7bcdd7fec2f9464c1` |
| `site_interaction_display_amendment/source_data/main_site_free_work_forest_source.csv` | 3,423 | `06883e6c5a345c98b6834ac547122b006c7fdbe865a80704c3b4d65076585692` |
| `site_interaction_display_amendment/figures/main_site_free_work_forest.png` | 324,853 | `201f199480acfc9f2ab56f0cee304565a4d95cf2977f680b7116597c42ef6b23` |
| `site_interaction_display_amendment/figures/main_site_free_work_forest.svg` | 30,013 | `6ab907d9d0dd282970492866b25e05625f0a4b640d83623ddaeebb2f8ee90c54` |
| `site_interaction_display_amendment/render_retry_execution_record.csv` | 1,722 | `a237d06b1c8eee1cf97b8ed42e79642921f1fe5853f558e2cd2965f60ac0a118` |
| `site_interaction_display_amendment/retry_render_verification_checks.csv` | 1,124 | `16c6f9bf2c8b41ae5cc60507a6fdf8dc86dfbf9705c791dbe7187020bae99b5e` |
| `site_interaction_display_amendment/retry_render_verification_execution_record.csv` | 709 | `58476832dd343742b75b84935b163e8980b6dcd6a4aeb5918d3181c9d9a33654` |
| `site_interaction_display_amendment/visual_qa_preflight_identities.csv` | 2,500 | `957669e024a2ea2976b1e1bb5485e673adf5441dc37a0b3e839c716f6b625dc3` |

Paths beginning with `site_interaction_display_amendment/` are relative to
`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/`.

The replacement render record must remain the sole `BA-012` attempt. The QMD,
HTML, paired source, PNG, SVG, configuration, report CSS, scientific inputs,
and all prior evidence must remain byte-identical throughout QA.

## Native visual inspection

Use the existing secure served page at the browser's native 1280 by 720
viewport. If the current server has already stopped, one new server bound
only to `127.0.0.1` may be started for QA. Do not use a `file:` page as the
controlling view.

With ordinary reader scrolling, inspect and record:

1. the title, answer-in-brief callout, scientific question, selected model,
   exact sample table, and primary state and day-type findings;
2. the complete site-interaction section, including its test table, all 27
   forest-plot contrasts, caption, alt-text meaning, paired-source link,
   zero lines, equal-site reference lines, five emphasized contrasts, and
   surrounding detailed table;
3. endpoint calibration, coverage gate, retained participant random effect,
   R-squared and Shapley displays, chest context, and limitations;
4. the separate cross-state association extension, descriptive Wake-cycle
   groups, anonymous raincloud, qualifications, and final synthesis;
5. all callouts, cross-references, source links, tables, figures, captions,
   headings, and page flow for clipping, overlap, obscured controls,
   unreadable text, broken layout, or unintended horizontal page overflow;
   and
6. the exported 2,640 by 3,360 forest-plot PNG at its declared intended size,
   where exported-artifact legibility is controlling.

Retain a full-page screenshot and focused screenshots of the new
site-interaction figure and its immediate context. Existing native-viewport
screenshots may be used if their page and HTML identities are exact.

## Deterministic responsive and mobile checks

Because a 390-pixel browser viewport cannot be safely produced, verify the
mobile contract directly from the exact rendered HTML and linked CSS. The
record must check all of the following:

1. the viewport metadata is exactly responsive and permits user scaling;
2. `html` and `body` are bounded to the page width, while `main`, `.content`,
   and `.page-columns` have no fixed minimum width;
3. every native `gt` table is inside a container with contained horizontal
   overflow, and the 760-pixel breakpoint's 680-pixel table minimum width is
   handled by that container rather than by document-level overflow;
4. all four figures have responsive image classes or explicit responsive
   sizing, and the new wide forest plot remains inside its dedicated
   horizontal-scroll wrapper with the approved minimum mobile figure width;
5. callout text can wrap at narrow width, source links and captions contain
   no unbreakable layout-forcing token, and no reader-facing element imposes
   a fixed page width greater than 390 pixels outside an approved scroller;
6. the complete 30-of-30 render checks, 12-part new-figure contract, 16-table,
   four-figure, 28-source-link, 20-cross-reference, privacy, error, and
   protected-identity checks remain passed; and
7. the QA record distinguishes observed native visual evidence from the
   deterministic 390-pixel structural assessment and does not claim that a
   mobile screenshot or emulated viewport was obtained.

R 4.6.1 may be used for these non-scientific structural checks. No model,
prediction, inferential calculation, source-data transformation, figure
rebuild, or HTML rewrite is permitted.

## Security boundary and final sealing

Do not retry the blocked iframe harness. Do not use CDP, another browser,
another browser-control tool, a different browser surface, injected page
scripts that simulate a viewport, or any workaround to Browser Use policy.
Record the fixed-viewport limitation and blocked harness as QA-method
evidence only.

After QA, stop the loopback server, prove that its process is gone and no
listener remains, close the QA tab where supported, and rehash all frozen
identities. Seal one non-circular final manifest, QA record, screenshots
inventory, updated handoff, final checks, and renewed author gate inside the
existing amendment directory. The QA outcome may be recorded as
`PASS_WITH_BOUNDED_VIEWPORT_EQUIVALENCE` only if every native visual and
deterministic structural check passes.

Stop and return a sealed failure on any visual defect, missing responsive
contract, uncontained wide element, broken link, identity drift, listener
teardown failure, or attempt to exceed this QA boundary. No additional
render is authorized.

## Mandatory author stop

If the bounded-equivalence QA passes, the task may reach
`BA-CS-G3-INTEGRATED-REVIEW`. The required author decision remains:

> Approve Brown cross-state integrated Stage 3 as written.

Stage 4 and notification of manuscript task
`019ffb39-372e-7262-bfac-192751fd0e63` remain blocked until that explicit
approval.
