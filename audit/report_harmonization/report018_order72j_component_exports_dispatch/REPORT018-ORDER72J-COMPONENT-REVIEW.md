# REPORT-018 Order72j component review

Date: 2026-09-11.

Status: `INDEPENDENT_STATIC_ACCEPTANCE_COMPLETE_VISUAL_ACCEPTANCE_PENDING`.

Mandatory gate: `REPORT018-ORDER72J-COMPONENT-REVIEW`.

## Result

The native SVG component exports for H07 and H09 pass the complete independent
static review. The optional H11 compatibility candidate also passes its bounded
static review, but remains unpromoted under the separately sealed browser-stop
disposition. No component received visual acceptance because every authorized
local browser route stopped before content load. These are browser policy or
sandbox route stops, not demonstrated SVG defects.

| Owner | Component | Static result | Visual result | Current disposition |
|---|---|---|---|---|
| H07 | S7-B | 32/32 independent checks pass | Loopback bind rejected before content load | Keep SVG candidate exact; visual acceptance pending |
| H09 | S15-A and S15-B | 41/41 independent checks pass | Loopback bind rejected before content load | Keep both SVG candidates exact; visual acceptance pending |
| H11 | Optional S17 compatibility | 14/14 independent checks pass | Direct file route rejected before content load | Retain the accepted S17 SVG; optional candidate remains unpromoted |

The full R 4.6.1 finalizer passes 30/30 combined checks. It replays the 123-row
release manifest, the 110 owner execution-input pins, and the 2,548 owner
preservation rows. It also replays each owner static seal, each incremental QA
seal, all candidate identities, the historical H11 independent acceptance and
the coordinator's H11 stop disposition.

## Accepted static candidates

- H07 S7-B:
  `audit/hypotheses/H07/report018_order72j_split_svg_export/candidate/H07_revised_smooth_derivative_pairs_near_eye.svg`,
  SHA-256 `f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57`.
- H09 S15-A:
  `audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_primary_effects.svg`,
  SHA-256 `a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a`.
- H09 S15-B:
  `audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_observed_timing_patterns.svg`,
  SHA-256 `c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3`.
- H11 optional S17 compatibility candidate:
  `audit/hypotheses/H11/report018_order72j_libreoffice_compatibility/candidate/H11_reader_near_eye_curves_arial_safe_margin.svg`,
  SHA-256 `ca613c8860b38625524518d106f0408ad264f90d78ef92bd9abd87f4daad904e`.
  This file is not accepted for promotion.

## Visual-route evidence

The three exclusive visual leases were issued serially and all are explicitly
released. No visual lease remains active.

- H11 lease 001: the direct immutable file-SVG browser call was rejected by the
  browser URL policy. The task-created blank tab was closed and no listener was
  created. Coordinator stop disposition:
  `audit/report_harmonization/report018_order72j_h11_browser_stop_disposition/disposition.md`,
  SHA-256 `6373a09892c90e008946ee1109e2611894a971e42b084cd2881f13d1c0853543`.
- H09 lease 002: the sole bounded `127.0.0.1:43129` bind returned
  `PermissionError: [Errno 1] Operation not permitted` before listener creation
  or content load. No browser tab was created. Stop record SHA-256
  `f34f677cc89d076d51057543ae2809b7093f651bfaac617eb40c0a4d7d5003c7`;
  19-member incremental QA seal SHA-256
  `fcbaa0343d7c797dbf72289304611b7a1d35d842eb510d7f9fc92261af716058`.
- H07 lease 003: the sole bounded `127.0.0.1:43137` bind returned the same
  permission error before listener creation or content load. No browser tab was
  created. Stop record SHA-256
  `8f042f8bf8428e16bef8c5e688c0fbc3383ab2e22263f0568671d3800656a4b8`;
  21-member incremental QA seal SHA-256
  `3d8ddfda564d8ee3a9dd8a1ce0f7dfa60ef2e9ffdb9090660e1993c053abcb39`.

Each owner proved that the failed route left no listener. No candidate,
accepted comparator, source CSV, QMD, test, model, or scientific result changed
during visual QA. No alternate browser surface, retry, escalation, correction
trial, Quarto render, Word generation, LibreOffice run, promotion, commit,
push, or upload occurred.

## Downstream recommendation

The coordinator can now decide whether to release a new, separately bounded
integration stage that uses the accepted-static H07 and H09 SVGs in the Quarto
source. That stage should keep the accepted S17 SVG, not the optional H11
compatibility candidate. Because component-level browser inspection was
blocked, the integrated Quarto HTML and Word candidate must carry the first
actual visual acceptance step at the intended widths before any canonical
replacement or final manuscript handoff.

The later integration stage should also preserve the already approved Table 3
metric order and source fragment, retain the accepted S12 figure without an
MDER legend, keep `H06_daily` excluded, use uppercase panel tags positioned on
the left, and apply the accepted removal of unnecessary "primary" wording only
where the existing language matrix permits it. Final S5 replacement remains
held for the separately released Brown analysis and its scientific review gate.

## Review artifacts

- Combined checks: `component_review_checks.csv`, 30/30 PASS, SHA-256
  `a02e372da02ceb81faba8446281bced5390621df45fea558ba61acdbaf4d701a`.
- Component status: `component_status.csv`, SHA-256
  `a4a58b3a966a6c271c8b439d43bd28ee2624cfdc8f4651343e9b13bf48fdfcf4`.
- Finalizer: `finalize_component_review.R`, SHA-256
  `bbe687d3b269b6a78049bd2ef66b97ab3c0d5683098d298ff8e131c5f74588db`.
- Session record: `component_review_session.txt`, SHA-256
  `d6b909fd385471a407ad9694ff5b45a304a5c17d3cd8b86ec47a4c6aa9241582`.

No candidate is promoted by this review. A new coordinator release is required
before any QMD edit, figure replacement, Quarto render, Word generation, or
Writer instruction.
