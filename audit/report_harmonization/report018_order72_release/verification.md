# Order 72 independent pre-dispatch disposition

Date: 2026-09-11

Verdict: revised export specification accepted for bounded candidate execution.

The initial proposal had the wrong H02 owner and omitted nine display
dependencies. Those findings were returned together before any owner wakeup.
The revised proposal at SHA-256
`d3f329a2149149663c47e5db4514cbb7771b0afb6362afc8b911871068d0ebcd`
corrects the owner and pins all nine dependencies. The central R 4.6.1 replay
reports `ORDER72_INPUT_PINS=37/37`, with 37 unique paths and no mismatch.

The review traced the actual H02 pointwise layout helper, H05 common colour
scale, H06 site palette, H08 factor order, H10 selection text, and H11 lower
panel, night shading, and sample labels. Export code must use those stored
display inputs without calling model or prediction paths. H02's frozen RDS
contains plotting data, not a required live model. The source records retain
participant-level plotting values; SVG output may not expose participant
identifiers or embed hidden data payloads.

This is input and scope verification, not advance acceptance of SVG candidates.
Visual equivalence, vector structure, privacy, and no-drift remain mandatory
owner and independent-acceptance checks.

Temporary independent review evidence:
`/private/tmp/order72-central-review.XB31I8/`

Command:

```text
Rscript --vanilla /private/tmp/order72-central-review.XB31I8/audit_order72.R /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 /private/tmp/order72-central-review.XB31I8
```

The reviewer created no figure, model, estimate, prediction, report, or render.
The six destination tasks were checked in the app and were not running before
release. H02 is `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`.

The earlier H01 MDER pilot-status report was superseded by the independently
accepted production and integration record
`audit/report_harmonization/report018_h01_metric010_final_independent_acceptance.md`,
SHA-256 `f15aec679dd53ecd66d6e096ea0486ff2b2015602caac81ca792a7fa65a64cb6`.
It is not an outstanding dispatch in this export queue.
