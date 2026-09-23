# Display construction from current numerical summaries.
brown_main_figures <- function() {
  library(ggplot2)
levels <- br_read("estimands/equal_site_means.csv")[
  sample_id == "primary_any_valid"
]
work <- br_read("estimands/compact_table_source.csv")[
  sample_id == "primary_any_valid" &
    row_kind == "site" &
    day_type_display == "Work day"
]
m4 <- br_read("multiplicity/BA_M4.csv")[sample_id == "primary_any_valid"]
m6 <- br_read("multiplicity/BA_M6_primary.csv")
coverage <- br_read("multiplicity/BA_M1.csv")
key <- c("analysis_state", "site")
effects <- merge(
  m4,
  m6[,
    c(key, "p_adjusted", "fdr_significant", "state_order", "site_order"),
    with = FALSE
  ],
  by = key,
  suffixes = c("_zero", "_average"),
  sort = FALSE
)
references <- coverage[
  sample_id == "primary_any_valid",
  .(analysis_state, reference = estimate)
]
effects <- merge(effects, references, by = "analysis_state", sort = FALSE)
work <- merge(
  work,
  levels[
    day_type_display == "Work day",
    .(analysis_state, reference = estimate)
  ],
  by = "analysis_state",
  sort = FALSE
)
orders <- m6[, .(analysis_state, site, state_order, site_order)]
work <- merge(work, orders, by = key, sort = FALSE)
setorder(work, state_order, site_order)
setorder(effects, state_order, site_order)
window_levels <- c("Daytime", "Pre-sleep", "Sleep")
site_levels <- m6[state_order == 1L][order(site_order), site_display]
for (name in c("levels", "work", "effects", "coverage")) {
  d <- get(name)
  d[, Window := factor(state_display, levels = window_levels)]
  d[, `:=`(
    point = 100 * estimate,
    lower = 100 * conf_low,
    upper = 100 * conf_high
  )]
  if ("site_display" %in% names(d))
    d[, Site := factor(site_display, levels = rev(site_levels))]
  if ("reference" %in% names(d)) d[, reference_pp := 100 * reference]
  assign(name, d)
}
levels[, Day := factor(day_type_display, levels = c("Work day", "Free day"))]
coverage[,
  Sample := factor(
    br_sample(sample_id),
    levels = c("Any valid period", "At least 80% coverage")
  )
]
work[,
  Mark := factor(
    ifelse(
      contrast_significant,
      "Different from equal-site mean",
      "FDR threshold not met"
    ),
    levels = c("FDR threshold not met", "Different from equal-site mean")
  )
]
effects[,
  Mark := factor(
    ifelse(
      p_adjusted_zero < .05,
      "Different from zero",
      "FDR threshold not met"
    ),
    levels = c("FDR threshold not met", "Different from zero")
  )
]
ink <- "#20394C"
blue <- "#0072B2"
orange <- "#D55E00"
base_theme <- theme_minimal(base_size = 9, base_family = "sans") +
  theme(
    text = element_text(color = ink),
    axis.title = element_text(size = 9),
    axis.text = element_text(size = 8, color = ink),
    legend.position = "top",
    legend.title = element_blank(),
    legend.text = element_text(size = 8),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "#CED8DF", linewidth = .25),
    panel.grid.major.y = element_line(color = "#E3E9ED", linewidth = .2),
    strip.text = element_text(size = 9, face = "bold"),
    plot.margin = margin(7, 8, 7, 7),
    plot.caption = element_text(size = 8, hjust = 0),
    plot.caption.position = "plot",
    panel.spacing.y = unit(4, "mm")
  )
dodge <- position_dodge(width = .38)
p_levels <- ggplot(
  levels,
  aes(Window, point, color = Day, shape = Day, group = Day)
) +
  geom_errorbar(
    aes(ymin = lower, ymax = upper),
    width = .12,
    position = dodge,
    linewidth = .55
  ) +
  geom_point(size = 2.4, position = dodge) +
  scale_color_manual(values = c(blue, orange)) +
  scale_shape_manual(values = c(16, 17)) +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    expand = expansion(mult = c(.015, .015))
  ) +
  labs(
    x = "Brown recommendation window",
    y = "Recommendation adherence (%)",
    caption = "Equal weight for nine sites. Bars are 95% confidence intervals."
  ) +
  base_theme
p_work <- ggplot(work, aes(point, Site)) +
  geom_vline(
    aes(xintercept = reference_pp),
    data = unique(work[, .(Window, reference_pp)]),
    color = blue,
    linetype = "longdash",
    linewidth = .55
  ) +
  geom_errorbar(
    aes(xmin = lower, xmax = upper),
    orientation = "y",
    width = .18,
    linewidth = .5,
    color = ink
  ) +
  geom_point(
    aes(shape = Mark, fill = Mark),
    color = ink,
    size = 2.5,
    stroke = .6
  ) +
  facet_wrap(vars(Window), ncol = 1, drop = FALSE) +
  scale_shape_manual(values = c(21, 23)) +
  scale_fill_manual(values = c("white", orange)) +
  scale_x_continuous(
    breaks = seq(0, 100, 20),
    limits = c(-2, 104),
    expand = expansion(mult = 0)
  ) +
  labs(
    x = "Work-day recommendation adherence (%)",
    y = NULL,
    caption = "Long-dashed blue line: equal-site Work-day mean.\nPoints show adherence levels; symbols refer to separate site-minus-mean tests."
  ) +
  base_theme
p_effects <- ggplot(effects, aes(point, Site)) +
  geom_vline(
    xintercept = 0,
    linetype = "dotted",
    color = ink,
    linewidth = .45
  ) +
  geom_vline(
    aes(xintercept = reference_pp),
    data = unique(effects[, .(Window, reference_pp)]),
    color = blue,
    linetype = "longdash",
    linewidth = .55
  ) +
  geom_errorbar(
    aes(xmin = lower, xmax = upper),
    orientation = "y",
    width = .18,
    linewidth = .5,
    color = ink
  ) +
  geom_point(
    aes(shape = Mark, fill = Mark),
    color = ink,
    size = 2.5,
    stroke = .6
  ) +
  geom_text(
    data = effects[fdr_significant == TRUE],
    aes(label = "*"),
    nudge_y = .25,
    color = "#111111",
    size = 4.3,
    show.legend = FALSE
  ) +
  facet_wrap(vars(Window), ncol = 1, drop = FALSE) +
  scale_shape_manual(values = c(21, 23)) +
  scale_fill_manual(values = c("white", orange)) +
  scale_x_continuous(breaks = seq(-30, 40, 10)) +
  labs(
    x = "Free day minus Work day (percentage points)",
    y = NULL,
    caption = "* Different from the equal-site Free-minus-Work effect (separate FDR family).\nDotted line: zero. Long-dashed blue line: equal-site effect."
  ) +
  base_theme
p_coverage <- ggplot(
  coverage,
  aes(point, Window, color = Sample, shape = Sample, group = Sample)
) +
  geom_vline(xintercept = 0, linetype = "dashed", color = ink, linewidth = .5) +
  geom_errorbar(
    aes(xmin = lower, xmax = upper),
    orientation = "y",
    width = .12,
    position = dodge,
    linewidth = .55
  ) +
  geom_point(size = 2.4, position = dodge) +
  scale_color_manual(values = c(blue, orange)) +
  scale_shape_manual(values = c(16, 17)) +
  scale_y_discrete(limits = rev(window_levels)) +
  scale_x_continuous(
    limits = c(-10, 15),
    breaks = c(-10, -5, 0, 5, 10, 15),
    expand = expansion(mult = c(.01, .01))
  ) +
  labs(
    x = "Free day minus Work day (percentage points)",
    y = NULL,
    caption = "Bars are 95% confidence intervals. The Pre-sleep coverage interval includes zero."
  ) +
  base_theme
plots <- list(
  main_adherence_levels = p_levels,
  main_site_workday = p_work,
  main_site_free_work = p_effects,
  main_coverage = p_coverage
)
sources <- list(
  main_adherence_levels = levels,
  main_site_workday = work,
  main_site_free_work = effects,
  main_coverage = coverage
)
heights <- c(100, 230, 230, 95)
checks <- data.table(
  check = c(
    "six_primary_levels",
    "27_workday_rows",
    "27_effect_rows",
    "six_coverage_rows",
    "full_site_key_set",
    "workday_markers",
    "zero_markers",
    "departure_markers",
    "all_source_CIs_finite",
    "all_current_main_samples"
  ),
  passed = c(
    nrow(levels) == 6L,
    nrow(work) == 27L,
    nrow(effects) == 27L,
    nrow(coverage) == 6L,
    identical(
      work[, paste(analysis_state, site)],
      effects[, paste(analysis_state, site)]
    ),
    identical(work$contrast_significant, work$contrast_p_adjusted < .05),
    identical(
      effects$Mark == "Different from zero",
      effects$p_adjusted_zero < .05
    ),
    identical(effects$fdr_significant, m6$fdr_significant),
    all(vapply(
      sources,
      function(d) all(is.finite(c(d$point, d$lower, d$upper))),
      logical(1)
    )),
    all(levels$sample_id == "primary_any_valid") &&
      all(work$sample_id == "primary_any_valid")
  )
)
stopifnot(all(checks$passed))

for (i in seq_along(plots)) {
  name <- names(plots)[i]
  lb_write_csv(sources[[i]], paste0("figures/", name, "_source.csv"))
  for (format in c("png", "svg")) {
    ggsave(file.path("results/images/brown", paste0(name, ".", format)), plots[[i]],
           width = 170, height = heights[i], units = "mm", dpi = 320, bg = "white")
  }
}
invisible(plots)
}
