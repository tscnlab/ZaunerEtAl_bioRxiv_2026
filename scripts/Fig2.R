Fig2_plot_individual <- function(data, site_name) {

    site_color <- melidosData::melidos_colors[site_name]
    
    data |> 
    mutate(sleep = replace_values(sleep, "wake" ~ NA),
     ) |> 
    filter(site == site_name) |> 
    site_conv_mutate(rev = FALSE) |> 
    gg_doubleplot(geom = "blank",
                  facetting = FALSE,
                  jco_color = FALSE,
                  x.axis.label = "Local time (HH:MM)",
                  y.axis.label = "Melanopic EDI (lx)",
                  aes_fill = site
    ) |> 
    gg_photoperiod() |> 
    gg_states(sleep, aes_fill = sleep, ymax = -0.1, fill = "red", alpha = 1,
              on.top = TRUE) +
    facet_wrap(~site, nrow = 3, ncol = 3) + 
    geom_ribbon(aes(ymin = lower95, ymax = upper95, fill = site), alpha = 0.4) +
    geom_ribbon(aes(ymin = lower75, ymax = upper75, fill = site), alpha = 0.4) +
    geom_ribbon(aes(ymin = lower50, ymax = upper50, fill = site), alpha = 0.4) +
    geom_line(aes(y = MEDI), linewidth = 1.5) +
    map(c(1,10,250), 
        \(x) geom_hline(aes(yintercept = x), col = "grey", linetype = "dashed")
    ) +
    scale_color_manual(values = melidos_colors) +
    scale_fill_manual(values = melidos_colors) +
    coord_cartesian(ylim = c(0, 100000)) +
    guides(y = guide_axis_stack(Brown_bracket, "axis"), fill = "none",
           color = "none") +
    # labs(x = NULL)
    labs(
      caption = glue(
        "<i>daytime</i>, <i>evening</i>, and <i>sleep</i> indicate 
          recommendations for healthy light exposure (Brown et al., 2022). 
          <br><b>Median</b> with <b style = 'color:{alpha(site_color,
          alpha = 0.9)}'>50%</b>, <b style = 'color:{alpha(site_color,
          alpha = 0.75)}'>75%</b>, or <b style = 'color:{alpha(site_color,
          alpha = 0.5)}'>95%</b> of data.
          <br>The horizontal bars show
          <b style = 'color:red'>average sleep times</b>. The vertical bars show 
          <b style = 'color:grey'>average nighttimes</b>."
      )
    ) +
    theme(plot.caption = ggtext::element_markdown(),
          panel.spacing.x = unit(30, "pt"),
          plot.background = element_blank())
  
  
}
