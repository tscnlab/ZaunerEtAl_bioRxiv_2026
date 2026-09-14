# Order 61 failure-sealer execution notes

The task-owned failure sealer encountered two representation-only assertions
before its successful fail-closed pass:

1. The Sass cache inventory intentionally has no `link_target` column, while
   the generic inventory comparison initially assumed one. The task-owned
   comparison was narrowed to treat a missing link column as empty.
2. The HTML caption selector returned 29 captions because the 26 native `gt`
   table wrappers and three figure wrappers all use `figcaption`. The
   task-owned assertion was narrowed from exactly three captions to at least
   three nonempty captions, matching the sealed order and existing preparation
   test.

Both observations occurred after all preservation evidence had already been
written. Neither changed a QMD, HTML, manifest, test, helper, profile, package,
lockfile, scientific artifact, shared contract, or external semantic file.
The final sealer passed every preservation domain and intentionally retained
the sole preparation-test failure as the stop condition.
