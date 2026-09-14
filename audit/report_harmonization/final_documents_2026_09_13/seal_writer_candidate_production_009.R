# Seal one bounded Writer dispatch without changing any production input.
stopifnot(as.character(getRversion()) == "4.6.1")
project_root <- normalizePath(getwd(), mustWork = TRUE)
coord <- "audit/report_harmonization/final_documents_2026_09_13"
owner_root <- "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14"
selected <- file.path(owner_root, "attempt_02")
archive <- "audit/report_harmonization/final_documents_2026_09_12/writer_layout_preflight_archival_001/package"
old_helpers <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/helpers"
out_path <- file.path(coord, "writer_candidate_production_order_009_dispatch_manifest.csv")
detached_path <- file.path(coord, "writer_candidate_production_order_009.sha256")
check_path <- file.path(coord, "writer_candidate_production_order_009_preflight.csv")
session_path <- file.path(coord, "writer_candidate_production_order_009_session.txt")
candidate_root <- "audit/manuscript_nature_health/final_review_production_2026_09_14"
stopifnot(!file.exists(candidate_root))
stopifnot(!any(file.exists(c(out_path, detached_path, check_path, session_path))))
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
audit_manifest <- function(path, base, expected_count) {
  x <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(all(c("path", "bytes", "sha256") %in% names(x)))
  stopifnot(nrow(x) == expected_count, !anyDuplicated(x$path))
  paths <- ifelse(startsWith(x$path, "/"), x$path, file.path(base, x$path))
  stopifnot(all(file.exists(paths)))
  resolved <- normalizePath(paths, mustWork = TRUE)
  stopifnot(!normalizePath(path) %in% resolved, !anyDuplicated(resolved))
  stopifnot(all(file.info(paths)$size == x$bytes))
  stopifnot(all(vapply(paths, sha, "") == x$sha256))
  expected_count
}
pins <- c(
  "bf98c2ac5ed302f2632134d0d3a5f6dacbafddf547fa924607a96779ac91575c",
  "381a466441be50a3f88afbe9b8ae875f913e6302d870b647eae009faa77373ab",
  "1b5deb90c0c11cd0e931e6b13c00fedf5551920b9be1e890f86ba878ccfceb3b",
  "d711b2950ea8f7f893c3c09b0e7a015f657d59d1d7f966fbf7f8f89c2ab88ab8",
  "f0fa949f1a10dc0dfef3fac9fa03be9225d45966c1c25c1331250dc176cef6bb",
  "07e6f1ff9fbd2d7746317159cfe96a41161326366698ebfb6c01aba1335406e5",
  "ca062248f9dffb69e04c9dc36d26ac36b74c59967c4d4da39faf3841a23a4e7a",
  "31d1620d2e917aac5d81a63f84c26a8654b3918d49aed5c27adf593c3c5651de",
  "fa2ea19bb71bb8df1d0c231ea90586cc82008dfe50c03eccc19804854b5ae264",
  "f98800e8d15e78f985e944f2af06dc149ddb67ac4c76e869b014f4f36e0b0598",
  "b76e2aa7a6801126387fc4d8eafaf56a0ee43723efcb7ac54f5dae1d911fc692",
  "e89329f60bb477bf726fb1ccc0f3acecd107bab81d4541a1fca2633cf54415aa",
  "75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b",
  "4bf3a4aa761b18a34626c476774682766940992ce8b23a0b9107ac7daab85e1b",
  "0876e8fe580c8b0ad6fea21d040f4c1ae8ba384a72fc9f626774d000147d5684",
  "b3b7945b1bf8e9ca456bbfdccbdd8611c8caabb293b5cd4c95cae2d72e7b4d8d",
  "c6beb79ca34128c0b69d882c1e3ea332cb88664ce9a3c0883b39d1569db0a0d0",
  "fbfdde52cd24a60a5ff19eefb7901d3b7dcb268d97c2c922e0e87e7c944c652e",
  "3ed50e7dc3339bd42fc19393f10480baf733f485a65f34c03980fe4d466c5cf0",
  "84b88515af524e78f66ba947017afa195a000fa57663aa715d113fe1dab91f3b",
  "fa7454dedb2f84e5bf49fb9c590d1eadbaef2756dae05aa4bc2c2beceecc00a0",
  "5974136901a8325e831e932a3999382532acfcf94508f428b23bc8f5de3ffc98",
  "8c0cf634a4958aa05412de3f5f15aa92c40cbb5331a2319f761530472697e15f",
  "15b1272a3c360168e0b51ab9257534b08ced67190ed57be7a1c32cea8fc87be8",
  "d0b0874a22eb4556690773ca04094bf467190d60a3f2267918dc8048aec329d6",
  "72632b5b855ffec9db28a098cf62b9b83a80c57174bfa733b2b399a7bdef037f",
  "876d5993324e2faaaa96a68a4f7504642e9a07e6df265b385b2baa03b231369e",
  "81c7db1c6dbcdd606d95abef337b4529aeda6a4fa1cf23a5a567f9c5655c8b66"
)
pin_paths <- c(
  file.path(coord, "table_visual_acceptance_008.md"),
  file.path(coord, "table_visual_acceptance_008_manifest.csv"),
  file.path(owner_root, "package_manifest.csv"),
  file.path(selected, "source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"),
  file.path(selected, "source/supplementary_information_outline.qmd"),
  file.path(selected, "maps/part_count_contract.json"),
  file.path(selected, "maps/complete_drawing_order.csv"),
  file.path(selected, "maps/complete_table_part_map.csv"),
  file.path(selected, "maps/native_table_dispositions.csv"),
  file.path(old_helpers, "run_stage.py"),
  file.path(old_helpers, "stage_candidates.py"),
  file.path(old_helpers, "prepare_word_manuscript.py"),
  file.path(old_helpers, "embed_accepted_svg_figures.py"),
  "scripts/manuscript_nature_health/export_editable_tables.py",
  file.path(archive, "diffs/prepare_word_manuscript.py.diff"),
  file.path(archive, "diffs/export_editable_tables.py.diff"),
  "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd",
  "manuscript/R0_NatHealth/supplementary_information_outline.qmd",
  "manuscript/R0_NatHealth/_quarto.yml",
  "manuscript/R0_NatHealth/supplementary_information_standalone.qmd",
  "manuscript/R0_NatHealth/references_merged.bib",
  "manuscript/R0_NatHealth/manuscript_displays.css",
  "assets/reference.docx", "nature.csl",
  "_extensions/kapsner/authors-block/authors-block.lua",
  "/Applications/quarto/bin/quarto",
  "/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py",
  "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override/soffice"
)
stopifnot(length(pins) == length(pin_paths), all(nchar(pins) == 64L))
stopifnot(all(file.exists(pin_paths)), !anyDuplicated(pin_paths))
observed <- vapply(pin_paths, sha, "")
if (!all(observed == pins)) {
  print(data.frame(path = pin_paths, expected = pins, observed)[observed != pins, ])
  stop("A stable production pin differs; no dispatch seal was written.")
}
n_acceptance <- audit_manifest(pin_paths[[2]], project_root, 55L)
n_owner <- audit_manifest(pin_paths[[3]], owner_root, 263L)
part_counts <- jsonlite::read_json(file.path(selected, "maps/part_count_contract.json"), simplifyVector = TRUE)
stopifnot(length(part_counts) == 19L, sum(unlist(part_counts)) == 30L)
drawings <- read.csv(file.path(selected, "maps/complete_drawing_order.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(drawings) == 54L)
order_path <- file.path(coord, "writer_candidate_production_order_009.md")
order_text <- paste(readLines(order_path, warn = FALSE), collapse = "\n")
stopifnot(grepl("S2s small secondary text size is good enough for me", order_text, fixed = TRUE))
stopifnot(!grepl("\u2014", order_text, fixed = TRUE))
checks <- data.frame(
  check = c("R_version", "stable_pins", "acceptance_manifest", "owner_package", "table_parts", "drawings", "candidate_root_absent", "S2_author_size_choice", "no_em_dash"),
  observed = c("4.6.1", paste0(length(pins), "/", length(pins)), paste0(n_acceptance, "/55"), paste0(n_owner, "/263"), "19 keys/30 parts", "54", "absent", "preserved", "none"),
  pass = TRUE
)
write.csv(checks, check_path, row.names = FALSE, na = "")
writeLines(c(capture.output(sessionInfo()), paste("openssl", packageVersion("openssl")), paste("jsonlite", packageVersion("jsonlite"))), session_path)
extra <- c(order_path, file.path(coord, "seal_writer_candidate_production_009.R"), check_path, session_path,
  file.path(coord, "writer_candidate_production_order_009_path_resolution.md"),
  "scripts/manuscript_nature_health/prepare_word_manuscript.py",
  "scripts/manuscript_nature_health/embed_accepted_svg_figures.py",
  file.path(selected, "maps/source_to_full_screenshot_map.csv"),
  file.path(selected, "source/table2_primary_adherence.html"),
  file.path(selected, "source/supp_table_s2_complete.html"),
  file.path(selected, "source/supp_table_s7_complete.html"),
  "_extensions/kapsner/authors-block/utils.lua",
  "_extensions/kapsner/authors-block/from_scholarly_metadata.lua",
  "_extensions/kapsner/authors-block/from_author_info_blocks.lua",
  "_extensions/kapsner/authors-block/_extension.yml",
  file.path(archive, "scope_and_commands.md"), file.path(archive, "serial_qa_plan_NOT_EXECUTED.md"))
paths <- sort(unique(c(pin_paths, extra)))
stopifnot(all(file.exists(paths)), !any(c(out_path, detached_path) %in% paths))
manifest <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, ""))
write.csv(manifest, out_path, row.names = FALSE, na = "")
n_dispatch <- audit_manifest(out_path, project_root, length(paths))
writeLines(paste(vapply(c(order_path, out_path), sha, ""), c(order_path, out_path), sep = "  "), detached_path)
cat(sprintf("WRITER_ORDER009_DISPATCH=PASS checks=%s pins=%s acceptance=55/55 owner=263/263 dispatch=%s/%s R=4.6.1\n", nrow(checks), length(pins), n_dispatch, length(paths)))
cat("order ", sha(order_path), "\nmanifest ", sha(out_path), "\n", sep = "")
