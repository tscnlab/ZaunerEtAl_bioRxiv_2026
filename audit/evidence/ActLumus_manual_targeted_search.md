# Targeted ActLumus manual search

Date checked: 2026-07-30  
Method: `$search-pdf` targeted page-level indexing and retrieval

## Source

- Title: *ActLumus User Manual*
- Version: 2.1.0
- Source URL:
  <https://condorinst.com/wp-content/uploads/2023/02/Manual_ActLumus_EN_2_1_0.pdf>
- Archived file:
  `audit/evidence/ActLumus_User_Manual_EN_2_1_0.pdf`
- Bytes: 1,164,497
- SHA-256:
  `30a26572e1f431ad7ad231d8fce8a9925b44ea2f55c00972ff050eb722ec0e60`
- PDF pages: 21
- Encryption: none
- Search index:
  `audit/evidence/.pdf-index/ActLumus_User_Manual_EN_2_1_0-30a26572e1f4.json`
- Searchable coverage: 21 text, 0 sparse-text, 0 no-text pages
- Pages requiring OCR or separate visual inspection: none
- Page 16 table layout: visually inspected against a 150-dpi render; the
  extracted range and precision are in the Light Sensor row, not the preceding
  Temperature Sensors row

## Query log

Exact queries:

- `Operating Range`
- `Operating interval`
- `100.000 Lux`
- `100,000`
- `Light Sensor`
- `Precision`

## Results

| Query | PDF page | Printed page | Context and relevance |
|---|---:|---:|---|
| `Operating Range` | 16 | 16 | A temperature-sensor range appears immediately before the separate light-sensor specification; it is not the light-exposure boundary. |
| `Operating interval` | 16 | 16 | The light-sensor section specifies photopic, melanopic, and spectral outputs and an operating interval of 1–100,000 lx. |
| `100.000 Lux` | 16 | 16 | Exact European-number-format hit for the light-sensor upper endpoint. |
| `100,000` | — | — | Not found in searchable text; the manual uses `100.000`. |
| `Light Sensor` | 5, 8, 16, 20 | same | Page 16 contains the substantive specification; other hits identify hardware or normal operation. |
| `Precision` | 16 | 16 | The light-sensor specification reports typical precision of 10% at 1,000 lx. |

## Interpretation

PDF page 16 is the sole page needed for the present decision. It is a primary
manufacturer source for the reported upper operating endpoint of 100,000 lx.
It does not identify a physical failure mechanism and writes the range with
inclusive dash notation. The companion placement manuscript implements the
conservative strict rule `<100000 lx melEDI`; the author approved that same
strict endpoint for the present analysis. Accordingly, public-facing text
uses “upper operating boundary” and does not claim independently demonstrated
sensor saturation.

## Ranked pages for detailed reading

1. PDF/printed page 16: light-sensor spectrum, operating interval, precision,
   and manufacturer qualification.
