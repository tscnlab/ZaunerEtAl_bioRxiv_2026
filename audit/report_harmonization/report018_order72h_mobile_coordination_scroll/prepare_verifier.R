source("/private/tmp/order72h-scroll-recovery.rNlIZD/preflight.R")
central <- "audit/report_harmonization/report018_order72h_mobile_coordination_scroll"
recovery <- file.path(owner,"order72h_scroll_recovery")
v <- checker
old_output <- r"---(contract_root <- file.path(owner_root, "contracts")
)---"
new_output <- r"---(contract_root <- file.path(owner_root, "contracts")
verification_output_root <- Sys.getenv(
  "ORDER72H_VERIFY_OUTPUT_ROOT",
  unset = file.path(owner_root, "order72h_scroll_recovery")
)
)---"
v <- replace_once(v,old_output,new_output)
anchor <- r"---(add_check(
  "source_exact_forward_and_reverse_contract",
)---"
amendment <- r"---(coordination_contract_root <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72h_mobile_coordination_scroll"
)
coordination_table <- readChar(
  file.path(coordination_contract_root, "coordination_table_preimage.txt"),
  file.info(file.path(coordination_contract_root, "coordination_table_preimage.txt"))$size,
  useBytes = TRUE
)
coordination_wrapped <- paste0(
  '<div class="local-table-scroll" role="region" aria-label="Coordination status" tabindex="0">',
  "\n\n", coordination_table, "\n\n</div>"
)
expected_text <- replace_once(
  expected_text, coordination_table, coordination_wrapped,
  "Order72h exact Coordination status wrapper"
)
source_reverse <- replace_once(
  candidate_text, coordination_wrapped, coordination_table,
  "Order72h source reversal"
)
add_check(
  "source_order72h_exact_postimage_and_reverse",
  c(sha256_file(qmd_path), file_bytes(qmd_path)),
  c("197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9", 49967),
  sha256_file(qmd_path) ==
    "197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9" &&
    file_bytes(qmd_path) == 49967 &&
    digest(charToRaw(paste0(source_reverse, "\n")), algo = "sha256", serialize = FALSE) ==
      "9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3"
)
add_check(
  "source_exact_forward_and_reverse_contract",
)---"
v <- replace_once(v,anchor,amendment)
v <- replace_once(v,'file.path(owner_root, "qa/table_endpoint_checks.csv")','file.path(verification_output_root, "qa/table_endpoint_checks.csv")')
v <- replace_once(v,'file.path(owner_root, "qa", paste0(phase, "_checks.csv"))','file.path(verification_output_root, "qa", paste0(phase, "_checks.csv"))')
html_anchor <- r"---(  rendered_text <- normalize_text(document)
)---"
html_new <- r"---(  prior_svg_candidate_path <- file.path(
    owner_root, "rendered/manuscript_figure_table_selection.html"
  )
  if (sha256_file(prior_svg_candidate_path) !=
      "7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4") {
    stop("The preserved first SVG candidate changed.")
  }
  prior_svg_candidate <- read_html(prior_svg_candidate_path)
  coordination_region <- xml_find_all(
    document,
    "//section[@id='coordination-status']/div[@class='local-table-scroll' and @role='region' and @aria-label='Coordination status' and @tabindex='0']"
  )
  current_coordination_tables <- xml_find_all(
    coordination_region,
    "./table"
  )
  prior_coordination_tables <- xml_find_all(
    prior_svg_candidate,
    "//section[@id='coordination-status']/table"
  )
  add_check(
    "html_coordination_single_accessible_scroller",
    c(length(coordination_region), length(current_coordination_tables)),
    c(1L, 1L),
    length(coordination_region) == 1L &&
      length(current_coordination_tables) == 1L &&
      length(prior_coordination_tables) == 1L
  )
  current_coordination_cells <- vapply(
    xml_find_all(current_coordination_tables, ".//th|.//td"),
    normalize_text, character(1)
  )
  prior_coordination_cells <- vapply(
    xml_find_all(prior_coordination_tables, ".//th|.//td"),
    normalize_text, character(1)
  )
  add_check(
    "html_coordination_cells_unchanged",
    length(current_coordination_cells), 45L,
    length(current_coordination_cells) == 45L &&
      identical(current_coordination_cells, prior_coordination_cells)
  )
  table_cell_signature <- function(doc) {
    lapply(xml_find_all(doc, "//table"), function(table) {
      vapply(xml_find_all(table, ".//th|.//td"), normalize_text, character(1))
    })
  }
  add_check(
    "html_all_table_cells_equal_first_svg_candidate",
    length(table_cell_signature(document)), 22L,
    identical(table_cell_signature(document), table_cell_signature(prior_svg_candidate))
  )
  visible_text_tokens <- function(doc) {
    nodes <- xml_find_all(
      doc,
      "//body//text()[not(ancestor::script) and not(ancestor::style) and normalize-space()]"
    )
    trimws(gsub("[[:space:]]+", " ", xml_text(nodes)))
  }
  add_check(
    "html_visible_text_equal_first_svg_candidate",
    length(visible_text_tokens(document)),
    length(visible_text_tokens(prior_svg_candidate)),
    identical(visible_text_tokens(document), visible_text_tokens(prior_svg_candidate))
  )
  rendered_text <- normalize_text(document)
)---"
v <- replace_once(v,html_anchor,html_new)
writeChar(v,file.path(scratch,"verify_selection_svg_scroll_recovery.R"),eos=NULL,useBytes=TRUE)
parse(file.path(scratch,"verify_selection_svg_scroll_recovery.R"))
old_html_text <- raw_text(candidate)
section_start <- regexpr('<section id="coordination-status"',old_html_text,fixed=TRUE)[[1]]
stopifnot(section_start>0L)
section_remainder <- substring(old_html_text,section_start)
section_end <- regexpr("</section>",section_remainder,fixed=TRUE)[[1]]
section_text <- substr(section_remainder,1L,section_end+nchar("</section>")-1L)
table_start <- regexpr("<table",section_text,fixed=TRUE)[[1]]
table_end <- regexpr("</table>",section_text,fixed=TRUE)[[1]]
table_html <- substr(section_text,table_start,table_end+nchar("</table>")-1L)
new_section <- replace_once(section_text,table_html,paste0(opening,"\n",table_html,"\n</div>"))
simulation <- replace_once(old_html_text,section_text,new_section)
stopifnot(identical(replace_once(simulation,new_section,section_text),old_html_text))
writeChar(simulation,file.path(scratch,"simulated_wrapped_candidate.html"),eos=NULL,useBytes=TRUE)
cat("ORDER72H_PROSPECTIVE_VERIFIER=",sha(file.path(scratch,"verify_selection_svg_scroll_recovery.R"))," bytes=",file.info(file.path(scratch,"verify_selection_svg_scroll_recovery.R"))$size,"\n",sep="")
