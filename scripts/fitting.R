make_formula <- function(response, rhs) {
  if(is.na(rhs) | is.na(response)) return()
  as.formula(paste(response, rhs))
}

fit_model <- function(data, formula, engine, family) {
  if(is.null(formula)) return()
  switch(engine,
         "lm" = lm(formula, data = data),
         "glm" = glm(formula, data = data, family = family),
         "lmer" = lmer(formula, data = data),
         "glmer" = glmer(formula, data = data, family = family),
         "glmmTMB" = glmmTMB(formula, data = data, family = family)
         )
}

model_helper <- function(row, hypothesis = "H1", metrics) {
  hypothesis <- 
  if(hypothesis == "H1") "H1_formula" else "H1_formula0"
  fit_model(
  metrics$data[[row]], metrics[[hypothesis]][[row]], metrics$engine[[row]], metrics$family[[row]]
  )
}

diagnostics <- function(model) {
  if(is.null(model)) return()
  performance::check_model(model)
}

model_anova <- function(model1, model2) {
  if(any(is.null(model1), is.null(model2))) return()
  anova(model1, model2)
}

model_AIC <- function(...){
  dots <- rlang::list2(...)
  dot_names <- c("H1_0", "H1_1", "H1_phot", "H1_lat", "H1_rand")[!sapply(dots, is.null)]
  dots <- dots[!sapply(dots, is.null)]
  if(length(dots) == 0) return()
  AICs <- rlang::inject(AIC(!!!dots))
  row.names(AICs) <- dot_names
  AICs |> rownames_to_column("model")
}

model_comp_p <- function(comp, engine, n){
  if(is.null(comp)) return(NA_real_)
  p.value <- 
    if(engine %in% c("lm", "glm")) {
     comp$`Pr(>F)`[2]
   } else
     comp$`Pr(>Chisq)`[2]
  p.value |> 
    p.adjust(method = "fdr", n = n)
}

model_VarCorr <- function(model) {
  if(is.null(model)) return()
  VarCorr(model)
}

AIC_dif <- function(AICs, model1, model2){
  AICs$AIC[AICs$model == model1] - AICs$AIC[AICs$model == model2]
}

