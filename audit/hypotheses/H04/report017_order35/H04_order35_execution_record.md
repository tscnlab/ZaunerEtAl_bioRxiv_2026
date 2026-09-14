# H04 order 35 source-only execution record

Date: 2026-08-14  
Working directory: `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026`  
R: 4.6.1  
`digest`: 0.6.39

## Authorized suite invocation

The two prescribed tests were invoked once, in order, after the consolidated
source edits:

```text
/usr/bin/time -p Rscript --vanilla tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R
env H04_ORDER35_AUDIT_CSV=audit/hypotheses/H04/report017_order35/H04_order35_source_audit.csv /usr/bin/time -p Rscript --vanilla tests/hypotheses/H04/test_h04_report017_source_harmonization.R
```

The combined tool response exceeded the client context limit and did not
retain the individual command timing and exit objects. The second command
wrote the complete 37-row audit CSV before stopping: 35 checks passed and two
failed. Its failure message corresponds to
`companion_chunk_allowlist` and `untracked_audit_html_preserved`. The
participant-random-intercept command's individual stdout, runtime, and exit
object cannot be recovered from the truncated response and it was not rerun.
This observability limitation is retained rather than replaced by an invented
runtime or a second invocation.

## Post-failure evidence commands

After the stop, only read-only or evidence-sealing commands were used. They
did not execute a QMD or scientific analysis:

```text
rg -n '"FAIL"' audit/hypotheses/H04/report017_order35/H04_order35_source_audit.csv
shasum -a 256 audit/hypotheses/H04/01_audit_and_plan.html audit/hypotheses/H04/02_implementation_and_v0_comparison.html
stat -f '%N|size=%z|mtime=%Sm|ctime=%Sc|birth=%SB' -t '%Y-%m-%dT%H:%M:%S%z' audit/hypotheses/H04/01_audit_and_plan.html audit/hypotheses/H04/02_implementation_and_v0_comparison.html
Rscript --vanilla -e '<display-only companion chunk SHA-256 extraction>'
git diff --no-ext-diff --binary --output=audit/hypotheses/H04/report017_order35/H04_order35_exact_source_diff.patch -- notebooks/hypotheses/H04.qmd audit/hypotheses/H04/H04_analysis_preparation.qmd
```

The chunk extraction established that the test's output-map expectation is
48 characters and omits `6c5b291c3b8ba4cb`, while all other expected changed
chunk hashes match. The HTML inspection established that both excluded pages
match their entries in the accepted Stage 3 manifest and retain modification
times from 2026-08-10 and 2026-08-11.

## Stop disposition

No test expectation or reader source was patched after the single suite. No
test was rerun. No Quarto, model fitting, prediction, simulation, bootstrap,
resampling, Shapley allocation, artifact generation, shared-file edit,
commit, or push was performed. REPORT-017 rendering and the two stored-figure
label refreshes remain held.
