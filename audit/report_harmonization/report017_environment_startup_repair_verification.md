# REPORT-017 environment-startup repair verification

Date: 2026-08-13  
Scope: normal R 4.6.1 project startup only  
Status: **startup smoke passed; one Descriptives target render may be released after its reader-only wording repair is sealed**

## Boundary

This verification followed the bounded request in
`report017_environment_startup_repair_request.md`. It did not render a Quarto
document, execute a scientific calculation, install or update a package, edit
`renv.lock`, bypass the project profile, or change a reader source, scientific
artifact, or build output.

The active parent environment had `HOME=/Users/zauner` and
`TMPDIR=/var/folders/9p/326_k3kx43qbn_cyl1rqfhb00000gn/T/`. `R_HOME`,
`R_LIBS`, `R_LIBS_USER`, `R_PROFILE`, `R_PROFILE_USER`, `RENV_PROJECT`,
`RENV_PATHS_CACHE`, `RENV_PATHS_LIBRARY`, `RENV_PATHS_SANDBOX`,
`RENV_CONFIG_SANDBOX_ENABLED`, and `RENV_CONFIG_SYNCHRONIZED_CHECK` were all
unset.

## Reproduction and exact cause

The bounded normal-profile smoke was:

```text
/usr/local/bin/Rscript -e '<print R, project, renv, and .libPaths()>'
```

Under the restricted workspace sandbox, it did not reach the expression. It
was interrupted after 35.50 seconds. Its R traceback ended at:

```text
renv_sandbox_activate_impl(project)
renv_scope_lock(lockfile)
renv_lock_acquire(path)
renv_lock_acquire_impl(path)
```

A diagnostic-only `R --vanilla --slave` session loaded the existing project
copy of renv 1.2.3 and resolved the exact sandbox and lock paths as:

```text
/Users/zauner/Library/Caches/org.R-project.R/R/renv/sandbox/macos/R-4.6/aarch64-apple-darwin23/46003b10
/Users/zauner/Library/Caches/org.R-project.R/R/renv/sandbox/macos/R-4.6/aarch64-apple-darwin23/46003b10.renv-lock
```

An explicit diagnostic `dir.create()` of that exact lock path under the
restricted sandbox returned `FALSE`, left no path, and reported:

```text
cannot create dir '.../46003b10.renv-lock', reason 'Operation not permitted'
```

The renv 1.2.3 implementation retries a `FALSE` return from this
`dir.create()` without sleeping. The failure therefore explains both the
observed CPU-active loop and the repeated `dir.create()` and `file.info()`
frames. The problem was execution permission for renv's user-cache lock. It
was not a broken project library, stale symbolic link, package defect, reader
source defect, or scientific computation failure.

## Smallest environment repair

No file was edited. The smallest repair is to run profile-dependent R and
Quarto commands with narrowly elevated access to the existing user-owned renv
cache. This permits renv to create and remove its transient sandbox lock while
retaining the ordinary project `.Rprofile` and `renv/activate.R` path. It is
not a profile bypass and does not alter the project library or lockfile.

## Confirming normal-profile smoke

The confirming command used the normal project profile with the environment
repair above:

```text
date '+start=%Y-%m-%dT%H:%M:%S%z'
/usr/bin/time -p /usr/local/bin/Rscript -e '<print R, project, renv, and .libPaths()>'
```

It completed inside the 30-second smoke window:

```text
start=2026-08-13T09:21:17+0200

NOTE: Dependency discovery took 16 seconds during snapshot using current .renvignore specifications.
Consider modifying .renvignore or switching to explicit snapshots.
See `?renv::dependencies` for more information.

startup_complete=TRUE
R=R version 4.6.1 (2026-06-24)
platform=aarch64-apple-darwin23
project=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026
renv=1.2.3
renv_path=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23/renv
libpaths_begin
/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23
/Users/zauner/Library/Caches/org.R-project.R/R/renv/sandbox/macos/R-4.6/aarch64-apple-darwin23/46003b10
libpaths_end
real 16.50
user 16.02
sys 0.30
end=2026-08-13T09:21:34+0200
exit_status=0
```

The synchronized dependency check explains the 16-second successful startup
time. It requires no change for this bounded render sequence.

The transient lock was absent after completion. The cache parent and generated
sandbox directory retained their paths and modes. Their modification times
changed from `2026-08-13 09:14:35 +0200` and
`2026-08-13 09:14:45 +0200` before the first successful smoke to
`2026-08-13 09:21:17 +0200` and `2026-08-13 09:21:34 +0200` after the
confirming smoke. These are expected environment-cache metadata changes from
lock creation and sandbox regeneration. No project package or package version
changed.

## Preservation evidence

The following sealed identities remained unchanged:

- `.Rprofile`: `3f9d62fc3f1bf5888a09816101b705f9844ef4cd44ee5ad157f4168dac4af4d4`;
- `renv/activate.R`: `51798a35c2772b94b4a73ae7a7cc928975ff6e628a17bad1bc73d30defca82e6`;
- `renv.lock`: `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`;
- `notebooks/descriptives.qmd`: `b631936d9e47c4988dd453ea22184090b076705e3716e8f037e1953e3309cd4c`;
- `_quarto-nathealth.yml`: `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`;
- existing Descriptives HTML: `2d88888c888bc6f89374bd43753c239329bb1b9dd33f0f6e466d5cece5556ce0`.

Immediately before and after the confirming smoke, the current 125-file
protected inventory contained 105,158,405 bytes and was byte-identical at
SHA-256 `d38c0000f21aea62cf91006ee413c27aa768c37af86a32747ca35eef3d39950d`.
The 827-file Nature Health build inventory contained 294,689,985 bytes and was
byte-identical at SHA-256
`8f4cf016a7ce3ddf67974e245c08ed0057a3e861eaf62f26d37749a7991e9b87`.
The protected total already included the separately authorized Descriptives
reader-wording edit before this pre-smoke inventory was captured. There was no
protected or build change during the startup repair smoke.

## Release condition

The environment smoke gate is passed. After the Descriptives owner seals the
separate reader-only footnote correction and rechecks the accepted source and
profile hashes, exactly one command may run next:

```text
quarto render notebooks/descriptives.qmd --profile nathealth
```

That command must use the same narrow elevated access to the user-owned renv
cache, must retain the normal project profile, and remains subject to the
existing stored-input, HTML, and final-size visual acceptance contracts. No
later serial render is released until Descriptives is accepted.

