# REPORT-018 Order72j H07 component return

Status: `CANDIDATE_PASS_AWAITING_INDEPENDENT_ACCEPTANCE`.

Mandatory gate: `REPORT018-ORDER72J-COMPONENT-REVIEW`.

## Authority

- Order SHA-256: `ed7c0b94b5ad380e1ec8b29d09aec07eedda9fdfa5c5ad8752f2b9dd913e182a`.
- Independent preflight acceptance SHA-256: `8e5d95479865fa4b71f11a133ae08b6aa2b067976305b190f267ac14d8514cd3`.
- Release manifest SHA-256: `66de5e9a17875b29616c2558994ed6724c61e9179c518da4d143e8f33ae97e8f`, 123/123 live exact.
- H07 execution pins SHA-256: `683c0ee307d3f3bfc9926ca6eb05b735f21260baecb0354fc583bfda0d573496`, 39/39 live exact.
- H07 preservation inventory SHA-256: `e8bfc8031fd40796927c8b245a6767a587c3bd17e3f82facb3f142c68a327aaa`, 1451/1451 live exact.

## Candidate

- Path: `audit/hypotheses/H07/report018_order72j_split_svg_export/candidate/H07_revised_smooth_derivative_pairs_near_eye.svg`.
- SHA-256: `f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57`.
- Bytes: `1238493`.
- Native device: `svglite::svglite`, 9 by 18 inches.
- One actual SVG export trial; zero renderer corrections.
- Candidate and retained attempt are byte-identical.
- Export implementation SHA-256: `08d9fe473b24374f2d6f569344adf7ae3835168253c7ceb18d07629fb859a34f`.

## Frozen-source and static gates

- Numerical input hashes pass 4/4: fitted smooth 918 rows, derivative 900 rows, qualifying transitions 12 rows across both panel kinds, and rugs 7011 rows.
- Layer-to-row map passes 6/6. All source-row and built-row counts agree, with 18 ordered panels.
- The nine manuscript metric labels and fitted-value-left, derivative-right order pass 18/18.
- Derivative states remain 461 pointwise compatible with zero, 108 detected decreases, and 331 detected increases. Six near-eye metrics retain the derivative-defined plateau pattern and no row is non-estimable.
- SVG XML and vector structure pass 16/16: 648 by 1296 points, matching the 9 by 18 inch canvas; no image, raster payload, script, foreign object or external resource; 37 unique IDs and 37/37 local references resolve.
- Accepted visible text, pointwise qualification, internal title `Near-eye — primary`, palette, and privacy checks pass. No participant identifier occurs in visible text or SVG metadata.
- The accepted PNG comparator and H01 S7-A SVG remain byte-exact under the pre/post inventories.

## Attempt inventory

Six construction/checker stops are preserved. Four occurred before any SVG device invocation, and two occurred only in the post-export static checker. None changed plot data, semantics or the SVG. The sole SVG export succeeded. Detailed causes and remedies are in `attempts/` and `evidence/attempt_inventory.csv`.

## Visual QA and teardown

The Harmonizer has not issued the serial visual-QA lease. Browser QA at original size, 170 mm and 708 px, plus comparison to the accepted PNG, is therefore `NOT_RUN`, not failed. No browser tab, loopback listener or serving root was created. No persistent task process remains, so teardown is not applicable.

## Runtime and scope

R 4.6.1 ran with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` and the existing project R 4.6 library. Package and library identities are in `evidence/session_and_packages.csv`; exact command forms are in `evidence/command_inventory.csv`. No Quarto, Pandoc, Word or LibreOffice command ran. No model or RDS was loaded, and no fitting, prediction, derivative, interval, p-value, multiplicity, bootstrap, simulation or other scientific computation ran. No existing source, artifact, test, manifest, configuration, ledger or accepted figure was edited or replaced.

The non-circular manifest covers every file in this new H07 owner root except itself. No promotion or downstream integration is authorized by this return.
