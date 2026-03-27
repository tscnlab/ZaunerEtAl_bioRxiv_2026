Fig3_wrapper <- function(data){
  Fig3_plot(data$data[[1]], "identity", data$metric_type[[1]], data$name[[1]])
}

Fig3_plot <- function(data, scaling, type, metric_name, prune_y = TRUE) {
  if(type == "level") {
    data <-
      data |>
      mutate(metric = log_zero_inflated(metric))
  }
  data |> 
    site_conv_mutate() |> 
    ggplot(aes(x=metric)) +
    geom_boxplot(aes(y= site, col = site), width = 0.25,
                 position = position_nudge(y = -0.25)) +
    geom_density_ridges(aes(y=site, fill = site),
                        linewidth = 1, colour = NA,
                        alpha = 0.5,
                        scale = 1,
                        from = min(data$metric, na.rm =TRUE),
                        to = max(data$metric, na.rm =TRUE),
    ) +
    geom_density_ridges(aes(y=site, color = site), fill = NA,
                        alpha = 1, linewidth = 1,
                        scale = 1,
                        quantile_lines = TRUE, quantiles = 2, vline_color = "red",
                        linetype = 1,
                        from = min(data$metric, na.rm =TRUE),
                        to = max(data$metric, na.rm =TRUE),
    ) +
    {
      if(type == "level") {
        scale_x_continuous(
                           labels = \(x) exp_zero_inflated(x) |> round(0))
      }
    } +
    {
      if(type %in% c("duration", "timing")) {
          scale_x_continuous(
            breaks = \(x) {
              if((x[2]-x[1]) > 14*60*60) {
            seq(-24*60*60, 24*60*60, by = 4*3600)
            } else seq(-24*60*60, 24*60*60, by = 2*3600)
              },
                             labels = \(x) {
                               x <- map_dbl(x,\(x) {
                                 if(is.na(x)) return(NA)
                                 if(x<0) x+24*60*60 else x
                                 })
                               x |> 
                                 hms::as_hms() |> 
                                 strptime("%H:%M:%S") |> 
                                 format("%H:%M")
                               } 
          )
      }
    } +
    scale_fill_manual(values = melidos_colors) +
    scale_alpha_continuous(range = c(0, 1)) +
    scale_color_manual(values = melidos_colors) +
    guides(fill = "none", color = "none") +
    labs(y = NULL, x = metric_name) +
    theme_ridges() +
    coord_cartesian(clip = "off") +
    theme_sub_plot(margin = margin(r = 20, t = 20)) +
    {
      if((!metric_name %in% c("Darkest 10h midpoint (HH:MM)" ,
                             "Mean (lx; from geometric mean)",
                             "Period above 250 lx mel EDI  (HH:MM)",
                             "Duration above 1000 lx mel EDI  (HH:MM)")) &
         prune_y) {
        theme_sub_axis_left(text = element_blank())
      } else theme_sub_axis_left(text = element_text(vjust = -1))
    }
    
}
