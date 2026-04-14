merge_columns <- function(table, column){
  table |> 
    cols_merge(all_of(c(column, paste0(column, "_total"))),
               pattern = "{2}<<\n({1})>>")
}

style_tab <- function(table, column) {
  table |> 
    tab_style(
      style = list(cell_text(color = melidosData::melidos_colors[column])
      ),
      locations = cells_column_labels(column)
    ) |> 
    tab_style(
      style = list(
        cell_fill(color = melidosData::melidos_colors[column],
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
ridges_function <- function(datanumber, data) {
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
    
    data <- data$data[[x]]
    
    if(scaling == "symlog") {
     data <- data |> mutate(metric = log_zero_inflated(metric)) 
    }
      

    data |> 
      site_conv_mutate(rev = FALSE) |> 
      ggplot(aes(x=metric)) +
      geom_density_ridges(aes(y=site, fill = site),
                          linewidth = 1, colour = NA,
                          alpha = 0.5,
                          from = min(data$metric, na.rm =TRUE),
                          to = max(data$metric, na.rm =TRUE)
      ) +
      geom_density_ridges(aes(y=site, color = site), fill = NA,
                          alpha = 1, linewidth = 4,
                          quantile_lines = TRUE, quantiles = 2, vline_color = "red",
                          linetype = 1,
                          from = min(data$metric, na.rm =TRUE),
                          to = max(data$metric, na.rm =TRUE)
      ) +
      scale_fill_manual(values = melidos_colors) +
      # {
      #   if(scaling == "symlog") {
      #     scale_x_continuous(labels = \(x) x |> exp_zero_inflated() |> signif(2))
      #   }
      # } +
      scale_alpha_continuous(range = c(0, 1)) +
      scale_color_manual(values = melidos_colors) +
      guides(fill = "none", color = "none") +
      labs(y = NULL, x = NULL) +
      theme_ridges(font_size = 40) +
      coord_flip(clip = "off") +
      theme_sub_plot(margin = margin(r = 30, t = 20)) +
      theme_sub_axis_bottom(text = element_blank())+
      theme_sub_axis_left(text = element_text(vjust = 0))
  })
}

#second function for ridgeline plots
ridges_function2 <- function(data, scaling) {
  if(scaling == "log_10_zero_inflated") {
    data <- 
      data |> 
      mutate(metric = log_zero_inflated(metric))
  }
  data |> 
    site_conv_mutate(rev = FALSE) |> 
    ggplot(aes(x=metric)) +
    geom_density_ridges(aes(y=site, fill = site),
                        linewidth = 1, colour = NA,
                        alpha = 0.5,
                        from = min(data$metric, na.rm =TRUE),
                        to = max(data$metric, na.rm =TRUE)
    ) +
    geom_density_ridges(aes(y=site, color = site), fill = NA,
                        alpha = 1, linewidth = 4,
                        quantile_lines = TRUE, quantiles = 2, vline_color = "red",
                        linetype = 1,
                        from = min(data$metric, na.rm =TRUE),
                        to = max(data$metric, na.rm =TRUE)
    ) +
    scale_fill_manual(values = melidos_colors) +
    scale_alpha_continuous(range = c(0, 1)) +
    scale_color_manual(values = melidos_colors) +
    guides(fill = "none", color = "none") +
    labs(y = NULL, x = NULL) +
    theme_ridges(font_size = 40) +
    coord_flip(clip = "off") +
    theme_sub_plot(margin = margin(r = 20, t = 20)) +
    theme_sub_axis_bottom(text = element_blank())+
    theme_sub_axis_left(text = element_text(vjust = 0))
}

merge_desc_columns <- function(table, column){
  table |> 
    cols_merge(ends_with(column),
               pattern = "**{1}**<br>({4}, {5})<br>*{2} ±{3}*<br><span style = 'color:grey'>n={6}</span>")
}

change_point <- function(x){
  which(x[-1] != x[-length(x)]) + 1
}

datetime_handler <- function(x, fun = \(x) mean(x, na.rm = TRUE)) {
  if(all(is.na(x))) return(na_dbl)
  x_tz <- tz(x)
  x_date <- date(x)
  x_time <- LightLogR:::datetime_to_circular(x)
  
  x_date_handled <- fun(x_date)
  x_time_handled <- 
    fun(x_time) |> 
    LightLogR:::circular_to_hms() |> 
    strptime("%H:%M:%S", tz = x_tz)
  
  date(x_time_handled) <- x_date_handled
  
  x_date_handled
}

melidos_sites <- 
  tibble(
    site = names(melidos_countries),
    site_name =
      paste(melidos_cities, 
            c("(SE)", "(ES)", "(DE)", "(DE)", "(DE)", "(NL)", "(TR)", "(GH)", "(CR)")
            ) |> 
    replace_values("San Pedro, San José (CR)" ~ "San José (CR)")
  )

melidos_order <- c("RISE", "THUAS", "BAUA", "MPI", "TUM", "FUSPCEU", 
                   "IZTECH", "UCR", "KNUST")

site_conversion <- function(x){
  x |> 
    replace_values(
      from = melidos_sites$site,
      to = melidos_sites$site_name
    )
}

site_conv_mutate <- function(data, site = site, rev = TRUE, other.levels = NULL){
  
  if(rev) melidos_order <- rev(melidos_order)
  
  if(!is.null(other.levels)) {
    melidos_order <- c(other.levels, melidos_order)
  }
  
  factor_conv <- function(x) {
      if(!inherits(x, "factor")) {
        x <- fct(x, levels = melidos_order)
      }
    inject(fct_relevel(x, !!!melidos_order)) |> 
      fct_relabel(site_conversion)
  }
  # browser()
  data |> 
    mutate({{ site }} := {{ site }} |> factor_conv())
}

melidos_colors <- 
  melidos_colors |> set_names(melidos_sites$site_name)

site_conv_gt <- function(table, after = "Overall", rev = FALSE){
  
  if(rev) melidos_order <- rev(melidos_order)
  
  table |> 
    cols_label_with(
      columns = matches(names(melidos_cities)),
      fn = site_conversion
        ) |> 
    cols_move(melidos_order, after = after)
}

lm_r2 <- function(model) {
  model_summary <- model |> summary()
  r2 <- list(R2_marginal = model_summary$r.squared,
             R2_conditional = model_summary$r.squared
  )
  r2
}

r2_helper <- function(model, ...) {
  if(is.null(model)) return(NULL)
  switch(class(model),
         "lm" = lm_r2(model),
         r2_nakagawa_helper(model, ...))
}
  
r2_nakagawa_helper <- function(model, data, family, response, random_formula = "(1 | site:Id)") {
  null_formula <- as.formula(paste(response, " ~ 1 +", random_formula))
  
  null_model <- tryCatch(
    glmmTMB::glmmTMB(
      formula = null_formula,
      family = family,
      data = data
    ),
    error = function(e) NULL
  )
  
  out <- tryCatch(
    performance::r2_nakagawa(model, null_model = null_model),
    warning = function(w) {
      message("r2 warning: ", conditionMessage(w))
      return(NA)
    },
    error = function(e) {
      message("r2 error: ", conditionMessage(e))
      return(NA)
    }
  )
  
  out
}

test_term <- function(model, term, do.anova = FALSE){
  reduced <- update(model, paste(". ~ . -", term))
  if(do.anova) {
    anova(reduced, model)$`Pr(>Chisq)`[2]
  } else reduced
  
}
