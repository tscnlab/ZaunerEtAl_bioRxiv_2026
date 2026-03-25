source("scripts/helpers.R")

model_table <- function(name, p.value, summary, metric_type, response, family) {
  if(is.null(summary)) return()
  if(!"group" %in% names(summary)) summary <- summary |> mutate(group = NA)
  table <- 
  tibble(
    metric_type = metric_type,
    metric = name,
    response = response,
    family = family$family,
    p.value = p.value |>
      p_styling(),
    summary |>
      mutate(
        term = str_remove_all(term, "\\(|\\)|site"),
        term = replace_values(
          term,
          "sd__Intercept" ~ "SD Participant",
          "sd__Observation" ~ "SD Residual",
        ) |> 
          replace_when(
                       group == "site" ~ "SD Site",
                       group == "Residual" ~ "SD Residual",
                       group == "Id:site" ~ "SD Participant",
          )
      ) |>
      select(term, estimate) |>
      pivot_wider(names_from = term, values_from = estimate) |>
      mutate(
        BAUA = if (exists("FUSPCEU"))
          0
        else
          NA,
        .after = Intercept,
        # across(any_of(names(
        #   melidos_countries
        # ) |> sort()), \(x) x + Intercept, .names = "{.col}_total")
      ) |> 
      relocate(any_of(names(
        melidos_countries
      ) |> sort()), .after = BAUA)
  )
  
}

inference_table <- function(data, p_adjustment, scaling = TRUE) {
  
  red_data <- 
    data |> 
    drop_na(table) |> 
    arrange(metric_type, name)
  
  gt_table <- 
    red_data |> 
    pull(table) |> 
    list_rbind() |>
    relocate(`SD Residual`, .after = `SD Participant`) |> 
    mutate(metric_type = metric_type |> str_to_title())
  
  if (scaling) {
    scaling_names <-
      gt_table |>  ungroup() |> select(where(is.numeric)) |> names()
    
    dAIC_names <- gt_table |> ungroup() |> select(starts_with("dAIC_")) |> names()
    scaling_names <- setdiff(scaling_names, dAIC_names)
    
    gt_table <-
      gt_table |>
      rowwise() |>
      mutate(
        across(all_of(scaling_names), \(x) {
          x <- switch(
            response,
            "log_zero_inflated(metric)" = 10^x,
            "qlogis(metric)" = x,
            "metric" = x,
            stop("no correct response transformation defined")
          )
          x <- switch(family,
                      "tweedie" = exp(x),
                      "gaussian" = x,
                      stop("no correct scaling family assigned"))
          x
        }),
        `Coefs are` =
          replace_values(
            response,
            "log_zero_inflated(metric)" ~ "multiplied",
            "metric" ~ "additive",
            "qlogis(metric)" ~ "logit scale"
          ) |>
          replace_when(family == "tweedie" ~ "multiplied"),
        .after = family
      )
  }
  
  gt_table <- 
    gt_table |> 
    group_by(metric_type) |> 
    gt(rowname_col = "metric") %>% 
    cols_hide(c(response, family)) |> 
    fmt_markdown(columns = "p.value", md_engine = "commonmark") %>% 
    tab_footnote(
      "Models with a tweedie error distribution do not return a residual standard deviation, as a dispersion parameter is estimated instead during modeling.",
      locations = cells_column_labels(columns = "SD Residual")
    ) |> 
    tab_footnote(
      paste("p-values are adjusted for multiple comparisons using the false-discovery-rate for n=", p_adjustment, "comparisons"),
      locations = cells_column_labels(columns = "p.value")
    ) %>% 
    tab_footnote(
      paste("Dynamics-based metrics are calculated per participant and thus are using linear/generalized models instead of the mixed-model framework"),
      locations = cells_row_groups("Dynamics")
    ) %>% 
    tab_spanner(
      label = md("Site intercept (±coefficients)"),
      columns = c(all_of(names(melidos_cities) |> sort()), ends_with("_total"))
    ) %>% 
    tab_footnote(
      paste("Sites have only entries if the (adjusted) p-value is significant, otherwise the results for the null-model are shown. Entries show the site intercept, with the site-specific coefficient below in brackets (relative to the reference level)."),
      locations = cells_column_spanners(starts_with("Site "))
    ) %>% 
    tab_footnote(
      md("*multiplied*: coefficients are multiplicative. This comes from the fact that the models were calculated on a log scale and backtransformed in the table. The Intercept can be read as linear scale, with coefficients being multiplied with the intercept. *additive*: All values are on the linear scale and no transformation is necessary. *logit scale*: data were modelled on the logit scale. Coefficients can be added to the intercept, but have to be transformed with the logistic function."),
      locations = cells_column_labels(columns = "Coefs are")
    ) %>% 
    fmt(metric, fns = \(x) x |> str_to_title() |>  str_replace_all("_", " ")) |> 
    sub_values(values = "MDER", replacement = "MDER")
  gt_table %>% 
    cols_add(Plot = 1:nrow(data |> drop_na(table))) %>% 
    text_transform(locations = cells_body(Plot),
                   fn = \(x) {
                     gt::ggplot_image(
                       ridges_function(as.numeric(x),red_data),
                       height = gt::px(80), 
                       aspect_ratio = 2
                     )
                   }) %>% 
    gt_multiple(names(melidos_cities), style_tab) |> 
    cols_label(
      p.value = "p-value",
      photoperiod = "Photoperiod",
      lat = "Latitude",
      Plot = "Distribution"
    ) |> 
    tab_style(
      style = cell_text(weight = "bold"),
      locations = list(cells_column_labels(), cells_stub(), cells_column_spanners(), cells_row_groups())
    ) |> 
    sub_missing() |>
    # gt_multiple(names(melidos_cities), merge_columns) |> 
    fmt_number(where(is.numeric)) |> 
    fmt_number(rows = str_detect(metric, "dose"), decimals = 0) |> 
    fmt_number(any_of(c(names(melidos_cities), "photoperiod", "lat"))) |> 
    fmt_duration(
      any_of(
        c(paste0(names(melidos_cities), "_total"), "Intercept")),
      str_detect(metric, "duration|period"),
      input_units = "hours",
      max_output_units = 2
      ) |> 
    # fmt_duration(
    #   c(paste0(names(melidos_cities), "_total"), "Intercept"),
    #   rows = str_detect(metric, "midpoint|timing"),
    #   input_units = "hours",
    #   output_units = "hours",
    #   duration_style = "colon-sep"
    # ) |>
    fmt_duration(
      c(names(melidos_cities), "photoperiod", "lat", "SD Participant", "SD Residual", "SD Site"),
      rows = str_detect(metric, "midpoint|timing"),
      input_units = "hours",
      max_output_units = 2
      # duration_style = "narrow"
    ) |> 
    tab_style(
      style = cell_text(align = "center"),
      locations = list(cells_column_labels(),
                       cells_body())
    )
}

