# Read-only checker correction. The first checker and all its outputs remain.
# The owner seal pins our five prior evidence files through a nested ledger,
# not as direct owner-tree members. Verify that exact nested ledger and files.
original_path <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/review_completion_seal_001.R"
original_con <- file(original_path, "rb")
original_hash <- unname(unclass(as.character(openssl::sha256(original_con))))
close(original_con)
stopifnot(original_hash == "e1c9539807d93b06146afc4253a1ce06bea4a903cef5a4b25eb9e9e74b1cbb74")
original_lines <- readLines(original_path, warn = FALSE)
first <- which(startsWith(original_lines, 'check("64 prior independent Harmonizer package checks unchanged"'))
stopifnot(length(first) == 1L, identical(original_lines[first + 1L],
  '  all(file.path(D, c("review_completed_svg_docx_001.R", "completed_svg_docx_independent_001/independent_package_checks.csv")) %in% current$resolved))'))
replacement <- c(
  'own_pins_path <- file.path(R, "harmonizer_independent_evidence_pins.csv")',
  'own_pins <- read.csv(own_pins_path)',
  'check("64 prior independent Harmonizer checks and five nested evidence pins unchanged",',
  '  nrow(own_checks) == 64L && all(own_checks$pass) && nrow(own_pins) == 5L &&',
  '  own_pins_path %in% current$resolved &&',
  '  all(vapply(own_pins$path, sha, character(1)) == own_pins$sha256) &&',
  '  all(file.info(own_pins$path)$size == own_pins$bytes) &&',
  '  file.path(D, "completed_svg_docx_independent_001/independent_package_checks.csv") %in% own_pins$path)',
  'write.csv(own_pins, file.path(out, "verified_nested_harmonizer_evidence_pins.csv"), row.names = FALSE)')
verified_lines <- c(original_lines[seq_len(first - 1L)], replacement,
  original_lines[seq.int(first + 2L, length(original_lines))])
verified_lines <- gsub("completed_svg_handoff_independent_001", "completed_svg_handoff_independent_verified_001", verified_lines, fixed = TRUE)
verified_lines <- gsub("review_completion_seal_001.R", "review_completion_seal_verified_001.R", verified_lines, fixed = TRUE)
eval(parse(text = verified_lines), envir = new.env(parent = globalenv()))
