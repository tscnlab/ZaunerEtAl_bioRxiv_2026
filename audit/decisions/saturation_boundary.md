# Melanopic EDI operating-range boundary

Decision ID: `SIGNAL-001`  
Status: approved preregistration deviation; preparation rerun verified,
downstream metric/model rerun pending  
Decision date: 2026-07-30

## Decision

Retain ActLumus melanopic EDI observations only when
\(\mathrm{MEDI} < 100{,}000\) lx. Values at or above 100,000 lx are outside
the retained operating range and become analytically missing with an explicit
operating-boundary reason flag. Raw values remain preserved. The internal
field name `medi_saturated` is retained for compatibility but is not treated
as evidence about the physical mechanism of the invalid reading.

The boundary is applied after each native-epoch source stream has been
aggregated to the canonical one-minute interval, matching the analysis unit
at which the current preprocessing applies its range rule.

## Evidence

The official ActLumus User Manual, version 2.1.0, specifies the light sensor
as photopic, melanopic, and spectral and gives an operating interval of
`1 – 100.000 Lux` (PDF page 16, printed page 16). The archived primary source
is:

- file: `audit/evidence/ActLumus_User_Manual_EN_2_1_0.pdf`;
- source:
  `https://condorinst.com/wp-content/uploads/2023/02/Manual_ActLumus_EN_2_1_0.pdf`;
- SHA-256:
  `30a26572e1f431ad7ad231d8fce8a9925b44ea2f55c00972ff050eb722ec0e60`;
- pages: 21;
- searchable coverage: 21 text, 0 sparse-text, and 0 no-text pages;
- indexed page:
  `audit/evidence/.pdf-index/ActLumus_User_Manual_EN_2_1_0-30a26572e1f4.json`.

The companion dosimeter-placement manuscript states that only observations
below the manufacturer's maximum operating range were retained and gives the
rule as `<100,000 lx melEDI` (source `index.qmd` line 162; rendered PDF page 9,
manuscript lines 235–236). The verified source is:

- repository tag: `v1.0.0`;
- commit: `15b3e28e763c2f49ca9ae861d117e2c42e28743d`;
- SHA-256:
  `9cf8309c753d6ad753ac1d772927996d1035f59dadfa3b62523a810897ca67e3`;
- pages: 66;
- searchable coverage: 64 text, 1 sparse-text, and 1 no-text page;
- exact queries: `100,000`, `100000`, `10^5`, `upper measurement`,
  `measurement range`, and `ActLumus`.

The manual establishes the manufacturer-reported upper endpoint; the
companion analysis and the author's decision establish the conservative
strict implementation (`MEDI <100000`). Public-facing prose calls \(10^5\) lx
the upper operating boundary rather than claiming that the physical
saturation mechanism was independently verified.

The signed preregistration instead specified values above 120,000 lx. This is
therefore an explicit, author-approved device-range deviation rather than a
silent boundary repair.

## R-verified baseline scope

The saved stage-1 objects already mask the former upper range, so the
following counts cover the newly affected interval `[100,000, 120,000)`:

| Placement | Retained minutes under the former rule | Participants | Participant-days |
|---|---:|---:|---:|
| Near-eye | 37 | 10 | 13 |
| Chest | 84 | 16 | 21 |

No saved one-minute value was exactly 100,000 lx.

## Clean pinned-source rebuild

The full nine-site Preparation 01 rebuild applied the strict
`MEDI < 100000` rule after source-epoch-aware one-minute aggregation. Its
checksummed `saturation_audit.csv` records:

| Placement | Minutes invalidated at or above 100,000 lx | Participants | Participant-days |
|---|---:|---:|---:|
| Near-eye | 39 | 10 | 13 |
| Chest | 87 | 16 | 21 |

Every site-placement audit row records the 100,000-lx boundary. Photopic
illuminance is not independently thresholded, and the pre-mask melanopic EDI
is retained. The metric, model, display, and claim effects remain to be
quantified in their clean reruns.
