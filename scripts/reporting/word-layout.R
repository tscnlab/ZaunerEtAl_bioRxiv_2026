# Normalize the WordprocessingML properties that HTML/gt conversion emits.
# ECMA-376 defines a fixed child order, even when Word/LibreOffice tolerate
# some variations. Keep this independent of presentation and of model results.
normalize_word_xml <- function(document) {
  ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
  orders <- list(
    pPr = "pStyle keepNext keepLines pageBreakBefore framePr widowControl numPr suppressLineNumbers pBdr shd tabs suppressAutoHyphens kinsoku wordWrap overflowPunct topLinePunct autoSpaceDE autoSpaceDN bidi adjustRightInd snapToGrid spacing ind contextualSpacing mirrorIndents suppressOverlap jc textDirection textAlignment textboxTightWrap outlineLvl divId cnfStyle rPr sectPr pPrChange",
    rPr = "rStyle rFonts b bCs i iCs caps smallCaps strike dstrike outline shadow emboss imprint noProof snapToGrid vanish webHidden color spacing w kern position sz szCs highlight u effect bdr shd fitText vertAlign rtl cs em lang eastAsianLayout specVanish oMath rPrChange",
    sectPr = "headerReference footerReference footnotePr endnotePr type pgSz pgMar paperSrc pgBorders lnNumType pgNumType cols formProt vAlign noEndnote titlePg textDirection bidi rtlGutter docGrid printerSettings sectPrChange",
    tblPr = "tblStyle tblpPr tblOverlap bidiVisual tblStyleRowBandSize tblStyleColBandSize tblW jc tblCellSpacing tblInd tblBorders shd tblLayout tblCellMar tblLook tblCaption tblDescription tblPrChange",
    tcPr = "cnfStyle tcW gridSpan hMerge vMerge tcBorders shd noWrap tcMar textDirection tcFitText vAlign hideMark headers cellIns cellDel cellMerge tcPrChange",
    tblBorders = "top start left bottom end right insideH insideV",
    tcBorders = "top start left bottom end right insideH insideV tl2br tr2bl",
    tblCellMar = "top start left bottom end right",
    tcMar = "top start left bottom end right",
    style = "name aliases basedOn next link autoRedefine hidden uiPriority semiHidden unhideWhenUsed qFormat locked personal personalCompose personalReply rsid pPr rPr tblPr trPr tcPr tblStylePr"
  )
  # gt's inline count notation can leave RTF control groups outside Word runs.
  # Translate their formatting while retaining every existing text run.
  for (paragraph in xml2::xml_find_all(document, '//w:p[text()[normalize-space()]]', ns)) {
    format <- NULL
    for (child in xml2::xml_contents(paragraph)) {
      if (xml2::xml_type(child) == "text") {
        value <- xml2::xml_text(child)
        if (!nzchar(trimws(value))) next
        format <- switch(value, "{\\i " = "italic", "}{\\sub " = "subscript", "}" = "plain", NULL)
        if (is.null(format)) stop("Unexpected bare text in a Word paragraph: ", value)
        xml2::xml_remove(child)
      } else if (xml2::xml_name(child) == "r" && !is.null(format) && format != "plain") {
        rp <- xml2::xml_find_first(child, './w:rPr', ns)
        if (inherits(rp, 'xml_missing')) rp <- xml2::xml_add_child(child, 'w:rPr', .where = 0)
        if (format == "italic") xml2::xml_add_child(rp, 'w:i')
        if (format == "subscript") xml2::xml_add_child(rp, 'w:vertAlign', 'w:val' = 'subscript')
      }
    }
  }
  # gt uses missing/zero border widths to mean no visible border.
  # Encode that intent explicitly instead of leaving an ambiguous single border.
  for (border in xml2::xml_find_all(document, '//w:tcBorders/* | //w:tblBorders/*', ns)) {
    width <- suppressWarnings(as.numeric(xml2::xml_attr(border, 'sz')))
    value <- xml2::xml_attr(border, 'val')
    if (!is.na(value) && value == 'single' && (is.na(width) || width <= 0)) {
      xml2::xml_set_attr(border, 'w:val', 'nil')
      xml2::xml_set_attr(border, 'w:sz', NULL, ns = ns)
    }
  }
  for (border in xml2::xml_find_all(document,
      '//w:tcBorders/*[@w:val="nil" or @w:val="none"] | //w:tblBorders/*[@w:val="nil" or @w:val="none"]', ns)) {
    for (attribute in c('sz', 'space', 'color')) xml2::xml_set_attr(border, paste0('w:', attribute), NULL, ns = ns)
  }
  # Give empty table cells an explicit paragraph for Word compatibility.
  # gt can omit this otherwise conventional cell content.
  for (cell in xml2::xml_find_all(document, '//w:tc[not(w:p) and not(w:tbl)]', ns)) {
    xml2::xml_add_child(cell, 'w:p')
  }
  # Imported table styles in the reference template need distinct display names.
  for (style in xml2::xml_find_all(document, '//w:style[not(w:name)]', ns)) {
    xml2::xml_add_child(style, 'w:name',
      'w:val' = paste('Table', xml2::xml_attr(style, 'styleId')), .where = 0)
  }
  for (tag in names(orders)) {
    ordering <- strsplit(orders[[tag]], ' ', fixed = TRUE)[[1L]]
    for (parent in xml2::xml_find_all(document, paste0('//w:', tag), ns)) {
      children <- xml2::xml_children(parent)
      repeated <- if (tag == "sectPr") c("headerReference", "footerReference") else if (tag == "style") "tblStylePr" else character()
      duplicate <- duplicated(xml2::xml_name(children), fromLast = TRUE) & !xml2::xml_name(children) %in% repeated
      xml2::xml_remove(children[duplicate])
      children <- xml2::xml_children(parent)
      index <- order(match(xml2::xml_name(children), ordering), na.last = TRUE)
      for (child in children[index]) xml2::xml_add_child(parent, child, .copy = FALSE)
    }
  }
  invisible(document)
}

# Quarto post-render formatting for the manuscript Word file.
# Input/output: a freshly rendered DOCX. Text, numbers and embedded media are
# preserved; only table layout and section/paragraph properties are changed.
format_manuscript_word <- function(path) {
  if (!file.exists(path)) return(invisible(FALSE))
  manuscript <- basename(path) == "index.docx"
  work <- tempfile("manuscript-word-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = work)
  document_path <- file.path(work, "word/document.xml")
  document <- xml2::read_xml(document_path)
  ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    r = "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
  if (length(xml2::xml_find_all(document, '//comment()[.="Quarto publication Word layout v2"]'))) {
    return(invisible(FALSE))
  }
  find <- function(x, xpath) xml2::xml_find_all(x, xpath, ns)
  first <- function(x, xpath) xml2::xml_find_first(x, xpath, ns)
  missing <- function(x) inherits(x, "xml_missing")
  node <- function(name, attributes = "") xml2::xml_root(xml2::read_xml(paste0(
    '<w:', name, ' xmlns:w="', ns[["w"]], '" ', attributes, '/>')))
  ensure <- function(parent, name) {
    result <- first(parent, paste0('./w:', name))
    if (missing(result)) result <- xml2::xml_add_child(parent, node(name), .where = 0)
    result
  }
  property <- function(parent, name, attributes = "") {
    xml2::xml_remove(find(parent, paste0('./w:', name)))
    xml2::xml_add_child(parent, node(name, attributes))
  }
  # Convert the occasional escaped gt superscript run to actual Word runs.
  # For example, the Site footnote must display as Site¹, not literal XML.
  for (text_node in find(document, '//w:t')) {
    value <- xml2::xml_text(text_node)
    if (!grepl('<w:r>', value, fixed = TRUE)) next
    pieces <- regmatches(value, regexec('^([^<]*)(<w:r>.*</w:r>)$', value))[[1L]]
    if (length(pieces) != 3L) stop('Unsupported escaped Word markup.')
    fragment <- xml2::read_xml(paste0('<fragment xmlns:w="', ns[['w']], '">', pieces[[3L]], '</fragment>'))
    xml2::xml_set_text(text_node, pieces[[2L]])
    previous_run <- xml2::xml_parent(text_node)
    for (run in xml2::xml_children(fragment)) {
      previous_run <- xml2::xml_add_sibling(previous_run, run, .where = 'after')
    }
  }
  # DOCX requires six-digit RGB fills. Flatten HTML alpha over white paper.
  for (shade in find(document, '//w:shd')) {
    value <- xml2::xml_attr(shade, 'fill')
    if (is.na(value) || !grepl('^RGBA\\(', value, ignore.case = TRUE)) next
    rgba <- as.numeric(strsplit(sub('\\)$', '', sub('^RGBA\\(', '', toupper(value))), ',', fixed = TRUE)[[1L]])
    stopifnot(length(rgba) == 4L, all(is.finite(rgba)), rgba[[4L]] >= 0, rgba[[4L]] <= 1)
    rgb <- as.integer(round(rgba[1:3] * rgba[[4L]] + 255 * (1 - rgba[[4L]])))
    xml2::xml_set_attr(shade, 'w:fill', paste(sprintf('%02X', rgb), collapse = ''))
  }
  before_text <- sort(xml2::xml_text(find(document, '//w:t[normalize-space()]')))
  before_pictures <- length(find(document, '//w:drawing'))
  body <- first(document, '//w:body')
  section <- first(body, './w:sectPr')
  stopifnot(!missing(section))
  section_xml <- sub("<w:sectPr", paste0('<w:sectPr xmlns:w="', ns[["w"]],
    '" xmlns:r="', ns[["r"]], '"'), as.character(section), fixed = TRUE)
  # Quarto places main tables in single-cell float wrappers. Unwrap those
  # containers so Word can paginate the actual editable rows and repeat headers.
  for (table in find(body, './w:tbl[w:tr/w:tc/w:tbl]')) {
    cells <- find(table, './w:tr/w:tc')
    if (length(cells) != 1L) next
    for (child in xml2::xml_children(cells[[1L]])) {
      if (xml2::xml_name(child) != 'tcPr') xml2::xml_add_sibling(table, child, .where = 'before')
    }
    xml2::xml_remove(table)
  }
  xml2::xml_remove(find(body, './w:tbl[not(w:tr)]'))
  # Normalize duplicate properties introduced by HTML-to-Word conversion.
  for (paragraph in find(document, '//w:p')) {
    properties <- find(paragraph, './w:pPr')
    if (length(properties) > 1L) {
      for (extra in properties[-1L]) {
        for (child in xml2::xml_children(extra)) xml2::xml_add_child(properties[[1L]], child)
        xml2::xml_remove(extra)
      }
    }
    if (length(properties)) {
      children <- xml2::xml_children(properties[[1L]])
      xml2::xml_remove(children[duplicated(xml2::xml_name(children), fromLast = TRUE)])
    }
  }
  make_section_end <- function(landscape) {
    p <- node('p'); pp <- ensure(p, 'pPr')
    property(pp, 'spacing', 'w:before="0" w:after="0" w:line="20" w:lineRule="exact"')
    property(pp, 'suppressLineNumbers')
    sp <- xml2::xml_add_child(pp, xml2::xml_root(xml2::read_xml(section_xml)))
    property(sp, 'type', 'w:val="nextPage"')
    # Page numbers continue across orientation changes.
    xml2::xml_remove(find(sp, './w:pgNumType'))
    if (landscape) {
      property(sp, 'pgSz', 'w:w="16840" w:h="11901" w:orient="landscape"')
      property(sp, 'pgMar', 'w:top="1000" w:right="1000" w:bottom="1000" w:left="1000" w:header="500" w:footer="500" w:gutter="0"')
      xml2::xml_remove(find(sp, './w:lnNumType'))
    }
    p
  }
  span <- function(cell) {
    value <- suppressWarnings(as.integer(xml2::xml_attr(first(cell, './w:tcPr/w:gridSpan'), 'val')))
    if (is.na(value)) 1L else value
  }
  # Explicit page starts and heading spacing are part of the rendered document.
  major_sections <- c("Abstract", "Introduction", "Results", "Discussion", "Methods",
    "Supplementary Information", "Acknowledgements", "References")
  for (p in find(body, './w:p')) {
    label <- trimws(xml2::xml_text(p))
    style <- xml2::xml_attr(first(p, './w:pPr/w:pStyle'), 'val')
    heading <- !is.na(style) && grepl('^(Heading|berschrift)', style)
    if (!heading) next
    pp <- ensure(p, 'pPr')
    property(pp, 'keepNext')
    property(pp, 'spacing', 'w:before="240" w:after="160" w:line="240" w:lineRule="auto"')
    if (manuscript && (label %in% major_sections ||
        grepl('^Supplementary (Figure|Table) S[0-9]+', label) ||
        label %in% c('Supplementary figures', 'Supplementary tables'))) {
      property(pp, 'pageBreakBefore')
    }
    preceding <- xml2::xml_find_first(p, 'preceding-sibling::w:p[1]', ns)
    if (!inherits(preceding, 'xml_missing') &&
        trimws(xml2::xml_text(preceding)) %in% c('Supplementary figures', 'Supplementary tables')) {
      xml2::xml_remove(find(pp, './w:pageBreakBefore'))
    }
    if (label == 'Competing interests') {
      property(pp, 'spacing', 'w:before="480" w:after="180" w:line="240" w:lineRule="auto"')
    }
  }
  if (manuscript) {
    # Use 1.25 line spacing on the title page; authors and affiliations remain 12 pt.
    for (p in find(body, './w:p')) {
      if (trimws(xml2::xml_text(p)) == 'Abstract') break
      pp <- ensure(p, 'pPr')
      property(pp, 'spacing', 'w:before="0" w:after="80" w:line="300" w:lineRule="auto"')
      property(pp, 'suppressLineNumbers')
      style <- xml2::xml_attr(first(p, './w:pPr/w:pStyle'), 'val')
      size <- if (!is.na(style) && style %in% c('Title', 'Titel')) {
        36L
      } else if (!is.na(style) && style %in% c('Author', 'FirstParagraph')) {
        24L
      } else {
        22L
      }
      for (run in find(p, './/w:r')) property(ensure(run, 'rPr'), 'sz', paste0('w:val="', size, '"'))
    }
    # The tall activity figure needs a portrait-page height bound as well.
    for (drawing in find(body, './w:tbl[.//w:bookmarkStart[@w:name="fig-activity-context"]]//w:drawing')) {
      extents <- xml2::xml_find_all(drawing, ".//*[local-name()='extent' or local-name()='ext'][@cx and @cy]")
      width <- as.numeric(xml2::xml_attr(extents[[1L]], 'cx'))
      height <- as.numeric(xml2::xml_attr(extents[[1L]], 'cy'))
      scale <- min(1, 8.8 * 914400 / height)
      xml2::xml_set_attr(extents, 'cx', as.character(round(width * scale)))
      xml2::xml_set_attr(extents, 'cy', as.character(round(height * scale)))
    }
    # Bound figure heights in portrait pages, preserving their aspect ratios.
    # Captions use single spacing so that all rows of tall figures remain visible.
    current_figure <- NA_integer_
    for (block in xml2::xml_children(body)) {
      label <- trimws(xml2::xml_text(block))
      if (grepl('^Supplementary Figure S[0-9]+[.]', label) &&
          length(find(block, './w:pPr/w:pStyle'))) {
        current_figure <- as.integer(sub('^Supplementary Figure S([0-9]+).*', '\\1', label))
      }
      if (label == 'Supplementary tables') current_figure <- NA_integer_
      if (is.na(current_figure)) next
      for (drawing in find(block, './/w:drawing')) {
        extents <- xml2::xml_find_all(drawing, ".//*[local-name()='extent' or local-name()='ext'][@cx and @cy]")
        if (!length(extents)) next
        width <- as.numeric(xml2::xml_attr(extents[[1L]], 'cx'))
        height <- as.numeric(xml2::xml_attr(extents[[1L]], 'cy'))
        max_height <- if (current_figure == 8L) 7.6 else if (current_figure == 5L) 7.15 else 6.8
        scale <- min(1, max_height * 914400 / height)
        if (current_figure == 3L) scale <- min(scale, .75)
        xml2::xml_set_attr(extents, 'cx', as.character(round(width * scale)))
        xml2::xml_set_attr(extents, 'cy', as.character(round(height * scale)))
      }
      for (p in c(if (xml2::xml_name(block) == 'p') list(block) else list(), as.list(find(block, './/w:p')))) {
        pp <- ensure(p, 'pPr')
        property(pp, 'spacing', 'w:before="0" w:after="120" w:line="240" w:lineRule="auto"')
        property(pp, 'suppressLineNumbers')
        if (!any(grepl('^(Heading|berschrift)', xml2::xml_attr(find(p, './w:pPr/w:pStyle'), 'val'))) && !length(find(p, './/w:drawing'))) {
          for (run in find(p, './/w:r')) property(ensure(run, 'rPr'), 'sz', 'w:val="20"')
        }
      }
    }
  }
  for (p in find(document, '//w:p[w:pPr/w:pStyle[@w:val="ImageCaption"]]')) {
    pp <- ensure(p, 'pPr')
    property(pp, 'keepLines')
    property(pp, 'spacing', 'w:before="80" w:after="120" w:line="240" w:lineRule="auto"')
    for (run in find(p, './/w:r')) property(ensure(run, 'rPr'), 'sz', 'w:val="20"')
  }
  table_count <- 0L; landscape_count <- 0L
  for (table in find(body, './w:tbl')) {
    rows <- find(table, './w:tr')
    if (!length(rows)) next
    row_columns <- vapply(rows, function(row) sum(vapply(find(row, './w:tc'), span, integer(1))), integer(1))
    columns <- max(row_columns)
    if (missing(first(table, './w:tblGrid'))) {
      # Quarto can omit the required grid on a single-cell figure container.
      properties <- ensure(table, 'tblPr')
      grid <- xml2::xml_add_sibling(properties, node('tblGrid'), .where = 'after')
      for (column in seq_len(columns)) xml2::xml_add_child(grid, node('gridCol',
        paste0('w:w="', round(9021 / columns), '"')))
    }
    if (columns < 3L) {
      # Give callout/figure containers explicit table and cell widths so Word
      # does not have to infer the intended width from their content.
      widths <- as.numeric(xml2::xml_attr(find(table, './w:tblGrid/w:gridCol'), 'w'))
      if (length(widths) != columns || any(!is.finite(widths)) || sum(widths) <= 0) {
        widths <- rep(round(9021 / columns), columns)
      }
      properties <- ensure(table, 'tblPr')
      if (missing(first(properties, './w:tblW'))) {
        property(properties, 'tblW', paste0('w:type="dxa" w:w="', sum(widths), '"'))
      }
      for (row in rows) {
        pos <- 1L
        for (cell in find(row, './w:tc')) {
          extent <- span(cell)
          cp <- ensure(cell, 'tcPr')
          if (missing(first(cp, './w:tcW'))) {
            property(cp, 'tcW', paste0('w:type="dxa" w:w="', sum(widths[pos:(pos + extent - 1L)]), '"'))
          }
          pos <- pos + extent
        }
      }
      next
    }
    table_count <- table_count + 1L
    text <- paste(xml2::xml_text(find(table, './/w:t')), collapse = ' ')
    # gt's Word exporter ignores column-label weight, so set the two header
    # rows of the adherence table explicitly in the final document.
    if (grepl("Valid minutes meeting recommendation", text, fixed = TRUE)) {
      for (row in rows[seq_len(2L)]) {
        for (run in find(row, './/w:r[w:t]')) property(ensure(run, 'rPr'), 'b')
      }
    }
    landscape <- columns >= 6L || grepl("Qualifying transition", text, fixed = TRUE)
    # Move a supplementary caption in front of its table; main captions are
    # already before their table after removing the float wrapper.
    after <- first(table, 'following-sibling::w:p[1]')
    if (!missing(after) && grepl('^Supplementary Table S[0-9]+[.]', trimws(xml2::xml_text(after))) &&
        !any(grepl('^(caption|Beschriftung|Heading|berschrift)', xml2::xml_attr(find(after, './w:pPr/w:pStyle'), 'val')))) {
      caption_target <- table
      if (grepl('^Supplementary Table S2[.]', trimws(xml2::xml_text(after)))) {
        caption_target <- first(body, './w:tbl[.//w:t[contains(., "Near-eye metric summaries: overall distribution")]][1]')
        stopifnot(!missing(caption_target))
      }
      caption <- xml2::xml_add_sibling(caption_target, after, .where = 'before')
      caption_properties <- ensure(caption, 'pPr')
      property(caption_properties, 'keepNext')
      property(caption_properties, 'suppressLineNumbers')
      property(caption_properties, 'spacing', 'w:before="0" w:after="120" w:line="240" w:lineRule="auto"')
      xml2::xml_remove(after)
    }
    start <- table
    previous <- first(table, 'preceding-sibling::w:p[1]')
    if (!missing(previous) && (grepl('^(Supplementary )?Table[[:space:]\u00a0]+|^Overall distribution$|^Site summaries [0-9]+$', trimws(xml2::xml_text(previous))) ||
        any(grepl('^(Heading|berschrift)', xml2::xml_attr(find(previous, './w:pPr/w:pStyle'), 'val'))))) {
      start <- previous
      heading <- first(previous, 'preceding-sibling::w:p[1]')
      if (!missing(heading) && any(grepl('^(Heading|berschrift)',
          xml2::xml_attr(find(heading, './w:pPr/w:pStyle'), 'val')))) {
        start <- heading
        property(ensure(heading, 'pPr'), 'keepNext')
        property(ensure(heading, 'pPr'), 'suppressLineNumbers')
      }
      pp <- ensure(previous, 'pPr')
      property(pp, 'keepNext'); property(pp, 'suppressLineNumbers')
      property(pp, 'spacing', 'w:before="0" w:after="120" w:line="240" w:lineRule="auto"')
      property(pp, 'jc', 'w:val="left"')
    }
    if (landscape) {
      xml2::xml_remove(find(start, './w:pPr/w:pageBreakBefore'))
      landscape_count <- landscape_count + 1L
      xml2::xml_add_sibling(start, make_section_end(FALSE), .where = 'before')
      xml2::xml_add_sibling(table, make_section_end(TRUE), .where = 'after')
    }
    available <- if (landscape) 14840L else 9021L
    grid <- first(table, './w:tblGrid')
    widths <- suppressWarnings(as.numeric(xml2::xml_attr(find(table, './w:tblGrid/w:gridCol'), 'w')))
    if (length(widths) != columns || any(!is.finite(widths)) || sum(widths) <= 0) {
      widths <- c(.20, rep(.80 / (columns - 1L), columns - 1L))
    }
    if (columns == 11L) widths <- c(.16, rep(.084, 10L))
    if (columns == 7L && grepl('Construct|Light-exposure behaviour', text)) {
      widths <- c(.12, .11, .27, .11, .10, .14, .15)
    }
    widths <- as.integer(round(available * widths / sum(widths)))
    widths[[length(widths)]] <- available - sum(widths[-length(widths)])
    properties <- ensure(table, 'tblPr')
    property(properties, 'tblW', paste0('w:type="dxa" w:w="', available, '"'))
    property(properties, 'tblLayout', 'w:type="fixed"')
    property(properties, 'jc', 'w:val="left"')
    margins <- property(properties, 'tblCellMar')
    for (side in c('top','bottom','start','end')) property(margins, side,
      paste0('w:w="', if (side %in% c('top','bottom')) 55 else 70, '" w:type="dxa"'))
    if (missing(grid)) grid <- xml2::xml_add_sibling(properties, node('tblGrid'), .where = 'after')
    xml2::xml_remove(xml2::xml_children(grid))
    for (width in widths) xml2::xml_add_child(grid, node('gridCol', paste0('w:w="', width, '"')))
    for (row_index in seq_along(rows)) {
      row <- rows[[row_index]]
      next_is_note <- FALSE
      if (row_index < length(rows)) {
        following <- rows[[row_index + 1L]]
        following_cells <- find(following, './w:tc')
        next_is_note <- length(following_cells) == 1L && span(following_cells[[1L]]) == columns &&
          nchar(xml2::xml_text(following)) > 80L
      }
      rp <- ensure(row, 'trPr'); property(rp, 'cantSplit')
      cells <- find(row, './w:tc'); pos <- 1L
      group <- length(cells) == 1L && span(cells[[1L]]) == columns
      header <- length(find(rp, './w:tblHeader')) > 0L
      for (cell in cells) {
        extent <- span(cell)
        cp <- ensure(cell, 'tcPr')
        property(cp, 'tcW', paste0('w:type="dxa" w:w="', sum(widths[pos:(pos + extent - 1L)]), '"'))
        property(cp, 'vAlign', 'w:val="center"')
        pos <- pos + extent
        unsupported <- columns == 6L && grepl('Near-eye personal light-exposure metrics', text, fixed = TRUE) &&
          grepl('FDR not supported', xml2::xml_text(cell), fixed = TRUE)
        for (p in find(cell, './w:p')) {
          pp <- ensure(p, 'pPr')
          property(pp, 'jc', 'w:val="left"')
          property(pp, 'spacing', 'w:before="0" w:after="30" w:line="240" w:lineRule="auto"')
          property(pp, 'suppressLineNumbers')
          xml2::xml_remove(find(pp, './w:keepNext | ./w:pageBreakBefore'))
          if (header || (group && row_index < length(rows)) || next_is_note) property(pp, 'keepNext')
          for (run in find(p, './/w:r')) {
            rpr <- ensure(run, 'rPr')
            property(rpr, 'sz', 'w:val="18"'); property(rpr, 'szCs', 'w:val="18"')
            if (unsupported) property(rpr, 'color', 'w:val="777777"')
          }
        }
      }
    }
  }
  # Adjacent wide tables do not need an empty portrait section between them.
  # Likewise, a next-page section break already starts the following heading.
  has_content <- function(block) {
    xml2::xml_name(block) == 'tbl' || length(find(block,
      './/w:t[normalize-space()] | .//w:drawing | .//w:pict | .//w:object')) > 0L
  }
  is_landscape <- function(block) identical(xml2::xml_attr(
    first(block, './w:pPr/w:sectPr/w:pgSz'), 'orient'), 'landscape')
  remove_empty_paragraph <- function(p) {
    for (bookmark in find(p, './/w:bookmarkStart | .//w:bookmarkEnd')) {
      xml2::xml_add_sibling(p, bookmark, .where = 'before')
    }
    xml2::xml_remove(p)
  }
  for (section_end in find(body, './w:p[w:pPr/w:sectPr]')) {
    if (is_landscape(section_end)) next
    previous <- find(section_end, 'preceding-sibling::*')
    for (block in rev(as.list(previous))) {
      if (has_content(block)) break
      if (length(find(block, './w:pPr/w:sectPr'))) {
        if (is_landscape(block)) xml2::xml_remove(section_end)
        break
      }
      if (xml2::xml_name(block) == 'p') remove_empty_paragraph(block)
    }
  }
  for (section_end in find(body, './w:p[w:pPr/w:sectPr]')) {
    if (!is_landscape(section_end)) next
    for (block in as.list(find(section_end, 'following-sibling::*'))) {
      if (has_content(block)) {
        if (any(grepl('^(Heading|berschrift)', xml2::xml_attr(find(block, './w:pPr/w:pStyle'), 'val')))) {
          xml2::xml_remove(find(block, './w:pPr/w:pageBreakBefore'))
        }
        break
      }
      if (xml2::xml_name(block) == 'sectPr') {
        # The last table may finish the document in landscape orientation.
        final_section <- first(section_end, './w:pPr/w:sectPr')
        xml2::xml_add_sibling(block, final_section, .where = 'before')
        xml2::xml_remove(block)
        xml2::xml_remove(section_end)
        break
      }
      if (length(find(block, './w:pPr/w:sectPr'))) break
      if (xml2::xml_name(block) == 'p') remove_empty_paragraph(block)
    }
  }
  # Keep a compact final paragraph after the last table, providing a stable
  # document boundary without a blank page after the final landscape table.
  final_section <- first(body, './w:sectPr')
  ending_blocks <- find(final_section, 'preceding-sibling::w:p | preceding-sibling::w:tbl')
  if (length(ending_blocks) && xml2::xml_name(tail(ending_blocks, 1L)[[1L]]) == 'tbl') {
    closing <- xml2::xml_add_sibling(final_section, node('p'), .where = 'before')
    pp <- ensure(closing, 'pPr')
    property(pp, 'suppressLineNumbers')
    property(pp, 'spacing', 'w:before="0" w:after="0" w:line="20" w:lineRule="exact"')
  }
  # This marker makes the hook safe to run again on the same generated file.
  xml2::xml_add_child(body, xml2::xml_comment('Quarto publication Word layout v2'), .where = 0)
  stopifnot(identical(before_text, sort(xml2::xml_text(find(document, '//w:t[normalize-space()]')))),
    before_pictures == length(find(document, '//w:drawing')),
    !manuscript || table_count == 22L)
  styles_path <- file.path(work, 'word/styles.xml')
  styles <- xml2::read_xml(styles_path)
  style_nodes <- find(styles, '//w:style')
  style_ids <- xml2::xml_attr(style_nodes, 'styleId')
  style_names <- vapply(style_nodes, function(style) xml2::xml_attr(first(style, './w:name'), 'val'), character(1))
  for (reference in find(document, '//w:pStyle | //w:rStyle | //w:tblStyle')) {
    id <- xml2::xml_attr(reference, 'val')
    if (id %in% style_ids) next
    match <- match(tolower(id), tolower(style_names))
    if (!is.na(match)) xml2::xml_set_attr(reference, 'w:val', style_ids[[match]])
  }
  # Pandoc supplies author/date paragraphs even when a custom template lacks them.
  for (id in c('Author', 'Date')) if (!id %in% style_ids) {
    style <- xml2::xml_add_child(styles, node('style', paste0('w:type="paragraph" w:customStyle="1" w:styleId="', id, '"')))
    property(style, 'name', paste0('w:val="', id, '"'))
    normal_id <- xml2::xml_attr(first(styles, '//w:style[@w:type="paragraph" and @w:default="1"]'), 'styleId')
    property(style, 'basedOn', paste0('w:val="', normal_id, '"'))
  }
  normalize_word_xml(document)
  xml2::write_xml(document, document_path)
  # The reference template's footer otherwise inherits manuscript line numbering.
  for (footer_path in list.files(file.path(work, 'word'), pattern = '^footer[0-9]+[.]xml$', full.names = TRUE)) {
    footer <- xml2::read_xml(footer_path)
    for (paragraph in find(footer, '//w:p')) property(ensure(paragraph, 'pPr'), 'suppressLineNumbers')
    normalize_word_xml(footer)
    xml2::write_xml(footer, footer_path)
  }
  normalize_word_xml(styles)
  xml2::write_xml(styles, styles_path)
  output <- tempfile('manuscript-', tmpdir = normalizePath(dirname(path)), fileext = '.docx')
  on.exit(unlink(output), add = TRUE)
  # Word for Mac can reject explicit directory records in an otherwise valid
  # DOCX archive. Package the document parts only, without directory entries.
  zip::zipr(output, list.files(work, all.files = TRUE, no.. = TRUE), root = work,
    include_directories = FALSE)
  # Publish a complete new file instead of rewriting an inode Word may have open.
  stopifnot(file.rename(output, path))
  message('Word layout: ', table_count, ' editable tables; ', landscape_count,
    ' landscape sections; text and ', before_pictures, ' images preserved.')
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  paths <- commandArgs(trailingOnly = TRUE)
  if (!length(paths)) paths <- strsplit(Sys.getenv('QUARTO_PROJECT_OUTPUT_FILES'), '\n', fixed = TRUE)[[1L]]
  for (path in paths[grepl('[.]docx$', paths, ignore.case = TRUE)]) format_manuscript_word(path)
}
