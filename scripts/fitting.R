make_formula <- function(response, rhs) {
  as.formula(paste(response, rhs))
}

fit_model <- function(data, formula, engine, family) {
  switch(engine,
         "lm" = lm(formula, data = data),
         "glm" = glm(formula, data = data, family = family),
         "lmer" = lmer(formula, data = data),
         "glmer" = glmer(formula, data = data, family = family)
         )
}