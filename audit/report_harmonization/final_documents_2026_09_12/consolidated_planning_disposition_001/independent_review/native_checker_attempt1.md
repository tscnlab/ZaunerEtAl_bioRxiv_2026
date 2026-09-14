# Read-only manifest resolver correction

The first coordinator checksum probe stopped because it rejected every member
whose basename was completion_manifest.csv or completion_seal.json. The native
review legitimately pins an earlier package's completion_manifest.csv. The
non-circular condition must exclude this package's exact own manifest/seal
paths, not historical files sharing a basename. No owner file was changed.
The next probe uses exact full-path exclusion and retains all historical rows.
