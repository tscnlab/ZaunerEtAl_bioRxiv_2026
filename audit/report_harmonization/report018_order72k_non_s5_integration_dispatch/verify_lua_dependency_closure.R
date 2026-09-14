options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
prefix <- "_extensions/kapsner/authors-block/"
pins <- data.frame(
  path = paste0(prefix, c("utils.lua", "from_author_info_blocks.lua", "from_scholarly_metadata.lua")),
  sha256 = c("75d6b7897e3c6aac79f2f6e04433084758340dac4701b2031fabed665262628f",
    "0bb5577a23b9109fe555313ac087096c37af7142e617adf747ba47f930aa5d30",
    "84a3066380783b6794e6312f653d896ae6547011463af291bbcc7638ab2ad834"),
  bytes = c(1888L, 7564L, 2246L))
paths <- file.path(root, pins$path)
stopifnot(all(normalizePath(paths, mustWork = TRUE) == paths),
  !any(file.info(paths)$isdir), all(Sys.readlink(paths) == ""),
  all(unname(vapply(paths, sha, character(1))) == pins$sha256),
  all(file.info(paths)$size == pins$bytes))
entry <- file.path(root, prefix, "authors-block.lua")
stopifnot(sha(entry) == "d0b0874a22eb4556690773ca04094bf467190d60a3f2267918dc8048aec329d6")
graph <- do.call(rbind, lapply(c(entry, paths), function(path) {
  lines <- readLines(path, warn = FALSE)
  matches <- regmatches(lines, regexec("^\\s*local\\s+[a-zA-Z_]+\\s*=\\s*require\\s+['\"]([^'\"]+)['\"]", lines, perl = TRUE))
  modules <- vapply(matches[lengths(matches) > 0L], function(x) x[2L], character(1))
  data.frame(source = substring(path, nchar(root) + 2L), required_module = modules)
}))
local_modules <- unique(graph$required_module[!startsWith(graph$required_module, "pandoc.")])
stopifnot(setequal(paste0(local_modules, ".lua"), basename(pins$path)),
  setequal(graph$required_module[startsWith(graph$required_module, "pandoc.")], c("pandoc.List", "pandoc.utils")))
write.csv(pins, file.path(out, "lua_dependency_closure_pins.csv"), row.names = FALSE)
write.csv(graph, file.path(out, "lua_dependency_require_graph.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/verify_lua_dependency_closure.R",
  capture.output(sessionInfo())), file.path(out, "lua_dependency_closure_session.txt"))
cat("LUA_DEPENDENCY_CLOSURE=PASS exact_modules=3; all non-Pandoc requires resolved\n")
cat("Pins CSV SHA-256:", sha(file.path(out, "lua_dependency_closure_pins.csv")), "\n")
