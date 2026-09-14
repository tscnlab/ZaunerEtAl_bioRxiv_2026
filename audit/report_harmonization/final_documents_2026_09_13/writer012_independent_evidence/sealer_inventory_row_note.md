# Independent sealer inventory row classification

The initial coordinator release-sealer execution stopped before creating durable review evidence or either new manifest. It correctly rehashed the writer318, promotion89 and live/candidate914, then attempted to hash all3869 postflight records as files. Exactly one record is the directory-level complete_live_inventory assertion for _build/nathealth, with intentionally blank expected and actual file hashes. The other3868 rows are regular files.

The unsealed coordinator script now requires exactly that one named directory assertion and rehashes all3868 file rows. The complete914-file path/hash/byte equality and zero-symlink directory check already precede this condition and remain required. No record is silently ignored and no owner file, candidate, live artifact, scientific output or sealed history changed. This is an independent-sealer type classification only, not a candidate defect or a new owner retry.
