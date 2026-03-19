
model_summary <- function(significant, H0model, H1model) {
  if(is.na(significant)) return()
  switch(significant+1,
         tidy(H0model),
         tidy(H1model))
}

p_styling <- function(p.value, sig.level = 0.05) {
  significant <- p.value <= 0.05
  p.value <- p.value |> style_pvalue()
  p.value <- 
  if(significant) paste0("**", p.value, "**") else p.value
  p.value |> str_replace_all("\\>", "\\\\>")
}

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
        across(any_of(names(
          melidos_countries
        ) |> sort()), \(x) x + Intercept, .names = "{.col}_total")
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
    tab_style(
      style = cell_text(weight = "bold"),
      locations = list(cells_column_labels(), cells_stub(), cells_column_spanners(), cells_row_groups())
    ) |> 
    fmt(metric, fns = \(x) x |> str_to_title() |>  str_replace_all("_", " ")) |> 
    sub_values(values = "MDER", replacement = "MDER")
  gt_table %>% 
    cols_add(Plot = 1:nrow(data |> drop_na(table))) %>% 
    text_transform(locations = cells_body(Plot),
                   fn = \(x) {
                     gt::ggplot_image(
                       ridges_function(as.numeric(x),red_data, metric),
                       height = gt::px(80), 
                       aspect_ratio = 2
                     )
                   }) %>% 
    gt_multiple(names(melidos_cities), style_tab) |> 
    cols_label(
      p.value = "p-value",
      photoperiod = "Photoperiod",
      lat = "Latitude",
      Plot = "Ridgeline distribution"
    ) |> 
    sub_missing(columns = -c(names(melidos_cities))) |>
    gt_multiple(names(melidos_cities), merge_columns) |> 
    fmt_number(where(is.numeric)) |> 
    fmt_number(rows = str_detect(metric, "dose"), decimals = 0) |> 
    fmt_number(any_of(c(names(melidos_cities), "photoperiod", "lat"))) |> 
    fmt_duration(
      any_of(
        c(paste0(names(melidos_cities), "_total"), "Intercept", "photoperiod", "lat", "SD Participant", "SD Residual", "SD Site")),
      str_detect(metric, "duration|period"),
      input_units = "hours",
      max_output_units = 2
      ) |> 
    fmt_duration(
      c(paste0(names(melidos_cities), "_total"), "Intercept"),
      rows = str_detect(metric, "midpoint|timing"),
      input_units = "hours",
      output_units = "hours",
      duration_style = "colon-sep"
    ) |>
    fmt_duration(
      c(names(melidos_cities), "photoperiod", "lat", "SD Participant", "SD Residual", "SD Site"),
      rows = str_detect(metric, "midpoint|timing"),
      input_units = "hours",
      max_output_units = 2
      # duration_style = "narrow"
    ) |>
    cols_width(Plot ~ px(200))
}

merge_columns <- function(table, column){
  table |> 
    cols_merge(all_of(c(column, paste0(column, "_total"))),
               pattern = "{2}<<\n({1})>>")
}

style_tab <- function(table, column) {
  table |> 
    tab_style(
      style = list(cell_text(color = melidos_colors[column])
                   ),
      locations = cells_column_labels(column)
    ) |> 
    tab_style(
      style = list(
                   cell_fill(color = melidos_colors[column],
                             alpha = 0.05)),
      locations = cells_body(column)
    )
}

style_AICbased <- function(table, column, dif = 2){
  dAIC <- paste0("dAIC_", column)
  dAICsym <- sym(dAIC)
  
  table |> 
    tab_style(
      style = list(cell_text(weight = "bold")),
      locations = cells_body(column, !!dAICsym >= dif)
    )|> 
    tab_style(
      style = list(cell_text(color = "grey")),
      locations = cells_body(column, !!dAICsym <= -dif)
    )
}

gt_multiple <- function(table, names, fun){
  names |> purrr::reduce(\(tab, name) tab |> fun(name), .init = table)
}

H1_table <-  function(data, p_adjustment) {
  inference_table(data, p_adjustment) |> 
    tab_header("Model results for Hypothesis 1",
               subtitle = H1) |> 
    gt_multiple(c("lat", "SD Site", "photoperiod"), style_AICbased) |> 
    cols_hide(starts_with("dAIC_")) |>
    tab_footnote(
      md("These coefficients (*Latitude*, *Photoperiod*) and random effects (*SD Site*) come from two respective separate models that did not contain a fixed effect of site. If the random site or fixed latitude effect is significant, a value is presented. If AIC indicates a significant improvement over the base model (site as fixed effect), it is shown in **bold**. If the base model is significantly stronger, however, values are shown in <i style = 'color:grey'>grey</i>."),
      locations = cells_column_labels(c(lat, photoperiod, `SD Site`))
    ) |> 
    tab_footnote(
      md("*Photoperiod*: coefficient per 1-hour change in photoperiod. *Latitude*: coefficient per 10° change in latitude. *SD Site*: random effect standard deviation for site."),
      locations = cells_column_labels(c(lat, photoperiod, `SD Site`))
    ) |> 
    tab_style(
      style = cell_borders(
        sides = "right",
        weight = px(1),
        color = "lightgrey"
      ),
      locations = cells_body(`SD Residual`)
    ) |> 
    tab_spanner(
      label = md("Comparative models"),
      columns = c("photoperiod", "lat", "SD Site")
    )
    
}

#function for a ridgeline plot
ridges_function <- function(datanumber, data, value) {
  purrr::map(datanumber, \(x) {
    
    response <- data$response[[x]]
    family <- data$family[[x]]$family
    scaling <- 
      ifelse(family == "tweedie", family, response) |> 
      switch(
        "tweedie" =,
        "log_zero_inflated(metric)" = "symlog",
        "identity"
      )
    
    data$data[[x]] %>% 
      ggplot(aes(x={{ value }})) +
      geom_density_ridges(aes(y=site, fill = site))+
      scale_fill_manual(values = melidos_colors) +
      scale_x_continuous(trans = scaling) +
      theme_void() +
      theme(
        # axis.text.x = element_text(),
        legend.position = "none",
        plot.margin = margin(5,30,5,5)
      ) +
      coord_flip()
  })
}

H1_combining_tables <- function(table, table2, AICs, variable, H1, H2){
  if(is.null(table)) return()
  
  dAIC <- paste0("dAIC_", variable)

  if(!is.null(table2)){
    
    table <- 
      table |> 
      mutate(
        table2 |> 
          select(any_of(variable)),
        !!dAIC := AIC_dif(AICs, H1, H2)
      )
    
    if(!variable %in% names(table)) {
      table <- table |> mutate(!!variable := NA)
    }
    
    variable_sym <- sym(variable)
    
    table <- 
      table |> 
      mutate(
        across(any_of(dAIC),
               \(x) ifelse(is.na({{ variable_sym }}), NA, x))
      ) |> 
      relocate(any_of(c(variable, dAIC)), .after = last_col())
  }

  table
}
