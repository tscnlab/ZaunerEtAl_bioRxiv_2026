suppressPackageStartupMessages({
  library(digest)
  library(gt)
  library(xml2)
})

assert_condition <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

assert_post_render_runtime <- function() {
  assert_condition(
    as.character(getRversion()) == "4.6.1",
    "The gt HTML semantic post-render wrapper requires R 4.6.1."
  )
  assert_condition(
    as.character(packageVersion("gt")) == "1.3.0",
    "The gt HTML semantic post-render wrapper requires gt 1.3.0."
  )
}

environment_value <- function(environment, name) {
  value <- environment[[name]]
  if (is.null(value) || length(value) == 0L || is.na(value[[1L]])) {
    return("")
  }
  as.character(value[[1L]])
}

is_absolute_path <- function(path) {
  grepl("^(?:/|[A-Za-z]:[/\\\\])", path, perl = TRUE)
}

resolve_path <- function(path, base_dir, must_work = TRUE) {
  candidate <- if (is_absolute_path(path)) path else file.path(base_dir, path)
  normalizePath(
    candidate,
    winslash = "/",
    mustWork = must_work
  )
}

path_is_within <- function(path, directory) {
  identical(path, directory) ||
    startsWith(path, paste0(directory, .Platform$file.sep))
}

read_declared_output_files <- function(environment, project_dir) {
  list_file <- environment_value(
    environment,
    "QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES"
  )

  if (nzchar(list_file)) {
    list_path <- resolve_path(list_file, project_dir, must_work = TRUE)
    assert_condition(
      file.exists(list_path) && !dir.exists(list_path),
      "The Quarto output-list indirection path must be an existing file."
    )
    outputs <- readLines(list_path, warn = FALSE, encoding = "UTF-8")
  } else {
    output_value <- environment_value(
      environment,
      "QUARTO_PROJECT_OUTPUT_FILES"
    )
    assert_condition(
      nzchar(output_value),
      paste0(
        "QUARTO_PROJECT_OUTPUT_FILES is missing and no output-list ",
        "indirection file was declared."
      )
    )
    outputs <- strsplit(output_value, "\n", fixed = TRUE)[[1L]]
  }

  outputs <- sub("\r$", "", outputs)
  assert_condition(
    length(outputs) > 0L && all(nzchar(outputs)),
    "The declared Quarto output list must contain only nonempty paths."
  )
  assert_condition(
    !anyDuplicated(outputs),
    "The declared Quarto output list contains duplicate paths."
  )
  outputs
}

validate_project_context <- function(environment, project_dir = getwd()) {
  assert_post_render_runtime()

  project_dir <- normalizePath(
    project_dir,
    winslash = "/",
    mustWork = TRUE
  )
  current_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  assert_condition(
    identical(current_dir, project_dir),
    "The post-render wrapper must run from the main Quarto project directory."
  )

  environment_project <- environment_value(
    environment,
    "QUARTO_PROJECT_DIR"
  )
  if (nzchar(environment_project)) {
    assert_condition(
      identical(
        resolve_path(environment_project, project_dir, must_work = TRUE),
        project_dir
      ),
      "QUARTO_PROJECT_DIR does not resolve to the current project directory."
    )
  }

  profile_path <- file.path(project_dir, "_quarto-nathealth.yml")
  assert_condition(
    file.exists(profile_path) && !dir.exists(profile_path),
    "The Nature Health profile is missing from the project directory."
  )

  output_value <- environment_value(
    environment,
    "QUARTO_PROJECT_OUTPUT_DIR"
  )
  assert_condition(
    nzchar(output_value),
    "QUARTO_PROJECT_OUTPUT_DIR is missing."
  )

  expected_output_dir <- normalizePath(
    file.path(project_dir, "_build", "nathealth"),
    winslash = "/",
    mustWork = TRUE
  )
  declared_output_dir <- resolve_path(
    output_value,
    project_dir,
    must_work = TRUE
  )
  assert_condition(
    identical(declared_output_dir, expected_output_dir),
    paste0(
      "QUARTO_PROJECT_OUTPUT_DIR must resolve exactly to ",
      "_build/nathealth for this profile."
    )
  )

  list(
    project_dir = project_dir,
    output_dir = expected_output_dir,
    profile_path = normalizePath(
      profile_path,
      winslash = "/",
      mustWork = TRUE
    )
  )
}

validate_audit_directory <- function(environment, project_dir) {
  audit_value <- environment_value(
    environment,
    "GT_HTML_SEMANTIC_AUDIT_DIR"
  )
  if (!nzchar(audit_value)) {
    return(NULL)
  }

  assert_condition(
    is_absolute_path(audit_value),
    "GT_HTML_SEMANTIC_AUDIT_DIR must be an absolute path."
  )
  audit_dir <- normalizePath(
    audit_value,
    winslash = "/",
    mustWork = TRUE
  )
  assert_condition(
    dir.exists(audit_dir),
    "GT_HTML_SEMANTIC_AUDIT_DIR must be an existing directory."
  )
  assert_condition(
    !path_is_within(audit_dir, project_dir),
    paste0(
      "GT_HTML_SEMANTIC_AUDIT_DIR must resolve outside the project and ",
      "output trees."
    )
  )
  audit_dir
}

normalize_declared_outputs <- function(outputs, context) {
  normalized <- vapply(
    outputs,
    function(path) {
      candidate <- if (is_absolute_path(path)) {
        path
      } else {
        file.path(context$project_dir, path)
      }
      assert_condition(
        file.exists(candidate) && !dir.exists(candidate),
        paste0("Declared Quarto output does not exist as a file: ", path)
      )
      resolved <- normalizePath(
        candidate,
        winslash = "/",
        mustWork = TRUE
      )
      assert_condition(
        path_is_within(resolved, context$output_dir) &&
          !identical(resolved, context$output_dir),
        paste0(
          "Declared Quarto output resolves outside _build/nathealth: ",
          path
        )
      )
      resolved
    },
    character(1)
  )

  assert_condition(
    !anyDuplicated(normalized),
    "Declared Quarto outputs resolve to duplicate files."
  )

  data.frame(
    declared_path = outputs,
    normalized_path = unname(normalized),
    project_relative_path = substring(
      unname(normalized),
      nchar(context$project_dir) + 2L
    ),
    is_html = tolower(tools::file_ext(unname(normalized))) %in%
      c("html", "htm"),
    stringsAsFactors = FALSE
  )
}

accepted_repair_engine_sha256 <-
  "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1"

load_repair_engine <- function(project_dir) {
  engine_path <- normalizePath(
    file.path(
      project_dir,
      "scripts",
      "report_harmonization",
      "repair_gt_html_semantics.R"
    ),
    winslash = "/",
    mustWork = TRUE
  )
  assert_condition(
    path_is_within(engine_path, project_dir),
    "The accepted repair engine must resolve inside the project directory."
  )
  assert_condition(
    identical(
      digest(
        engine_path,
        file = TRUE,
        algo = "sha256",
        serialize = FALSE
      ),
      accepted_repair_engine_sha256
    ),
    "The gt HTML semantic repair engine does not match its accepted identity."
  )

  engine <- new.env(parent = globalenv())
  sys.source(engine_path, envir = engine)
  required <- c(
    "apply_raw_replacements",
    "inventory_unsupported_id_references",
    "normalized_dom_without_mutable_values",
    "read_file_raw",
    "repair_gt_html_semantics",
    "sha256_raw"
  )
  assert_condition(
    all(vapply(required, exists, logical(1), envir = engine, inherits = FALSE)),
    "The accepted repair engine does not expose its required functions."
  )
  engine
}

gt_table_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)

inspect_gt_html_state <- function(path, engine) {
  input_raw <- engine$read_file_raw(path)
  input_sha256 <- engine$sha256_raw(input_raw)
  document <- read_html(rawToChar(input_raw))
  tables <- xml_find_all(document, gt_table_xpath)

  if (length(tables) == 0L) {
    return(list(
      disposition = "NO_GT",
      sha256 = input_sha256,
      bytes = length(input_raw),
      table_count = 0L,
      id_count = 0L,
      headers_count = 0L
    ))
  }

  endpoints <- vapply(
    tables,
    function(table) {
      endpoint <- xml_find_first(
        table,
        "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
      )
      assert_condition(
        !inherits(endpoint, "xml_missing"),
        "Every native gt table must have one Quarto tbl-* endpoint."
      )
      xml_attr(endpoint, "id")
    },
    character(1)
  )
  assert_condition(
    all(nzchar(endpoints)) && !anyDuplicated(endpoints),
    "Native gt table endpoints must be nonempty and document-unique."
  )

  complete <- logical(length(tables))
  namespace_marker <- logical(length(tables))
  id_count <- integer(length(tables))
  headers_count <- integer(length(tables))

  for (i in seq_along(tables)) {
    table <- tables[[i]]
    id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
    ids <- xml_attr(id_nodes, "id")
    header_nodes <- xml_find_all(
      table,
      "self::*[@headers] | .//*[@headers]"
    )
    header_values <- xml_attr(header_nodes, "headers")
    header_tokens <- unlist(
      strsplit(header_values, "[[:space:]]+"),
      use.names = FALSE
    )

    assert_condition(
      length(ids) > 0L && !anyNA(ids) && all(nzchar(ids)),
      "Every native gt table must have nonempty internal IDs."
    )
    assert_condition(
      !anyDuplicated(ids),
      "A native gt table contains duplicate internal IDs."
    )

    id_count[[i]] <- length(ids)
    headers_count[[i]] <- length(header_values)
    expected_ids <- sprintf(
      "%s--gt-%04d",
      endpoints[[i]],
      seq_along(ids)
    )
    marker_values <- c(ids, header_tokens)
    namespace_marker[[i]] <- any(grepl(
      "^tbl-.*--gt-[0-9]{4}$",
      marker_values,
      perl = TRUE
    ))

    headers_complete <- all(vapply(
      header_values,
      function(value) {
        tokens <- strsplit(value, "[[:space:]]+")[[1L]]
        positions <- match(tokens, ids)
        length(tokens) > 0L &&
          !anyNA(positions) &&
          all(vapply(
            tokens,
            function(token) sum(ids == token) == 1L,
            logical(1)
          )) &&
          all(xml_name(id_nodes[positions]) == "th") &&
          all(
            xml_attr(id_nodes[positions], "scope") %in%
              c("col", "row", "colgroup", "rowgroup")
          )
      },
      logical(1)
    ))

    complete[[i]] <- identical(unname(ids), unname(expected_ids)) &&
      headers_complete
  }

  if (all(complete)) {
    document_ids <- xml_attr(xml_find_all(document, ".//*[@id]"), "id")
    document_ids <- document_ids[
      !is.na(document_ids) & nzchar(document_ids)
    ]
    all_internal_ids <- unlist(lapply(
      tables,
      function(table) {
        xml_attr(xml_find_all(table, "self::*[@id] | .//*[@id]"), "id")
      }
    ))
    unsupported <- engine$inventory_unsupported_id_references(
      document,
      all_internal_ids
    )
    assert_condition(
      !anyDuplicated(document_ids) && nrow(unsupported) == 0L,
      paste0(
        "A namespaced gt document has duplicate IDs or unsupported ",
        "internal-ID references."
      )
    )
    return(list(
      disposition = "ALREADY_REPAIRED",
      sha256 = input_sha256,
      bytes = length(input_raw),
      table_count = length(tables),
      id_count = sum(id_count),
      headers_count = sum(headers_count)
    ))
  }

  assert_condition(
    !any(namespace_marker),
    paste0(
      "Native gt HTML is partially namespaced or otherwise ambiguous; ",
      "no repair was attempted."
    )
  )

  list(
    disposition = "UNREPAIRED",
    sha256 = input_sha256,
    bytes = length(input_raw),
    table_count = length(tables),
    id_count = sum(id_count),
    headers_count = sum(headers_count)
  )
}

write_raw_exact <- function(value, path) {
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(value, connection)
  invisible(path)
}

safe_audit_stem <- function(path) {
  stem <- gsub("[^A-Za-z0-9._-]+", "__", path)
  substr(stem, 1L, 180L)
}

build_summary_row <- function(
  target,
  disposition,
  pre_sha256 = NA_character_,
  post_sha256 = NA_character_,
  pre_bytes = NA_real_,
  post_bytes = NA_real_,
  table_count = 0L,
  id_count = 0L,
  headers_count = 0L,
  total_substitutions = 0L,
  ledger_file = ""
) {
  data.frame(
    target = target,
    disposition = disposition,
    pre_sha256 = pre_sha256,
    post_sha256 = post_sha256,
    pre_bytes = pre_bytes,
    post_bytes = post_bytes,
    table_count = as.integer(table_count),
    id_count = as.integer(id_count),
    headers_count = as.integer(headers_count),
    total_substitutions = as.integer(total_substitutions),
    ledger_file = ledger_file,
    stringsAsFactors = FALSE
  )
}

run_post_render_gt_html_semantics <- function(
  environment,
  project_dir = getwd(),
  .finalize_callback = NULL
) {
  context <- validate_project_context(environment, project_dir)
  audit_dir <- validate_audit_directory(environment, context$project_dir)
  declared <- read_declared_output_files(environment, context$project_dir)
  outputs <- normalize_declared_outputs(declared, context)
  engine <- load_repair_engine(context$project_dir)

  temporary_root <- normalizePath(
    tempdir(),
    winslash = "/",
    mustWork = TRUE
  )
  assert_condition(
    !path_is_within(temporary_root, context$project_dir),
    "The R temporary directory must resolve outside the project tree."
  )
  staging_dir <- tempfile("gt-html-post-render-stage-", temporary_root)
  dir.create(staging_dir)
  staging_dir <- normalizePath(
    staging_dir,
    winslash = "/",
    mustWork = TRUE
  )
  assert_condition(
    path_is_within(staging_dir, temporary_root),
    "The staging directory did not resolve inside the R temporary directory."
  )
  on.exit(
    {
      if (
        dir.exists(staging_dir) && path_is_within(staging_dir, temporary_root)
      ) {
        unlink(staging_dir, recursive = TRUE, force = TRUE)
      }
    },
    add = TRUE
  )

  plans <- list()
  rows <- list()
  for (i in seq_len(nrow(outputs))) {
    target <- outputs$project_relative_path[[i]]
    path <- outputs$normalized_path[[i]]

    if (!outputs$is_html[[i]]) {
      rows[[i]] <- build_summary_row(
        target = target,
        disposition = "IGNORED_NON_HTML"
      )
      next
    }

    state <- inspect_gt_html_state(path, engine)
    if (state$disposition == "NO_GT") {
      rows[[i]] <- build_summary_row(
        target = target,
        disposition = "NO_GT",
        pre_sha256 = state$sha256,
        post_sha256 = state$sha256,
        pre_bytes = state$bytes,
        post_bytes = state$bytes
      )
      next
    }
    if (state$disposition == "ALREADY_REPAIRED") {
      rows[[i]] <- build_summary_row(
        target = target,
        disposition = "ALREADY_REPAIRED",
        pre_sha256 = state$sha256,
        post_sha256 = state$sha256,
        pre_bytes = state$bytes,
        post_bytes = state$bytes,
        table_count = state$table_count,
        id_count = state$id_count,
        headers_count = state$headers_count
      )
      next
    }

    staged_output <- file.path(staging_dir, sprintf("%03d-output.html", i))
    staged_ledger <- file.path(staging_dir, sprintf("%03d-ledger.csv", i))
    repair <- engine$repair_gt_html_semantics(
      path,
      staged_output,
      staged_ledger
    )
    repaired_state <- inspect_gt_html_state(staged_output, engine)
    assert_condition(
      repaired_state$disposition == "ALREADY_REPAIRED",
      "A staged gt HTML repair did not satisfy the complete postcondition."
    )

    original_raw <- engine$read_file_raw(path)
    repaired_raw <- engine$read_file_raw(staged_output)
    mode <- file.info(path)$mode[[1L]]
    plans[[length(plans) + 1L]] <- list(
      output_index = i,
      target = target,
      path = path,
      original_raw = original_raw,
      repaired_raw = repaired_raw,
      mode = mode,
      staged_ledger = staged_ledger,
      repair = repair
    )

    rows[[i]] <- build_summary_row(
      target = target,
      disposition = "REPAIRED",
      pre_sha256 = repair$input_sha256,
      post_sha256 = repair$output_sha256,
      pre_bytes = repair$input_bytes,
      post_bytes = repair$output_bytes,
      table_count = repair$table_count,
      id_count = repair$id_substitutions,
      headers_count = repair$headers_substitutions,
      total_substitutions = repair$total_substitutions
    )
  }

  summary <- do.call(rbind, rows)
  rownames(summary) <- NULL

  staged_audit <- list()
  if (!is.null(audit_dir)) {
    summary_destination <- file.path(
      audit_dir,
      "gt_html_semantic_post_render_summary.csv"
    )
    assert_condition(
      !file.exists(summary_destination),
      "The external combined audit-summary destination already exists."
    )
    summary_stage <- file.path(staging_dir, "combined-summary.csv")
    write.csv(summary, summary_stage, row.names = FALSE, na = "")
    staged_audit[[length(staged_audit) + 1L]] <- list(
      staged = summary_stage,
      destination = summary_destination
    )

    for (plan_index in seq_along(plans)) {
      plan <- plans[[plan_index]]
      ledger_name <- sprintf(
        "%03d_%s_gt_semantic_ledger.csv",
        plan$output_index,
        safe_audit_stem(plan$target)
      )
      ledger_destination <- file.path(audit_dir, ledger_name)
      assert_condition(
        !file.exists(ledger_destination),
        paste0(
          "External audit-ledger destination already exists: ",
          ledger_name
        )
      )
      staged_audit[[length(staged_audit) + 1L]] <- list(
        staged = plan$staged_ledger,
        destination = ledger_destination
      )
      summary$ledger_file[[plan$output_index]] <- ledger_name
    }

    write.csv(summary, summary_stage, row.names = FALSE, na = "")
  }

  if (is.null(.finalize_callback)) {
    .finalize_callback <- function(path, index) invisible(NULL)
  }
  assert_condition(
    is.function(.finalize_callback),
    "The finalization callback must be a function."
  )

  touched <- list()
  created_audit <- character()
  finalization_error <- NULL
  tryCatch(
    {
      for (plan_index in seq_along(plans)) {
        plan <- plans[[plan_index]]
        touched[[length(touched) + 1L]] <- plan
        write_raw_exact(plan$repaired_raw, plan$path)
        Sys.chmod(plan$path, mode = plan$mode)
        .finalize_callback(plan$path, plan_index)
        assert_condition(
          identical(engine$read_file_raw(plan$path), plan$repaired_raw),
          paste0(
            "Finalized HTML does not match its staged repair: ",
            plan$target
          )
        )
      }

      for (audit_plan in staged_audit) {
        copied <- file.copy(
          audit_plan$staged,
          audit_plan$destination,
          overwrite = FALSE,
          copy.mode = TRUE
        )
        assert_condition(
          isTRUE(copied),
          paste0(
            "Could not finalize external audit file: ",
            basename(audit_plan$destination)
          )
        )
        created_audit <- c(created_audit, audit_plan$destination)
      }
    },
    error = function(error) {
      finalization_error <<- error
    }
  )

  if (!is.null(finalization_error)) {
    rollback_errors <- character()
    for (plan in rev(touched)) {
      rollback_result <- tryCatch(
        {
          write_raw_exact(plan$original_raw, plan$path)
          Sys.chmod(plan$path, mode = plan$mode)
          assert_condition(
            identical(engine$read_file_raw(plan$path), plan$original_raw),
            paste0("Rollback verification failed for ", plan$target)
          )
          NULL
        },
        error = conditionMessage
      )
      if (!is.null(rollback_result)) {
        rollback_errors <- c(rollback_errors, rollback_result)
      }
    }
    for (audit_path in created_audit) {
      if (file.exists(audit_path)) {
        unlink(audit_path)
      }
    }
    assert_condition(
      length(rollback_errors) == 0L,
      paste0(
        "Post-render finalization failed and rollback was incomplete: ",
        paste(rollback_errors, collapse = "; ")
      )
    )
    stop(
      paste0(
        "Post-render finalization failed; exact originals were restored: ",
        conditionMessage(finalization_error)
      ),
      call. = FALSE
    )
  }

  summary
}

emit_post_render_status <- function(summary) {
  for (i in seq_len(nrow(summary))) {
    if (summary$disposition[[i]] == "IGNORED_NON_HTML") {
      cat(sprintf(
        "gt-html-semantics target=%s disposition=IGNORED_NON_HTML\n",
        summary$target[[i]]
      ))
      next
    }
    cat(sprintf(
      paste0(
        "gt-html-semantics target=%s disposition=%s pre=%s post=%s ",
        "tables=%d ids=%d headers=%d\n"
      ),
      summary$target[[i]],
      summary$disposition[[i]],
      summary$pre_sha256[[i]],
      summary$post_sha256[[i]],
      summary$table_count[[i]],
      summary$id_count[[i]],
      summary$headers_count[[i]]
    ))
  }
  invisible(summary)
}

post_render_main <- function() {
  environment <- as.list(Sys.getenv())
  result <- tryCatch(
    run_post_render_gt_html_semantics(
      environment = environment,
      project_dir = getwd()
    ),
    error = function(error) {
      message(
        "gt HTML semantic post-render ERROR: ",
        conditionMessage(error)
      )
      quit(save = "no", status = 1L)
    }
  )
  emit_post_render_status(result)
}

if (sys.nframe() == 0L) {
  post_render_main()
}
