options(warn = 2)

registry <- utils::read.csv(
  "config/site_display_registry.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)

expected <- data.frame(
  site = c(
    "RISE", "THUAS", "BAUA", "MPI", "TUM", "FUSPCEU", "IZTECH", "UCR",
    "KNUST"
  ),
  display_order = seq_len(9L),
  display_name = c(
    "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
    "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
    "Kumasi (GH)"
  ),
  color_hex = c(
    "#88CCEE", "#117733", "#DDCC77", "#DDCC77", "#DDCC77", "#CC6677",
    "#332288", "#44AA99", "#AA4499"
  ),
  stringsAsFactors = FALSE
)

metadata <- utils::read.csv(
  "config/site_metadata.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)

stopifnot(
  identical(names(registry), names(expected)),
  identical(registry, expected),
  !anyDuplicated(registry$site),
  !anyDuplicated(registry$display_order),
  !anyDuplicated(registry$display_name),
  identical(registry$display_order, seq_len(nrow(registry))),
  all(grepl("^#[0-9A-F]{6}$", registry$color_hex)),
  setequal(registry$site, metadata$site)
)

message("Submitted-manuscript site display registry: PASS")
