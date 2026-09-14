# Pre-seal path-spelling classification

The first new release-sealer invocation stopped before writing any release,
input, dispatch or owner output. It required canonical-path uniqueness of the
already immutable 353-row central stop manifest. That older manifest has 353
unique literal paths but 350 canonical files: the three retained width-repair
preimages each occur once with a doubled separator and once with a single
separator. Both spellings carry identical SHA-256 and byte values.

The exact three files, relative to the Writer root, are:

- `s2_width_repair_001/capture_word_tables.preimage.mjs`, 8dd21ba1..., 21,399 bytes.
- `s2_width_repair_001/main_layout.preimage.css`, 44b5a324..., 2,492 bytes.
- `s2_width_repair_001/selection_layout.preimage.css`, 44b5a324..., 2,492 bytes.

The new sealer now checks this exact three-pair set and requires identical
hashes and bytes within every pair. No historical manifest is edited. The
335-row Writer and seven-row Harmonizer manifests have zero canonical aliases.
The new release and input seals normalize and deduplicate their own paths, so
they contain only unique canonical files. This is no extra artifact/version
transition and grants no owner edit, capture, render or scientific permission.
