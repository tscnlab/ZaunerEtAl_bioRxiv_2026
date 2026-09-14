# Checker and visual iteration record

Date: 2026-08-31

The first execution used R 4.6.1 and stopped before opening a graphics device or creating any output. The exact failure was the site-order guard `identical(site_display_order, 1:9)`: `readr` had correctly loaded the exact values 1 through 9 using numeric storage, while `1:9` uses integer storage. This was only a checker type defect. It exposed no source-data, display-value, or scientific defect. The corrected guard casts the observed values to integer and separately requires every observed value to be whole-valued.

The first successfully built provisional candidate had SHA-256 `3d4b072964aa2ad4b74f132ef7a61ed83cb34884dddaba0f321f27fca93ccaf8`. Candidate-first inspection found one display-only defect: panel b's expanded FDR subtitle clipped at the right edge. The source rows, estimates, confidence intervals, panels, tags, site order, and colours were intact. The provisional files were moved intact to `/private/tmp/h10-selection-v1.M59HyC` and are not part of the candidate package.

Only the panel b subtitle was shortened. The final candidate was then rebuilt from the same pinned 322-row CSV. No model, prediction, bootstrap, report, selection document, canonical artifact, source-data file, manifest, or accepted table was changed or rendered.

After the first complete seal, the author superseded the lowercase-tag convention with bold uppercase A, B, and C positioned at the left side of their respective panels. The sealed lowercase candidate, SHA-256 `37c4021eab7d851df9a865c5d7788f21bff4a82935693944eb081144fa960112`, and its generated evidence were moved intact to `/private/tmp/h10-selection-lowercase-seal.RW5Rsf`. They are not part of the active candidate package. The uppercase amendment changes only the panel tags and matching caption references.

The first uppercase build command then stopped before opening a graphics device or creating any output because the coordinator-owned selection QMD had changed from the earlier released SHA-256 `d3bc63e3715fdf41daea48129b0107ee330e98ec7e3654efafa235ed01121c23` to `f430fe5bcbb6e40420a80797e8858d6b5ce42a7a046ad2da73877ae925c7acf3`. Read-only inspection showed that the changed H10 coordination note exactly encoded the author-wide uppercase-tag amendment. The coordinator independently confirmed `f430fe5bcbb6e40420a80797e8858d6b5ce42a7a046ad2da73877ae925c7acf3`, 50,118 bytes, as the authoritative replacement pin. The selection HTML remained intentionally unchanged. The build resumed only after that explicit repin.
