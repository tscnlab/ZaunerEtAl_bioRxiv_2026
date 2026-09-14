# Order72k author-filter dependency closure

The first main DOCX render stopped before output because the copied
`authors-block.lua` could not load its local companion modules. Independent
read-only inspection and R 4.6.1 identity checks confirm that the complete
local dependency graph contains exactly three unchanged source files:

- `_extensions/kapsner/authors-block/utils.lua`
- `_extensions/kapsner/authors-block/from_author_info_blocks.lua`
- `_extensions/kapsner/authors-block/from_scholarly_metadata.lua`

Their exact identities are recorded in `lua_dependency_closure_pins.csv`,
SHA-256 `62f27bb24c52d362cfd0b800c25208158bc92bc6772bae896d2f25e6179e3ef5`.
All three match the Writer's independently reported hashes and byte sizes.
The entry filter remains at its original pinned identity. The only other
requires are `pandoc.List` and `pandoc.utils`, supplied by Pandoc.

The Harmonizer confirms exact copying of these three dependencies into the
existing authorized candidate resource directory, adjacent to the copied
filter, preserving the original module filenames. This closes the existing
filter's resource paths under the original candidate-copy permission.
Record source-to-copy hashes and retain the failed command and log. Do not
change Lua code, the entry filter, author/affiliation metadata, manuscript
sources, reference documents or installed libraries.

Use these dependencies for the already authorized consolidated correction
pass. No extra DOCX render, new correction pass or immediate implicit retry
is added. All other Order72k and environment-recovery boundaries, including
tool permission requests, the exclusive Writer visual lease, frozen
scientific content and the separate Brown hold, remain unchanged.
