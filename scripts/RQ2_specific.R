bold_p. <- function(table, name) {
  table |> 
    tab_style(
      style = cell_text(weight = "bold"),
      locations = 
        cells_body(
          rows = !!rlang::sym(paste0("signif_", name)),
          columns = paste0("estimate_", name)
        )
    )
}

style_rows <- function(table, column) {
  table |> 
    tab_style(
      style = list(cell_text(color = melidos_colors[column])
      ),
      locations = cells_body(columns = site, rows = site == column)
    ) |> 
    tab_style(
      style = list(
                   cell_fill(color = melidos_colors[column],
                             alpha = 0.05)
      ),
      locations = cells_body(rows = site == column)
    )
    
}


gam_deriv_plot <- function(model, name) {
  deriv <- derivatives(model, select = "s(photoperiod)")
  deriv_signif <- deriv |> filter(.lower_ci > 0) |> slice_tail(n=1)
  deriv_plot <- 
    draw(deriv) + 
    theme_cowplot() +
    geom_hline(yintercept = 0, col = "red") +
    geom_vline(data = deriv_signif, 
               aes(xintercept = photoperiod), col = "red", linetype = "dashed") +
    annotate(geom = "label", size = 4,
             label = paste0("Significant rise\nends at ", 
                            deriv_signif$photoperiod |> round(1),
                            " hrs"), 
             x = deriv_signif$photoperiod, y = 0, vjust = 1.2, hjust = 1.025,
             col = "red") +
    labs(title = NULL)
  
  sm <- smooth_estimates(model, data = model$model,
                         select = "s(photoperiod)")
  
  pr <- partial_residuals(model, select = "s(photoperiod)")
  sm <- cbind(sm, pr)
  
  term_plot <-
    ggplot(sm, aes(x = photoperiod, y = .estimate)) +
    geom_ribbon(aes(ymin = .estimate-1.96*.se, ymax = .estimate+1.96*.se), alpha = 0.2) +
    geom_line() +
    geom_point(aes(y = `s(photoperiod)`), color = "skyblue3", alpha = 0.25) +  # harmless, keeps mapping stable
    theme_cowplot() +
    geom_vline(
      xintercept = deriv_signif$photoperiod,
      col = "red",
      linetype = "dashed"
    ) +
    labs(y = "s(photoperiod)", x = "photoperiod")
  
  term_plot + deriv_plot + plot_annotation(title = paste0("Metric: ", name))
}
