
H1_table <-  function(data, p_adjustment) {
  inference_table(data, p_adjustment) |> 
    tab_header("Model results for Hypothesis 1",
               subtitle = H1) |> 
    gt_multiple(c("lat", "SD Site", "photoperiod"), style_AICbased) |> 
    cols_hide(starts_with("dAIC_")) |>
    tab_footnote(
      md("These coefficients (*Latitude*) and random effects (*SD Site*) come from two respective separate models that did not contain a fixed effect of site. If the random site or fixed latitude effect is significant, a value is presented. If AIC indicates a significant improvement over the base model (site as fixed effect), it is shown in **bold**. If the base model is significantly stronger, however, values are shown in <i style = 'color:grey'>grey</i>."),
      locations = cells_column_labels(c(lat, `SD Site`))
    ) |> 
    tab_footnote(
      md("*Photoperiod*: coefficient per 1-hour change in photoperiod. *Latitude*: coefficient per 10° change in latitude. *SD Site*: random effect standard deviation for site."),
      locations = cells_column_labels(c(lat, photoperiod, `SD Site`))
    ) |> 
    tab_footnote(
      md("If the coefficient is greyed out it means it is not significant in a model base minus photoperiod."),
      locations = cells_column_labels(c(photoperiod))
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
      columns = c("lat", "SD Site")
    )
  
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