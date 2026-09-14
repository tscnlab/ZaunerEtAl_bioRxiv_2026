# Retained stopped attempt

This build stopped while checking the cumulative passage-change record. The
record contains actual newline characters, not literal backslash-n strings.
The check incorrectly escaped the accepted preimage before comparison.
Direct inspection confirmed that the accepted record and the extracted Table 2
block were identical before that unnecessary transformation.

No scientific source or live document changed. The partial candidate is
retained. The next attempt compares the original strings directly and records
the same two intended source changes. It also widens Table 2's first column
after the coordinator identified a plausible header-fit risk.
