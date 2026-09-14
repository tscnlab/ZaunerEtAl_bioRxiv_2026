# REPORT-018 Order 62 empty link-target import recovery

Status: `AUTHORIZED_FINAL_VERIFIER_IMPORT_CLASSIFICATION`

The complete corrected post-render checker now passes every domain except its
zero-symlink assertion. The build capture recorded empty `link_target` cells,
which `readr` imports as missing values. The checker applied `nzchar()` without
excluding those missing cells, so it treated the zero-symlink inventory as
nonempty.

The underlying pre-render and post-render inventories each contain 1,180
members and zero symlinks. This recovery preserves every sealed checker and
authorizes one outer temporary wrapper to change only the generated
post-render checker expression from the missing-unsafe `nzchar()` form to the
same expression restricted to nonmissing cells. It then invokes the already
sealed complete no-rerender path for `postrender` and later for `postqa`.

No Quarto command, page replacement, source edit, build mutation, semantic
rerun, or scientific computation is authorized.
