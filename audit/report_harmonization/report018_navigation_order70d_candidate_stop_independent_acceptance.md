# REPORT-018 Order 70d candidate stop independent acceptance

Date: 2026-09-02

Status: `PASS_FAIL_CLOSED_STOP_ACCEPTED`

The Order 70d candidate stop is accepted as a validator-only cardinality
defect. The retained candidate transformation itself is valid and must not be
regenerated.

Independent R 4.6.1 and xml2 1.6.0 validation reproduces exactly 2,776 IDREF
rows: six `aria-labelledby`, six `aria-describedby`, one `aria-controls`,
2,762 `headers`, one `data-bs-target`, and zero `data-target` rows. Every token
resolves to exactly one of 593 document IDs, and there are zero duplicate ID
values. The implementation's expected total of 2,775 omitted its own single
Bootstrap target row.

The complete retained-candidate static replay passes: 893 regular files, zero
symbolic links, 891 byte-identical accepted members, all other 36 HTML routes
byte-identical, 28 authors, 19 semantic tables, 20 figure endpoints, 2,762
resolving table-header tokens, 124 resolving manuscript fragments, 74 embedded
images, exact manuscript main children, exact 20 site scripts, and 46,071 of
46,071 local references resolved. The Brown figure is the exact accepted SVG
at `200e85cb...`, 108,600 bytes.

The retained candidate landing page is `c8abe2f9...`, 29,023,063 bytes, and
its Word download is the exact accepted `6cd59239...`, 28,792,333 bytes.
Production remains unchanged at landing page `600b7a3d...`, corpus manifest
`5d66d43d...`, and an absent Word download.

The owner stop record reproduces at SHA-256
`d46ab2c1cad9185ccaf594396b01638853c5c14b0adc9d07905e1bdbdc48ec26`,
1,710 bytes. Its eight-row non-circular seal reproduces at SHA-256
`d38ffc8ec4178d0ff9878cac08ad8ad1c1ddfdcd0c82759bc786cfd6bc156e36`,
1,366 bytes.

No browser QA, promotion, production mutation, Quarto render, QMD execution,
scientific calculation, or candidate regeneration occurred.

