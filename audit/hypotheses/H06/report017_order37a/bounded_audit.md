# H06 REPORT-017 order-37a bounded source audit

Date: 2026-08-15

Status: assembled for the one authorized source-only verifier run

## Scope and preflight

All 16 files in the sealed order-37a dispatch manifest matched their required
SHA-256 identities and byte counts before editing. The companion source, the
stopped order-37 verifier, and every stopped order-37 evidence file remain
byte-identical. This follow-up does not include H06 daily, a Quarto render,
QMD execution, scientific computation, or artifact regeneration.

The independent disposition classified 16 stopped assertions as verifier
classification defects and one as a reader-source preservation defect. The
only scientific text repair restores the accepted visible sentence containing
the three-predictor FDR-adjusted p = 0.298. No result was recalculated.

## Assembled source identities

- Result source: `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`,
  60,677 bytes.
- Companion source: `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`,
  59,613 bytes.
- Worker handoff: `21b37d161f07ec27a2802239a3999621f484b9d697c7cddaf3a73f6c09fe4e90`,
  11,453 bytes.
- New order-37a verifier:
  `fd8b4b5243d9942075a4845ea3fe21ace64fd5cc62300d8cd42b4b86c3eadb61`,
  52,962 bytes.

## Static evidence

- Exact source diff:
  `3fdf8165340f0a4c9bfdb155adf32ee51839e26dbb52842dd445ae655691b45a`.
- Reverse-substitution proof:
  `ce3b873aada159292f329a07e47bca3a07324f483086c1fb9d3a3731de4947d9`.
- Protected inventory:
  `4b1d3671b4c003cb89c0f1a4f4693c224497899c9131d97e47a3faf0e5d04eeb`,
  containing 94 protected paths.
- Package-version inventory:
  `f9ee302df3c59a61f9812678914638e9c820057bf6efa406e300fc05b7d7652c`.

The exact diff reverses the result and handoff to the stopped order-37 bytes.
The historical order-37 diff then reverses those stopped bytes to the accepted
pre-order-37 sources. The companion is unchanged in both substitutions.

## One-shot seal

The authorized command is:

```sh
Rscript tests/hypotheses/H06/test_h06_report017_source_harmonization_37a.R
```

It must use R 4.6.1 with the normal project profile and narrowly elevated
read/write access only to the existing user-owned renv cache. The verifier
will write the execution record, combined defect list, pre/post identities,
and non-circular order-37a source manifest. Those sealed outputs control the
final PASS or stopped-state disposition. No retry is authorized.
