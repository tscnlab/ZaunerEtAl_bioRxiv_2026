# H06 order-37a one-shot execution record

Status: PASS
Verifier body started UTC: 2026-08-14 23:25:59 UTC
Sealed UTC: 2026-08-14 23:26:01 UTC
Environment startup elapsed seconds before verifier body: 15.774
Verifier pre-seal elapsed seconds: 1.914
Total process elapsed seconds before seal: 17.688
Expected verifier exit status: 0
Checks evaluated: 178
Defects before manifest seal: 0
R version: 4.6.1
openssl version: 2.4.2
renv cache boundary: existing user-owned ~/Library/Caches/org.R-project.R/R/renv.
The normal project profile had approved narrow read/write cache access only.

Command:

```sh
Rscript tests/hypotheses/H06/test_h06_report017_source_harmonization_37a.R
```

Historical order 37: R 4.6.1 evaluated 171 checks and stopped with 17 sealed defects after its authorized environment-startup retry.
Before that run, one sandboxed startup process spent about 75 minutes in the documented renv transient-cache loop and never entered the verifier body.
No preliminary R or project test was run. No Quarto command was run.
The QMDs were parsed as text only and were not executed.
The three historical H06 tests were not run.
The manifest mismatch sets were audited as historical identity context.
The order-37a source patch and historical order-37 patch were reversed only inside an R temporary directory.
Pre/post identity rows: 103

Combined defect list: defect_list.csv contains its header only.
