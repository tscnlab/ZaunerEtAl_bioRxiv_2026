# H05 Order 72c native-vector legend handoff

Mandatory gate: `REPORT018-ORDER72-SVG-REVIEW`

Status: **CANDIDATE_READY_FOR_SHARED_QA**

## Candidate

The repaired native SVG candidate is:

`audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/candidate/H05_reader_near_eye_effects.svg`

- SHA-256: `e9d7d60100403aea3ac25282f9be33f981b182a09e74479cd160bdc296ae63b3`
- Size: 66,573 bytes
- Canvas: 648.00 pt by 648.00 pt
- ViewBox: `0 0 648.00 648.00`

This is an owner candidate, not visual or central acceptance. Order 72b section
A assigns original-size and 643 by 643 pixel visual comparison to the
Harmonizer.

## Exact sealed implementation

The central prospective exporter was copied byte-for-byte to the new repair
root and invoked exactly once under R 4.6.1 with
`RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` and `Rscript --vanilla`.

- Copied exporter SHA-256: `d3260f625ae8664136de91daacff97cd329456ac0a09100e2f29f95204a9dabd`
- Copied exporter size: 24,295 bytes
- Copied static-review SHA-256: `503e1c16939bb0df11c7e9b080a9f0db861d702c4fdb5d8b2822a5964acd47b5`
- Runtime 21-row owner-manifest SHA-256: `85e7f533d4408ad42f80589e377fdeb5b56ca915ee418452ce7e0daf11a2eccb`

The three patch-map postimages each occurred exactly once. Reversing them
reproduced the stopped exporter byte-for-byte at SHA-256
`dbaf4f34f5383c36b87955bfb03f8f277313829bdb2b2810e8afbea80169a389`.
The copied exporter parsed under R 4.6.1 and every required namespace resolved
from the accepted user and R system libraries before execution.

## Legend-only preservation

The centrally sealed checker was invoked exactly once. All five gates passed:

- the old candidate contained exactly one embedded legend image;
- the repaired candidate contains exactly 300 native legend rectangles and no
  embedded image;
- all 300 ordered legend colours are exact;
- all 101 visible SVG text nodes are exact and in the same sequence; and
- removing only the old and new legend elements leaves the complete normalized
  SVG DOM identical.

Checker evidence:

- `legend_only_preservation_checks.csv`: SHA-256
  `004d41351ec40318523fef751d06cc4acb44348c23d171735116e539ffa670e2`
- `old_svg_without_legend.xml`: SHA-256
  `571127928bdfc1de457b4f469cd9a1941b82152a355225d63d96a199e13829b7`
- `new_svg_without_legend.xml`: SHA-256
  `571127928bdfc1de457b4f469cd9a1941b82152a355225d63d96a199e13829b7`

## Authority and preservation

Before copying, the Order 72c release passed 188 of 188 identities, the
original release passed 71 of 71, the Order 72b recovery passed 163 of 163,
all eight stopped H05 files were exact, all five original H05 inputs were
exact, and the new repair root was absent. The same 188, 71, 163, eight-file,
five-input, and 21-member checks passed after export and legend verification.
The stopped H05 candidate and its seven companion files remain byte-identical.

Commands executed for the authorized candidate and preservation check were:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/export_h05_reader_near_eye_effects_svg.R
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72c_h05_native_legend/check_h05_legend_only.R audit/hypotheses/H05/report018_order72_svg_export/candidate/H05_reader_near_eye_effects.svg audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/candidate/H05_reader_near_eye_effects.svg audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair
```

No device probe, rasterizer, owner visual QA, model read, prediction, inference,
scientific calculation, broad builder, source-data regeneration, Quarto,
knitr, Pandoc, manuscript render, canonical edit, package change, commit, push,
or upload occurred. All new durable files are confined to the authorized
`vector_legend_repair` root.
