# REPORT-018 owner order 48c: H06_daily no-rerender verifier and result acceptance

Date: 2026-08-21

Owner: H06_daily task `019fec6a-20d3-7710-ab9b-a035e0874182`

Status: **AUTHORIZED ONCE AS A TEST-ONLY, NO-RERENDER CONTINUATION**

Target already rendered: `notebooks/hypotheses/H06_daily.qmd`

The H06_daily companion and every later REPORT-018 render remain held.

## Authority and exact purpose

Order 48b successfully completed the sole H06_daily result render under the
normal profile. The final HTML is SHA-256
`74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`,
11,946,551 bytes. The semantic hook repaired exactly 14 tables, 113 `id`
attributes, 705 `headers` attributes, and 818 substitutions with exact raw
reversal and reapplication.

The unchanged focused verifier then stopped because it used
`rvest::html_element()` and applied `length()` to the returned `xml_node`.
Both the pre-hook and post-hook HTML contain exactly one matching main element;
the observed value two is the number of children of that one node. This is a
verifier defect, not a page defect.

Independent acceptance is sealed at:

- `audit/report_harmonization/report018_h06_daily_order48b_verifier_stop_independent_acceptance.md`,
  SHA-256
  `56aea8f135784bb59de80a91a5103ade23255648a33701701cf0670497c043b5`;
- its 20-row non-circular manifest, SHA-256
  `a1835fa30e478b1da95a16f175c6d196fb342e2781b849a8752dba6fa45bfc62`;
  and
- `scripts/report_harmonization/check_h06_daily_order48b_verifier_stop.R`,
  SHA-256
  `35001c9b2f2de1c85fa0472a63b23f361d721400eb0a27722d05c1f5118fbf82`.

The complete downstream protected-set audit found ten expected evidence
additions relative to the pre-render inventory. They are sealed, with exact
hashes and byte counts, at:

- `audit/report_harmonization/owner_orders/48c_h06_daily_authorized_evidence_additions.csv`,
  SHA-256
  `39e36b34ea787ff109994efd0768a036e2e7a22b47a1c7de63a3b3967f82ca9a`,
  ten rows.

The exact verifier transition is sealed at:

- `audit/report_harmonization/owner_orders/48c_h06_daily_authorized_verifier_transition.csv`,
  SHA-256
  `a293539fadfcef6b51c31f239a0b07506f01ce206d367509367376f85b689466`,
  one row.

Order 48c authorizes only the exact two-hunk test classification below, one
post-render verifier run against the existing HTML and semantic evidence, the
remaining secure-loopback QA, one post-QA verifier run, and a final seal. It
does not authorize a Quarto command or any page, source, display, or science
change.

## Hard preflight pins

Before any edit:

1. Run once:

   ```text
   Rscript --vanilla scripts/report_harmonization/check_h06_daily_order48b_verifier_stop.R
   ```

   Require the exact PASS line beginning:

   ```text
   H06_DAILY_ORDER48B_VERIFIER_STOP=PASS owner_rows=32 protected_unchanged=3368 html_transition=1 tables=14 substitutions=818 main_matches=1
   ```

2. Verify the 20-row independent acceptance manifest exactly and verify both
   order-48c classification manifests at the identities above. The ten
   evidence paths must be the complete current addition set produced by the
   unchanged protected-set builder. There must be no eleventh path.
3. Require these live identities:

   - result QMD:
     `8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`,
     65,349 bytes;
   - result HTML:
     `74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`,
     11,946,551 bytes;
   - focused verifier preimage:
     `aca33f5815bb34979513caa7a50a9a38ba66e7bb22d228c8c04f6afb010e42f7`,
     63,149 bytes;
   - semantic summary:
     `bafde8ff09dda671e725d72adfa458f58bd599cba41a6881ed5a75862c9a917a`;
   - semantic ledger:
     `09fde59b3495da6e3bac7b6e0d389d09fa7ded61c5a5c72283913945e4ea310e`;
   - semantic reversal:
     `ad34e4bd128448d90354bdb65d527a0681648d71f6c53c578804b4993fc85e2c`;
   - companion QMD and held HTML:
     `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`
     and
     `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`;
   - profile:
     `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
   - display manifest:
     `395c112968c00294cbc085246894feae9cd7746e4e5c5714b96cb9e59fd90fc6`;
     and
   - corpus manifest:
     `73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334`.

4. Require the preserved semantic directory
   `/private/tmp/H06_daily-order48b-semantic.SbpRAI` to contain exactly the
   ledger and summary at the durable hashes above. Confirm no H06_daily Quarto,
   Pandoc, hook, browser, or loopback process is active.

Stop before editing on any mismatch.

## Sole permitted test edit

Edit only
`tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R`.
No other live project file may change before verification.

### Main-element cardinality

In the existing semantic-invariance block only:

1. change the two calls from `rvest::html_element()` to
   `rvest::html_elements()`;
2. retain the exact `length(...) != 1L` assertion and its exact message; and
3. after the assertion, assign the sole nodes with
   `pre_main <- pre_main[[1L]]` and `post_main <- post_main[[1L]]`.

### Exact historical-evidence and self-transition classification

In the existing post-render protected-delta block only:

1. read the ten-row evidence-addition manifest and require every listed live
   path, SHA-256, and byte count exact;
2. read the one-row verifier-transition manifest and require the current
   verifier to equal its postimage;
3. classify as authorized only:
   - the existing exact result-HTML transition;
   - exactly the ten sealed `ADDED` evidence paths with matching live hashes
     and bytes; and
   - exactly the one stopped-to-current verifier `CHANGED_CONTENT` transition
     with matching preimage and postimage hashes and bytes;
4. fail on an eleventh addition, a second verifier transition, any missing
   classified path, any changed classified identity, or every other delta;
   and
5. preserve every other test gate and message byte-for-byte.

The dispatch manifest for this order is stored beside this order in
`audit/report_harmonization/owner_orders/` and therefore is not a member of
the legacy dynamic protected-set pattern. Do not move or duplicate it into a
matched `report018_h06_daily*` path before post-QA verification.

The required verifier postimage is:

- SHA-256
  `54ed2e2ece2e90d1e316f3a94869b280d0cc7487b88df9ba480f560f7b25f543`;
- 66,167 bytes.

Require an exact two-hunk reverse substitution to reproduce the preimage SHA
and byte count. Require R parse and `air format --check` to pass. Do not run a
preliminary test.

## One post-render verifier execution

Do not create a new order-48c owner-evidence directory before this verifier
run. This keeps the complete authorized evidence-addition set at exactly ten.

Run exactly once:

```text
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 ORDER48A_VERIFY_PHASE=postrender GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order48b-semantic.SbpRAI R --vanilla --slave -f tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R
```

This is a verifier run against preserved outputs, not QMD execution. Require
the `ORDER48A_POSTRENDER=PASS` result. It must reproduce:

- exact semantic reversal and visible/structural invariance;
- exactly 14 native gt tables, five figures, and seven dynamic links;
- three distinct predictor-specific 15 by 4 placement-table bodies;
- exact durable and embedded figure identities and paired source links;
- unique document IDs and every explicit table-header token resolving once;
- the accepted reader hierarchy, links, active navigation, country-coded
  sites, zero execution defects, and no unresolved internal target;
- only classified build deltas; and
- 3,379 current protected members, consisting of the pre-render set plus the
  exact ten evidence additions, with only the accepted HTML and verifier
  content transitions.

Stop without patch or rerender on any new failure.

## Secure-loopback QA and post-QA verification

Only after the post-render verifier passes, serve `_build/nathealth` through
one read-only server bound to `127.0.0.1`. Inspect only the current H06_daily
result page at 1440 by 1000, 708 by 1000, and 720 by 500, plus the original and
170-mm figure sizes.

Inspect all 14 tables and five figures, especially the distinct Tables 5 to 7
and repaired Figures 1 to 4. Verify typography, scrollers, axes, legends,
symbols, labels, panels, captions, disclosures, links, navigation, clipping,
overlap, wrapping, and horizontal page overflow. Require Figures 1 to 4 to
remain at least 7.0 effective points at 170 mm and 708 pixels, and Figure 5 to
remain exact.

Write the required QA evidence only inside the existing excluded directory
`audit/hypotheses/H06_daily/report018_order48a_display_repair/`. Stop the
server, prove no listener remains, reset the viewport, and close the QA tab.

Then run exactly once with `ORDER48A_VERIFY_PHASE=postqa` and the same root and
semantic directory. Require `ORDER48A_POSTQA=PASS`, complete build/protected
stability, and a non-circular acceptance manifest. Only after that PASS may
the owner create a new order-48c completion record and non-circular seal.

## Prohibitions and return

No Quarto command, QMD edit, source-data edit, display regeneration, candidate
iteration, artifact promotion, HTML edit, model, fit, refit, prediction,
simulation, resampling, estimate, interval, p-value, FDR, diagnostic,
scientific artifact change, helper, broad builder, profile, package, lockfile,
ledger, manuscript, companion, later target, full-project render, commit, push,
upload, deletion, or publication action is authorized.

Return one complete no-rerender result-page acceptance package or one genuine
new combined stop. The H06_daily companion and every later REPORT-018 render
remain held pending independent result acceptance.
