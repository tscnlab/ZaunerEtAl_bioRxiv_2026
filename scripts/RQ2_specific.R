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

difference_sz <- function(model, data, x, fac, lev1, lev2,
                          sz_term,
                          exclude = NULL,
                          unconditional = FALSE,
                          level = 0.95) {
  
  data1 <- data
  data2 <- data
  
  fac_levels <- levels(model.frame(model)[[fac]])
  
  data1[[fac]] <- factor(rep(lev1, nrow(data1)), levels = fac_levels)
  
  data2[[fac]] <- factor(rep(lev2, nrow(data2)), levels = fac_levels)
  
  X1 <- predict(
    
    model, 
    newdata = data1,
    type = "lpmatrix",
    exclude = exclude,
    newdata.guaranteed = TRUE
  )
  
  X2 <- predict(
    model, 
    newdata = data2,
    type = "lpmatrix",
    exclude = exclude,
    newdata.guaranteed = TRUE
  )
  
  Xd <- X1 - X2
  
  ## keep only the sz smooth columns
  sm_labels <- vapply(model$smooth, `[[`, character(1), "label")
  i <- match(sz_term, sm_labels)
  
  if (is.na(i)) {
    stop(
      "Smooth not found. Available smooth labels are:\n",
      paste(sm_labels, collapse = "\n")
    )
  }
  
  keep <- model$smooth[[i]]$first.para:model$smooth[[i]]$last.para
  Xd[, setdiff(seq_len(ncol(Xd)), keep)] <- 0
  
  beta <- coef(model)
  V <- vcov(model, unconditional = unconditional)
  
  fit <- drop(Xd %*% beta)
  se <- sqrt(rowSums((Xd %*% V) * Xd))
  
  crit <- qnorm(1 - (1 - level) / 2)
  
  tibble(
    {{ x }} := data[[x]],
    comparison = paste0(lev1, "_", lev2),
    diff = fit,
    se = se,
    lower = fit - crit * se,
    upper = fit + crit * se
  )
}
