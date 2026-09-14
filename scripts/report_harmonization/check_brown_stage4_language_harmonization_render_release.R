options(stringsAsFactors = FALSE)

suppressPackageStartupMessages(library(digest))

central_root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown_root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"

fail <- function(label) {
  stop(sprintf("Brown Stage 4 render release failed: %s", label), call. = FALSE)
}

require_true <- function(value, label) {
  if (!isTRUE(value)) fail(label)
}

sha256 <- function(path) {
  digest(path, algo = "sha256", serialize = FALSE, file = TRUE)
}

verify_identity <- function(root, path, bytes, hash, label = path) {
  full <- file.path(root, path)
  require_true(file.exists(full), paste(label, "exists"))
  require_true(identical(as.numeric(file.info(full)$size), as.numeric(bytes)), paste(label, "bytes"))
  require_true(identical(sha256(full), hash), paste(label, "SHA-256"))
}

central_pins <- data.frame(
  path = c(
    "audit/decisions/brown_adherence_stage3_order50_independent_acceptance.md",
    "audit/decisions/brown_adherence_stage3_order50_independent_acceptance_verification.md",
    "audit/decisions/brown_adherence_stage3_order50_independent_acceptance_manifest.csv",
    "scripts/report_harmonization/check_brown_stage3_order50_independent_acceptance.R",
    "audit/decisions/brown_adherence_stage3_stage4_language_harmonization_source_independent_acceptance.md",
    "audit/report_harmonization/report018_brown_stage3_stage4_source_independent_acceptance.md",
    "scripts/report_harmonization/repair_gt_html_semantics.R"
  ),
  bytes = c(3779, 1083, 5153, 11770, 4908, 4334, 17747),
  sha256 = c(
    "cc5f751f7f86ce2ec1cd930f60bea19cca8e6bdfd2b33113c978694a6357a7be",
    "8df611632001716f0774f35d1e8f11b58c96cb41828c456adf0a83244e9d9962",
    "7305e781e788376c326ef7894648bb2d90ba702056d4a5443abb6c9bb07bcc8a",
    "1b8bbf185b243a21dcddfd36ff75db8d63e18967a3f92bbef9f41edc430ea672",
    "eb7da424f42cc7e2e953c45a4e559fcff8c1375ec6e64f000520c4753580d6ca",
    "1a41eff44049194072dfcdaa58fc67a9a91802b31adf14bc31a1d9ae2bc4185f",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1"
  )
)

for (i in seq_len(nrow(central_pins))) {
  verify_identity(
    central_root,
    central_pins$path[[i]],
    central_pins$bytes[[i]],
    central_pins$sha256[[i]],
    central_pins$path[[i]]
  )
}

brown_pins <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
    "audit/analyses/brown_adherence/language_harmonization/source_only/source_only_final_manifest.csv",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/order50_completion_record.md",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/order50_final_manifest.csv",
    "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv",
    "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest_verification.csv",
    "renv.lock"
  ),
  bytes = c(55426, 4825090, 24416, 4340432, 3659, 3651, 16282, 54203, 29804, 603493),
  sha256 = c(
    "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
    "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
    "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
    "bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46",
    "f536124ca5554b0e6c03f894d8d6549c3287a8343c938ad811515a97dddae931",
    "37b728618d875a16939c382c243dea7ff29d8dc72fd945ac16a16082c755e8f4",
    "80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2",
    "60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  )
)

for (i in seq_len(nrow(brown_pins))) {
  verify_identity(
    brown_root,
    brown_pins$path[[i]],
    brown_pins$bytes[[i]],
    brown_pins$sha256[[i]],
    brown_pins$path[[i]]
  )
}

acceptance_manifest_path <- file.path(
  central_root,
  "audit/decisions/brown_adherence_stage3_order50_independent_acceptance_manifest.csv"
)
acceptance_manifest <- read.csv(acceptance_manifest_path, check.names = FALSE)
require_true(nrow(acceptance_manifest) == 26L, "Stage 3 acceptance manifest row count")
require_true(!anyDuplicated(paste(acceptance_manifest$path_class, acceptance_manifest$path)), "Stage 3 acceptance manifest uniqueness")
acceptance_roots <- ifelse(
  acceptance_manifest$path_class == "central",
  central_root,
  brown_root
)
acceptance_files <- file.path(acceptance_roots, acceptance_manifest$path)
require_true(all(file.exists(acceptance_files)), "Stage 3 acceptance manifest paths exist")
require_true(
  identical(as.numeric(file.info(acceptance_files)$size), as.numeric(acceptance_manifest$bytes)),
  "Stage 3 acceptance manifest bytes"
)
require_true(
  identical(
    unname(vapply(acceptance_files, sha256, character(1))),
    acceptance_manifest$sha256
  ),
  "Stage 3 acceptance manifest hashes"
)

source_manifest_path <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/language_harmonization/source_only/source_only_final_manifest.csv"
)
source_manifest <- read.csv(source_manifest_path, check.names = FALSE)
source_path_column <- intersect(c("project_relative_path", "path"), names(source_manifest))[[1L]]
source_files <- file.path(brown_root, source_manifest[[source_path_column]])
require_true(nrow(source_manifest) == 19L, "source manifest row count")
require_true(!anyDuplicated(source_manifest[[source_path_column]]), "source manifest unique paths")
require_true(all(file.exists(source_files)), "source manifest paths exist")
require_true(
  identical(as.numeric(file.info(source_files)$size), as.numeric(source_manifest$bytes)),
  "source manifest bytes"
)
require_true(
  identical(unname(vapply(source_files, sha256, character(1))), source_manifest$sha256),
  "source manifest hashes"
)

stage4_manifest_path <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv"
)
stage4_manifest <- read.csv(stage4_manifest_path, check.names = FALSE)
require_true(nrow(stage4_manifest) == 113L, "historical Stage 4 manifest row count")
require_true(!anyDuplicated(stage4_manifest$project_relative_path), "historical Stage 4 manifest uniqueness")
stage4_files <- file.path(brown_root, stage4_manifest$project_relative_path)
require_true(all(file.exists(stage4_files)), "historical Stage 4 manifest paths exist")
live_bytes <- as.numeric(file.info(stage4_files)$size)
live_hashes <- unname(vapply(stage4_files, sha256, character(1)))
matches <- live_bytes == as.numeric(stage4_manifest$bytes) & live_hashes == stage4_manifest$sha256
mismatch_paths <- stage4_manifest$project_relative_path[!matches]
require_true(
  identical(
    mismatch_paths,
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd"
  ),
  "historical Stage 4 manifest has only the authorized source transition"
)
transition_index <- which(!matches)
require_true(
  stage4_manifest$bytes[[transition_index]] == 24147 &&
    stage4_manifest$sha256[[transition_index]] ==
      "642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29" &&
    live_bytes[[transition_index]] == 24416 &&
    live_hashes[[transition_index]] ==
      "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
  "exact Stage 4 historical-to-harmonized source transition"
)
require_true(sum(matches) == 112L, "112 historical Stage 4 members remain live exact")

stage4_qmd_path <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd"
)
stage4_lines <- readLines(stage4_qmd_path, warn = FALSE, encoding = "UTF-8")
r_chunks <- grep("^```\\{r(?:[ ,}]|$)", stage4_lines, perl = TRUE, value = TRUE)
table_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-", stage4_lines, value = TRUE)
)
mermaid_chunks <- grep("^```\\{mermaid\\}$", stage4_lines, value = TRUE)
require_true(length(r_chunks) == 18L, "Stage 4 has 18 R chunks")
require_true(length(table_labels) == 17L && !anyDuplicated(table_labels), "Stage 4 has 17 unique table endpoints")
require_true(length(mermaid_chunks) == 1L, "Stage 4 has one Mermaid endpoint")
require_true(sum(grepl("13_cross_state_association_results_amendment.qmd#sec-brown-main-results", stage4_lines, fixed = TRUE)) == 3L, "Stage 4 reciprocal result links")
require_true(!any(grepl("—", stage4_lines, fixed = TRUE)), "Stage 4 source has no em dash")

listener <- suppressWarnings(
  system2("lsof", c("-nP", "-iTCP", "-sTCP:LISTEN"), stdout = TRUE, stderr = TRUE)
)
require_true(!any(grepl("brown", listener, ignore.case = TRUE)), "no Brown loopback listener")

cat(sprintf(
  paste0(
    "BROWN_STAGE4_RENDER_RELEASE=PASS central=7/7 stage3_acceptance=26/26 ",
    "source_manifest=19/19 historical_stage4=112_exact+1_authorized_qmd_transition ",
    "stage4=18_chunks/17_tables/1_mermaid/3_result_links lock=exact R=%s digest=%s\n"
  ),
  paste(R.version$major, R.version$minor, sep = "."),
  as.character(packageVersion("digest"))
))
