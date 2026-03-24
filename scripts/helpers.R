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

#function for a ridgeline plot in tables
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

#second function for ridgeline plots
ridges_function2 <- function(data, scaling) {
  if(scaling == "log_zero_inflated") {
    data <- 
      data |> 
      mutate(metric = log_zero_inflated(metric))
  }
  data |> 
    ggplot(aes(x=metric)) +
    geom_density_ridges(aes(y=site, fill = site),
                        linewidth = 1, colour = NA,
                        alpha = 0.5,
                        from = min(data$metric, na.rm =TRUE),
                        to = max(data$metric, na.rm =TRUE)
    ) +
    geom_density_ridges(aes(y=site, color = site), fill = NA,
                        alpha = 1, linewidth = 1.5,
                        quantile_lines = TRUE, quantiles = 2,
                        linetype = 1,
                        from = min(data$metric, na.rm =TRUE),
                        to = max(data$metric, na.rm =TRUE)
    ) +
    scale_fill_manual(values = melidos_colors) +
    scale_alpha_continuous(range = c(0, 1)) +
    scale_color_manual(values = melidos_colors) +
    guides(fill = "none", color = "none") +
    labs(y = NULL, x = NULL) +
    theme_ridges() +
    coord_flip(clip = "off") +
    # theme_sub_panel(margin = margin(t = 30)) +
    theme_sub_axis(text = element_blank())
}

merge_desc_columns <- function(table, column){
  table |> 
    cols_merge(ends_with(column),
               pattern = "**{1}**<< ±{2}>><<<br>({3}, {4})>><<<br>n={5}>>")
}

change_point <- function(x){
  which(x[-1] != x[-length(x)]) + 1
}
