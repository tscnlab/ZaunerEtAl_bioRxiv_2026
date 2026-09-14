# REPORT-018 Navigation Order 67a read-only completion

Date: 2026-09-02

Disposition: `PASS_NO_RENDER_SHARED_SHELL_TRANSFORMATION`

The approved Nature Health navigation structure is integrated on branch `rewrite/NH`. The manuscript remains the landing page. Hierarchical menus and submenus expose all 37 registered reader routes, the desktop table of contents remains fixed on the right, and the collapsed mobile table of contents is usable at 708 and 390 pixels.

The production change was one sealed, no-render promotion of the shared mobile-TOC include and the same embedded 154-byte script substitution in all 37 HTML routes. No QMD, scientific result, manuscript content, stylesheet, semantic table, figure, link endpoint, or previous/next page navigation was changed by this repair.

The original postflight stopped because its protected allowlist omitted the H06 provenance companion. Central disposition classified that companion as one of the same 37 approved shell transitions. This read-only verifier found exactly four protected transitions: the shared include, corpus manifest, H06 result HTML, and H06 companion HTML. The remaining 50 protected paths are byte-exact, and no fifth transition exists.

The current build is byte-identical to the sealed candidate for 892 of 892 files and contains no symbolic links. The corpus manifest is live-exact for 37 of 37 HTML routes while retaining all historical source paths and source hashes. Candidate and production browser evidence passes 148 of 148 mobile route checks, 6 of 6 desktop checks, and all 4 extended H06 view modes. The accepted Descriptives table remains an internal horizontal scroller at 708 pixels and does not gain width when its mobile TOC opens.

The production server is stopped, port 57370 has no listener, the browser viewport was reset, and the QA tabs were closed.

Final production identities:

- mobile TOC include: `153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980` (1,542 bytes)
- corpus manifest: `5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b` (11,479 bytes)
- H06 result HTML: `4883b77a2e225c8bad8628f1a04274f5d19d81aeb7cc493949707cdc6cd98e2f` (4,898,816 bytes)
- H06 companion HTML: `aeac00b6806ae10368e133e904784e7c2fcc79747bb8c8e2dc95fe2d721a944e` (849,699 bytes)
