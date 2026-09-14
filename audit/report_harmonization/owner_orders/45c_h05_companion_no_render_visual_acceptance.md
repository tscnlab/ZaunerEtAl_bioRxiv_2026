# REPORT-018 owner order 45c: H05 companion no-render visual acceptance

Date: 2026-08-20

Owner: harmonizer shared integration

Status: **released for existing-HTML visual acceptance only**

## Authority

Order 45b completed the sole H05 companion render, semantic repair, helper,
and independent nonvisual inspection. Independent acceptance is
`audit/report_harmonization/report018_h05_order45b_test_stop_independent_acceptance.md`,
SHA-256
`d460ecbdb625b40488900c31c96eabb7f7227a5dac12d0ee650d3ca3c5a2e9c3`.
Its 14-row non-circular manifest is SHA-256
`9a78b7cfa820b3c1760d5289c966c2a34e20f47ff9d5a7894b54e7fed9dc5b76`.

Finding H05-45B-TEST-001 is a deferred stale source-test contract under
REPORT-018. It does not block reader-facing render completion. Do not edit or
rerun that test in this order.

## Hard pins

- companion source and source-identical website QMD:
  `843f60f890daac0e41c6655bc365ab0325e3f582e011610469a799946b2f2811`;
- fresh companion HTML:
  `856dbd21920b65dce6437172022d0e6130410d9e357259a4d50aa1f6fe2461d8`,
  926,928 bytes;
- live-exact 142-row preparation manifest:
  `49ab691f8d86852ec034ed49ffa773032c3acdf3312d7fef5de7849c9ff07d80`;
- accepted result QMD and HTML:
  `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`
  and
  `a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic summary and ledger:
  `1d1b02be2c3ee2ada3d563b51bf7d6702212b4072404eb8a4551330f6b0e4f4c`
  and
  `7de75179be2f187d646077f94879fd45817e7177b32323b9852452f3b1f91f52`;
- post-render build inventory:
  `fc5b883724477532baa2697eb94864c53e26991a2f49b34cc3a43dc2ebb9fe11`;
- post-render protected inventory:
  `9a7fc2f8699abf6e75f25d1042263cb7f3d3f250eae23393f72cc69cf0409871`;
- order-45b 41-row owner manifest:
  `33f0fe8bb0de17b0ccf9c89d216fe8b5b273337e965888302fce4e4799af239c`.

## Visual QA

1. Recheck every hard pin and preflight `_build/nathealth` for symlinks.
2. Start one temporary read-only static server rooted exactly at
   `_build/nathealth`, bound only to `127.0.0.1` on an unused high port.
3. Navigate only to
   `/audit/hypotheses/H05/H05_analysis_preparation.html` in the in-app
   browser.
4. Inspect the complete page at 1440 by 1000, 708 by 1000, and a
   200-percent-equivalent viewport. Inspect all 22 native tables, all three
   figures, the Mermaid, disclosures, callouts, headings, captions, links, and
   active navigation.
5. Apply the accepted desktop-first table policy. Narrow tables may use a
   contained, usable horizontal scroller. The page itself must not overflow.
6. Inspect stored PNG or SVG outputs at their intended final sizes for exported
   figure acceptance.
7. Record screenshots, DOM measurements, viewport sizes, server command, PID,
   port, root, timestamps, and verdict.
8. Stop the server, prove no listener remains, reset the viewport, close the QA
   tab, and prove source, profile, HTML, build, and protected identities are
   stable after QA.

Return one combined acceptance or one genuinely new visual defect. Do not open
a language, style, optional-link, stale-test, or cosmetic cleanup loop.

## Prohibitions

No Quarto command, render, helper, test, source edit, HTML edit, build edit,
scientific execution, model, artifact regeneration, profile, package,
lockfile, ledger, manuscript, commit, push, upload, publication, external
browser, Computer Use, CDP, public tunnel, LAN binding, or file URL workaround
is authorized.

