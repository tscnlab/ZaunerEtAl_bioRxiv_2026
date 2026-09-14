# Initial final-corpus acceptance-sealer stop

The first acceptance-sealer execution stopped before writing its checks or
non-circular manifest. The pre- and post-integration build inventories were
byte-identical and contained zero symlinks, but `readr` imported empty
`link_target` CSV cells as `NA`. Applying `nzchar()` directly therefore made
the assertion indeterminate rather than false.

The bounded correction treats both imported `NA` and an empty string as an
empty link target. No source, HTML, build member, scientific artifact, corpus
manifest, coordination record, or prior evidence changed because of this
checker-only stop.
