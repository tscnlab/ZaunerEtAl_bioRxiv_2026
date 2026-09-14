#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
stopifnot(dir.exists(project_library))
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED", unset = "") == "FALSE"
)

owner_relative <-
  "audit/hypotheses/H07/report018_order72j_split_svg_export"
owner_root <- normalizePath(
  file.path(root, owner_relative),
  winslash = "/",
  mustWork = TRUE
)
qa_root <- file.path(owner_root, "qa")
serve_root <- file.path(qa_root, "serve")
asset_root <- file.path(serve_root, "assets")
stopifnot(
  dir.exists(qa_root),
  !dir.exists(serve_root),
  !dir.exists(file.path(qa_root, "evidence"))
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

assert_owner_target <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  stopifnot(startsWith(normalized, paste0(owner_root, "/")))
  normalized
}

write_csv_once <- function(object, path) {
  assert_owner_target(path)
  stopifnot(!file.exists(path))
  utils::write.csv(
    object,
    path,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

write_lines_once <- function(lines, path) {
  assert_owner_target(path)
  stopifnot(!file.exists(path))
  writeLines(lines, path, useBytes = TRUE)
}

rehash_manifest <- function(path, manifest_id, expected_rows) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(
    nrow(manifest) == expected_rows,
    identical(names(manifest), c("path", "sha256", "bytes")),
    !anyDuplicated(manifest$path)
  )
  resolved <- ifelse(
    startsWith(manifest$path, "/"),
    manifest$path,
    file.path(root, manifest$path)
  )
  exists <- file.exists(resolved)
  observed_sha256 <- rep(NA_character_, nrow(manifest))
  observed_bytes <- rep(NA_real_, nrow(manifest))
  observed_sha256[exists] <- vapply(
    resolved[exists],
    sha256_file,
    character(1)
  )
  observed_bytes[exists] <- as.numeric(file.info(resolved[exists])$size)
  result <- data.frame(
    manifest = manifest_id,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = manifest$bytes,
    observed_bytes = observed_bytes,
    exists = exists,
    status = ifelse(
      exists &
        observed_sha256 == manifest$sha256 &
        observed_bytes == manifest$bytes,
      "PASS",
      "FAIL"
    ),
    stringsAsFactors = FALSE
  )
  stopifnot(all(result$status == "PASS"))
  result
}

release_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_release"
)
preflight_rehash <- rbind(
  rehash_manifest(
    file.path(release_root, "release_manifest.csv"),
    "release_manifest",
    123L
  ),
  rehash_manifest(
    file.path(release_root, "H07_execution_input_pins.csv"),
    "H07_execution_inputs",
    39L
  ),
  rehash_manifest(
    file.path(release_root, "H07_preservation_inventory.csv"),
    "H07_preservation",
    1451L
  )
)
stopifnot(nrow(preflight_rehash) == 1613L)

candidate_path <- file.path(
  owner_root,
  "candidate/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
attempt_path <- file.path(
  owner_root,
  "attempts/attempt_01/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
png_path <- file.path(
  root,
  "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png"
)
static_manifest_path <- file.path(owner_root, "non_circular_manifest.csv")
static_handoff_path <- file.path(
  owner_root,
  "REPORT018-ORDER72J-COMPONENT-REVIEW.md"
)
lease_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/",
    "report018_order72j_component_exports_dispatch/visual_lease_003.csv"
  )
)
anchor_paths <- c(
  candidate_path,
  attempt_path,
  png_path,
  static_manifest_path,
  static_handoff_path,
  lease_path
)
anchor_expected <- c(
  "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57",
  "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57",
  "f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113",
  "b0952d912f00abb6be3c4ada6a54f86d25c87080bf933fa627a4f18351091b1f",
  "26c2ee98e535258db3c993f0d805aa0251d5404a60c8359f2cdda32ea1365e95",
  "cf72005894273b322f7374d5297f6a073b6bf578d1fc3475c769855f62ec96a9"
)
anchor_observed <- vapply(anchor_paths, sha256_file, character(1))
stopifnot(identical(unname(anchor_observed), anchor_expected))
anchor_rehash <- data.frame(
  role = c(
    "immutable SVG candidate",
    "retained SVG attempt",
    "pinned accepted PNG comparator",
    "accepted static non-circular seal",
    "accepted static owner handoff",
    "exclusive visual lease 003"
  ),
  path = substring(anchor_paths, nchar(root) + 2L),
  expected_sha256 = anchor_expected,
  observed_sha256 = unname(anchor_observed),
  bytes = as.numeric(file.info(anchor_paths)$size),
  status = "PASS",
  stringsAsFactors = FALSE
)

lease <- readr::read_csv(lease_path, show_col_types = FALSE)
stopifnot(
  nrow(lease) == 1L,
  lease$lease_id == "ORDER72J-VISUAL-LEASE-003",
  lease$owner == "H07",
  lease$state == "ACTIVE",
  grepl(
    "no other visual lease is active",
    lease$exclusivity_evidence,
    fixed = TRUE
  )
)

dir.create(asset_root, recursive = TRUE, showWarnings = FALSE)
stopifnot(dir.exists(asset_root))
svg_copy <- file.path(
  asset_root,
  "H07_revised_smooth_derivative_pairs_near_eye.svg"
)
png_copy <- file.path(
  asset_root,
  "H07_revised_smooth_derivative_pairs_near_eye.png"
)
stopifnot(
  file.copy(candidate_path, svg_copy, overwrite = FALSE),
  file.copy(png_path, png_copy, overwrite = FALSE),
  sha256_file(svg_copy) == anchor_expected[[1L]],
  sha256_file(png_copy) == anchor_expected[[3L]]
)

index_lines <- c(
  "<!doctype html>",
  "<html lang=\"en\">",
  "<head>",
  "  <meta charset=\"utf-8\">",
  "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
  "  <title>H07 Order72j visual QA routes</title>",
  "</head>",
  "<body>",
  "  <h1>H07 Order72j visual QA routes</h1>",
  "  <ul>",
  "    <li><a href=\"compare.html?width=intrinsic\">Intrinsic proportion comparison</a></li>",
  "    <li><a href=\"compare.html?width=642\">170 mm, 642 CSS px comparison</a></li>",
  "    <li><a href=\"compare.html?width=708\">708 CSS px comparison</a></li>",
  "  </ul>",
  "</body>",
  "</html>"
)
write_lines_once(index_lines, file.path(serve_root, "index.html"))

compare_lines <- c(
  "<!doctype html>",
  "<html lang=\"en\">",
  "<head>",
  "  <meta charset=\"utf-8\">",
  "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
  "  <title>H07 Order72j SVG and PNG comparison</title>",
  "  <style>",
  "    :root { color-scheme: light; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }",
  "    * { box-sizing: border-box; }",
  "    body { margin: 0; padding: 18px; color: #171717; background: #e9e9e6; }",
  "    header { margin-bottom: 14px; }",
  "    h1 { margin: 0 0 5px; font-size: 22px; }",
  "    p { margin: 3px 0; font-size: 14px; line-height: 1.4; }",
  "    #status { display: inline-block; margin-top: 7px; padding: 4px 8px; border-radius: 4px; background: #fff4c2; font-weight: 650; }",
  "    #status.pass { color: #0a5c2f; background: #dff4e7; }",
  "    #comparison { display: grid; grid-template-columns: repeat(2, max-content); align-items: start; gap: 14px; }",
  "    figure { margin: 0; padding: 8px; background: #fff; border: 1px solid #9a9a96; }",
  "    figcaption { margin-bottom: 7px; font-size: 14px; font-weight: 700; }",
  "    img { display: block; height: auto; background: #fff; }",
  "    .metadata { color: #444; }",
  "  </style>",
  "</head>",
  "<body>",
  "  <header>",
  "    <h1 id=\"heading\">H07 Order72j comparison</h1>",
  "    <p id=\"dimensions\" class=\"metadata\"></p>",
  "    <p><a href=\"index.html\">Route inventory</a></p>",
  "    <p id=\"status\" role=\"status\">Loading local assets</p>",
  "  </header>",
  "  <main id=\"comparison\" aria-label=\"Immutable SVG candidate and pinned PNG comparator\">",
  "    <figure>",
  "      <figcaption>Immutable native SVG candidate</figcaption>",
  "      <img id=\"candidate\" alt=\"H07 native SVG candidate for visual inspection\">",
  "    </figure>",
  "    <figure>",
  "      <figcaption>Pinned accepted PNG comparator</figcaption>",
  "      <img id=\"comparator\" alt=\"H07 accepted PNG comparator for visual inspection\">",
  "    </figure>",
  "  </main>",
  "  <script>",
  "    (() => {",
  "      'use strict';",
  "      const params = new URLSearchParams(window.location.search);",
  "      const widthMode = params.get('width');",
  "      const allowedWidths = new Set(['intrinsic', '642', '708']);",
  "      if (!allowedWidths.has(widthMode)) throw new Error('Unsupported comparison route');",
  "      const vectorWidthPt = 648;",
  "      const vectorHeightPt = 1296;",
  "      const intrinsicCssWidth = vectorWidthPt * 96 / 72;",
  "      const targetCssWidth = widthMode === 'intrinsic' ? intrinsicCssWidth : Number(widthMode);",
  "      const targetCssHeight = targetCssWidth * vectorHeightPt / vectorWidthPt;",
  "      const candidate = document.getElementById('candidate');",
  "      const comparator = document.getElementById('comparator');",
  "      for (const image of [candidate, comparator]) image.style.width = `${targetCssWidth}px`;",
  "      candidate.src = 'assets/H07_revised_smooth_derivative_pairs_near_eye.svg';",
  "      comparator.src = 'assets/H07_revised_smooth_derivative_pairs_near_eye.png';",
  "      document.getElementById('heading').textContent = widthMode === 'intrinsic' ? 'Intrinsic vector proportion comparison' : `${widthMode} CSS px comparison`;",
  "      document.getElementById('dimensions').textContent = `Target ${targetCssWidth.toFixed(0)} × ${targetCssHeight.toFixed(0)} CSS px; native SVG 648 × 1296 pt; accepted PNG 2430 × 4860 px.`;",
  "      const loaded = image => new Promise((resolve, reject) => {",
  "        if (image.complete && image.naturalWidth > 0) return resolve();",
  "        image.addEventListener('load', resolve, { once: true });",
  "        image.addEventListener('error', reject, { once: true });",
  "      });",
  "      Promise.all([loaded(candidate), loaded(comparator)]).then(() => {",
  "        const candidateRatio = candidate.naturalWidth / candidate.naturalHeight;",
  "        const comparatorRatio = comparator.naturalWidth / comparator.naturalHeight;",
  "        const aspectDifference = Math.abs(candidateRatio - comparatorRatio);",
  "        const resources = performance.getEntriesByType('resource').map(entry => entry.name);",
  "        const externalResources = resources.filter(url => new URL(url).origin !== window.location.origin);",
  "        const pass = aspectDifference < 0.000001 && externalResources.length === 0;",
  "        window.order72jQA = Object.freeze({",
  "          route: window.location.href, widthMode, targetCssWidth, targetCssHeight,",
  "          candidateNaturalWidth: candidate.naturalWidth, candidateNaturalHeight: candidate.naturalHeight,",
  "          comparatorNaturalWidth: comparator.naturalWidth, comparatorNaturalHeight: comparator.naturalHeight,",
  "          candidateRenderedWidth: candidate.getBoundingClientRect().width, candidateRenderedHeight: candidate.getBoundingClientRect().height,",
  "          comparatorRenderedWidth: comparator.getBoundingClientRect().width, comparatorRenderedHeight: comparator.getBoundingClientRect().height,",
  "          aspectDifference, externalResources, viewport: { width: window.innerWidth, height: window.innerHeight },",
  "          documentScrollWidth: document.documentElement.scrollWidth, documentScrollHeight: document.documentElement.scrollHeight,",
  "          status: pass ? 'PASS' : 'FAIL'",
  "        });",
  "        const status = document.getElementById('status');",
  "        status.textContent = `${window.order72jQA.status}: both local assets loaded; aspect-ratio difference ${aspectDifference.toExponential(2)}; external resources ${externalResources.length}.`;",
  "        status.classList.toggle('pass', pass);",
  "        document.documentElement.dataset.qaStatus = window.order72jQA.status;",
  "        console.info('ORDER72J_H07_VISUAL_ROUTE_READY', JSON.stringify(window.order72jQA));",
  "      }).catch(error => {",
  "        document.documentElement.dataset.qaStatus = 'FAIL';",
  "        document.getElementById('status').textContent = `FAIL: ${error.message}`;",
  "        console.error('ORDER72J_H07_VISUAL_ROUTE_FAILED', error);",
  "      });",
  "    })();",
  "  </script>",
  "</body>",
  "</html>"
)
write_lines_once(compare_lines, file.path(serve_root, "compare.html"))

serve_files <- sort(list.files(
  serve_root,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  include.dirs = FALSE
))
stopifnot(identical(
  serve_files,
  sort(c(
    "assets/H07_revised_smooth_derivative_pairs_near_eye.png",
    "assets/H07_revised_smooth_derivative_pairs_near_eye.svg",
    "compare.html",
    "index.html"
  ))
))
serve_paths <- file.path(serve_root, serve_files)
stopifnot(
  !anyDuplicated(serve_files),
  all(Sys.readlink(serve_paths) == "")
)
html_text <- paste(
  unlist(lapply(serve_paths[grepl("[.]html$", serve_paths)], readLines)),
  collapse = "\n"
)
stopifnot(
  !grepl("https?://", html_text, perl = TRUE),
  !grepl("<script[^>]+src=", html_text, perl = TRUE),
  !grepl("<link[^>]+href=", html_text, perl = TRUE)
)
serve_inventory <- data.frame(
  path = file.path("qa/serve", serve_files),
  sha256 = vapply(serve_paths, sha256_file, character(1)),
  bytes = as.numeric(file.info(serve_paths)$size),
  symlink = FALSE,
  stringsAsFactors = FALSE
)

dir.create(file.path(qa_root, "evidence"), showWarnings = FALSE)
write_csv_once(
  preflight_rehash,
  file.path(qa_root, "evidence/preflight_rehash.csv")
)
write_csv_once(
  anchor_rehash,
  file.path(qa_root, "evidence/preflight_anchor_rehash.csv")
)
write_csv_once(
  serve_inventory,
  file.path(qa_root, "evidence/serve_inventory.csv")
)
write_csv_once(
  data.frame(
    lease = lease$lease_id,
    owner = lease$owner,
    source_path = substring(lease_path, nchar(root) + 2L),
    source_sha256 = sha256_file(lease_path),
    source_bytes = as.numeric(file.info(lease_path)$size),
    status_at_preflight = lease$state,
    competing_active_lease = FALSE,
    result = "PASS",
    stringsAsFactors = FALSE
  ),
  file.path(qa_root, "evidence/visual_lease_receipt.csv")
)
write_lines_once(
  c(
    paste0("R version: ", as.character(getRversion())),
    paste0("RENV_CONFIG_AUTOLOADER_ENABLED: ", Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED")),
    paste0(".libPaths: ", paste(.libPaths(), collapse = " | ")),
    paste0("digest: ", as.character(utils::packageVersion("digest"))),
    paste0("readr: ", as.character(utils::packageVersion("readr")))
  ),
  file.path(qa_root, "evidence/session_info.txt")
)

cat(sprintf(
  paste0(
    "ORDER72J_H07_VISUAL_PREFLIGHT=PASS release=123/123 inputs=39/39 ",
    "preservation=1451/1451 anchors=6/6 serve_files=%d lease=%s\n"
  ),
  nrow(serve_inventory),
  lease$lease_id
))
