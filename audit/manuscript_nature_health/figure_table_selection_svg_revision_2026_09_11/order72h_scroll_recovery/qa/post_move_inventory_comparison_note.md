# Post-move inventory comparison note

The first ad hoc post-move check used R `identical()` on an in-memory inventory
and the same inventory read back from CSV. That comparison returned false
because serialization and re-import did not retain identical data-frame
attributes. It did not identify a filesystem difference. The failed check is
preserved as `post_move_checks_attempt1.csv`.

The pre-render and post-move inventory CSV files are byte-identical at SHA-256
`3c90298c0971bf143b769ed0f215c9e1ad55b255c62e818206381500de555d80`,
4,675 bytes each. The corrected check therefore compares their file identities.
It passes together with the candidate hash, temporary-sibling absence, QMD
postimage, frozen canonical HTML, and frozen first candidate.
