# REPORT-018 Order 70d preflight environment stop

Date: 2026-09-02

Status: `PASS_ENVIRONMENT_ONLY_STOP_RESOLVED`

The first prospective Order 70d checker invocation was interrupted before the
checker loaded. It was confined to the `renv` profile startup path and was
waiting in the sandbox lock-acquisition loop. The sampled stack contained no
Order 70d checker frame. The process was interrupted, exited with status 1,
and PID 20901 was confirmed absent.

The diagnostic sample is preserved as
`audit/report_harmonization/nathealth_final_landing_integration_2026_09_02/order70d_renv_startup_sample.txt`,
SHA-256 `135e23262793937e86d611a310ad840bcf3df7a8cd211b03ecf402fa82002ffb`,
88,323 bytes.

The unchanged prospective checker was then run under R 4.6.1 with
`RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`, `Rscript --vanilla`, and the accepted
project library
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. Package versions were
digest 0.6.39, jsonlite 2.0.0, readr 2.2.0, and xml2 1.6.0. The complete replay
passed. No candidate or production content was written.

