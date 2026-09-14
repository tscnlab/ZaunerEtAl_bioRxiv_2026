# Execution record

R 4.6.1; R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library; RENV_CONFIG_AUTOLOADER_ENABLED=FALSE. Rscript --vanilla.

Final sequence:

```text
build_candidate.R attempt_04
verify_candidate.R attempt_04
finalize_package.R
```

Only accepted result-string extraction/formatting, descriptive fraction verification, source/static markup checks and file/provenance operations were run. No models, predictions, estimates, intervals or adjusted p-values were recalculated.

Attempt 01 retains parser/newline/attribute-representation checker stops and their diagnoses, followed by a passing v4 verifier. Attempt 02 added content-aware container width and passed all 1,111 checks. Attempt 03 stopped at an unnecessary newline escape in the cumulative-record checker. Attempt 04 corrects that checker, reconciles the SI reference, widens the first Table 2 column and passes all base checks. Every meaningful stopped candidate remains unchanged.

A read-only inline inspection also stopped after printing diagnostics because of a stray closing brace; it changed no file. Package evidence does not depend on that stopped command.

The supplied historical screenshot was inspected and copied byte-exact. It controls layout concept only, never current estimates. No new capture was attempted.

The package manifest excludes itself and its detached checksum seal. All other package files are listed by relative path, byte size and SHA-256. No file is changed after sealing.
