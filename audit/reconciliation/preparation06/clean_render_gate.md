# Preparation 06 clean-render gate

Status: **PASS**  
Verified: 2026-07-30  
Authoritative runtime: R 4.6.1

The gate was reopened after the manuscript-prepared-data reconstruction was
found to split repeated fall-back hours rather than average them as the
manuscript preparation did, and after a direct CSV-to-RDS parity check was
added. The current render below was produced only after those repairs and the
same-model H01 sensitivity adapter passed.

## Authoritative working render

The complete Preparation 06 notebook rendered from executable source with
frozen execution disabled:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=<project R-4.6 library> \
quarto render notebooks/preparation/06_model_ready_datasets.qmd \
  --profile nathealth
```

All 45 knitr steps completed and Pandoc emitted:

`_build/nathealth/notebooks/preparation/06_model_ready_datasets.html`

The rendered HTML has SHA-256
`b9f2a074b3020c1466d6737b9da30ce97080f09c08568e9301b773b5b57f0dd1`
and size 435,390 bytes. It references exactly the intended numerical and
categorical pre-analysis diagnostic figures through output-relative paths.
The copied resources exist under `_build/nathealth/artifacts/` and their
hashes exactly match the authoritative source figures:

- `96210013f9ee40e0d243e721d486b95bcd8f2efbf3000f00ff909fefe3cc705d`;
- `033fb43f955fccd4702fc9f8133bed1e2ff7108a5adf348edd7d0f6687bb7ac6`.

The HTML contains the expected metric registry, main H01 sample table,
manuscript-prepared-data input summary, comparison-gate summary,
numerical-distribution table, categorical-distribution table, and both
distribution panels. It contains no missing-resource marker.

## Stable provenance after regeneration

The final render regenerated each preparation stage without changing its
content identity:

| Stage | Manifest SHA-256 |
|---|---|
| Model-input normalization | `e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab` |
| Site/solar context | `727f48016f430d1d48f1fe091c47bc7721011d72786fc691f3ca0d25a0a8386b` |
| True-time sequence provenance | `d05f8cf2ba7f5be01ae2fa5eb9c27350da2f84ed07508a731e243f1db23e1bb6` |
| Base model data | `fd48dc5d1ecd5da125dd2c360c32239f0adfe7009eca881f5838b0e61b81b13d` |
| Main H01 model data | `48f7cb7a9539bd1a35237275187a76528f1daacfc9abe368cbc4bc1397ed0375` |
| Manuscript-prepared-data inputs | `af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267` |
| Manuscript-prepared H01 model data | `672312ba62871317b0910fbd781f7f6db92e6718fed26961e17a986a5eb989f5` |
| Pre-analysis comparison | `a6ed6cbb184383fb7b649ae9b67e8d5c44e24fffb3ff3fbb8af52fbb252e768c` |

## Verification

`audit/scripts/verify_preparation06_html.R` independently checks the eight
preparation and H01 manifest hashes, required HTML content, both
output-relative image references, and byte identity between the copied and
authoritative image files. It passes under R 4.6.1.

The main H01 and manuscript-prepared-data builders additionally pass
independent reconstruction, deterministic rebuilding, CSV/RDS agreement and
deliberate-corruption rejection. The H01 sensitivity rejects an undeclared
file and a coordinated RDS, CSV and manifest alteration through its
independent reconstruction. Main and sensitivity H01 artifacts share
implementation fingerprint
`e07db16818e565aff40fa6b9f79f34a31eb943d6c393343ca96471b795bacbed`
and shared-code hash
`c7d66825c359066ec6dce1a623408d532c4686fd0b77bfe1da5e392fcc7f5516`,
while retaining different data-scenario identifiers.

## Reopening conditions

Reopen after any change to a pinned manifest, Preparation 06 source, Quarto
profile, execution directory, image path, output format, or diagnostic figure.
