# Local evidence-checker correction

The first read-only coordinator audit passed the 216, 186 and 21 authority
members, candidate scan and runtime hashes, then stopped because its string
matcher assumed the installed darwinUserCacheDir return occupied one line.
The installed function uses an eight-line layout. The corrected check compares
the complete eight-line function after whitespace normalization to the same
exact expression. This was a temporary audit-extractor defect, not an owner,
candidate, runtime, cache or scientific change. The original audit script is
retained as audit_cache_stop_attempt1.R. No render or cache write occurred.
