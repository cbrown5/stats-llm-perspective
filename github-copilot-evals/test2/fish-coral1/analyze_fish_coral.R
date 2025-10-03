# Analysis of dependence of fish abundance (pres.topa) on coral cover (CB_cover)
# Reads fish-coral.csv in same directory, fits alternative count models and saves outputs.

required_packages <- c("MASS", "pscl", "ggplot2", "dplyr", "broom")
for(p in required_packages){
  if(!requireNamespace(p, quietly = TRUE)){
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages({
  library(MASS)
  library(pscl)
  library(ggplot2)
  library(dplyr)
  library(broom)
})

# Read data
 dat <- read.csv("fish-coral.csv")

# Basic cleaning / feature engineering
 dat <- dat %>%
   mutate(coral_prop = CB_cover / n_pts,
          logging = factor(logged),
          flow = factor(flow),
          pres.topa = as.integer(pres.topa))

# Exploratory summaries
summary_stats <- dat %>% summarise(
  n = n(),
  zero_count = sum(pres.topa == 0),
  zero_prop = mean(pres.topa == 0),
  mean_count = mean(pres.topa),
  var_count = var(pres.topa),
  min_coral = min(CB_cover),
  max_coral = max(CB_cover),
  mean_coral = mean(CB_cover)
)
write.table(summary_stats, file = "exploratory_summary.txt", row.names = FALSE, sep = "\t")

# Univariate models of pres.topa ~ coral_prop (main question)
# Poisson GLM
pois_mod <- glm(pres.topa ~ coral_prop, family = poisson, data = dat)

overdispersion <- sum(residuals(pois_mod, type = "pearson")^2) / pois_mod$df.residual

# Negative binomial
nb_mod <- tryCatch(glm.nb(pres.topa ~ coral_prop, data = dat), error = function(e) NULL)

# Zero-inflated Poisson and NB (if possible)
zip_mod <- tryCatch(zeroinfl(pres.topa ~ coral_prop | 1, data = dat, dist = "poisson"), error = function(e) NULL)
zinb_mod <- tryCatch(zeroinfl(pres.topa ~ coral_prop | 1, data = dat, dist = "negbin"), error = function(e) NULL)

# Collect AICs
model_list <- list(Poisson = pois_mod, NegBin = nb_mod, ZIP = zip_mod, ZINB = zinb_mod)
model_aic <- lapply(model_list, function(m) if(is.null(m)) NA else AIC(m))
model_df <- data.frame(model = names(model_aic), AIC = unlist(model_aic)) %>% arrange(AIC)
write.table(model_df, file = "model_selection.txt", row.names = FALSE, sep = "\t")

# Save detailed summaries
capture.output(summary(pois_mod), file = "poisson_model_summary.txt")
if(!is.null(nb_mod)) capture.output(summary(nb_mod), file = "nb_model_summary.txt")
if(!is.null(zip_mod)) capture.output(summary(zip_mod), file = "zip_model_summary.txt")
if(!is.null(zinb_mod)) capture.output(summary(zinb_mod), file = "zinb_model_summary.txt")

# Choose best model (lowest AIC)
best_name <- model_df$model[which.min(model_df$AIC)]
best_model <- model_list[[best_name]]

# Effect size extraction (exponentiated coefficient for coral_prop)
coef_df <- tidy(best_model) %>% filter(term == "coral_prop")
if(grepl("zero", best_name, ignore.case = TRUE)){
  # zeroinfl has two sets of coefficients; tidy() includes both. Filter incorrectly maybe.
  # Provide both count and zero components
  coef_df <- tidy(best_model) %>% filter(grepl("coral_prop", term))
}

# For count component, compute incidence rate ratio (IRR)
coef_df <- coef_df %>% mutate(IRR = exp(estimate))
write.table(coef_df, file = "best_model_effects.txt", row.names = FALSE, sep = "\t")

# Generate prediction grid over coral_prop
newdat <- data.frame(coral_prop = seq(min(dat$coral_prop), max(dat$coral_prop), length.out = 100))

predict_counts <- function(model, newdata){
  if("zeroinfl" %in% class(model)){
    # Expected value for zero-inflated: (1 - pi) * mu
    # predict(..., type="link") not directly helpful, use predict(type="response")
    preds <- predict(model, newdata, type = "response")
    return(preds)
  } else {
    preds <- predict(model, newdata, type = "response")
    return(preds)
  }
}

newdat$pred_mean <- predict_counts(best_model, newdat)

# Approximate confidence intervals via simulation
set.seed(123)
B <- 1000
if(!("zeroinfl" %in% class(best_model))){
  # Use MVN approximation
  V <- vcov(best_model)
  beta <- coef(best_model)
  sim_beta <- MASS::mvrnorm(B, beta, V)
  X <- model.matrix(~ coral_prop, data = newdat)
  linpred <- sim_beta %*% t(X)
  if(best_name %in% c("Poisson", "NegBin")){
    sim_mu <- exp(linpred)
  } else {
    sim_mu <- exp(linpred) # fallback
  }
  newdat$lower <- apply(sim_mu, 2, quantile, 0.025)
  newdat$upper <- apply(sim_mu, 2, quantile, 0.975)
} else {
  # For zeroinfl, do parametric bootstrap of coefficients (approx)
  cf <- coef(best_model)
  V <- vcov(best_model)
  sim_beta <- MASS::mvrnorm(B, cf, V)
  # separate components
  terms_all <- names(cf)
  count_terms <- grep('^count_', terms_all, value = TRUE)
  zero_terms  <- grep('^zero_', terms_all, value = TRUE)
  Xc <- model.matrix(~ coral_prop, data = newdat)
  Xz <- model.matrix(~ 1, data = newdat) # intercept only zero component
  # Map columns
  idx_count <- match(count_terms, terms_all)
  idx_zero  <- match(zero_terms, terms_all)
  lin_count <- sim_beta[, idx_count] %*% t(Xc)
  lin_zero  <- sim_beta[, idx_zero, drop=FALSE] %*% t(Xz)
  mu <- exp(lin_count)
  pi0 <- plogis(lin_zero) # probability of extra zero
  sim_mu <- (1 - pi0) * mu
  newdat$lower <- apply(sim_mu, 2, quantile, 0.025)
  newdat$upper <- apply(sim_mu, 2, quantile, 0.975)
}

write.table(newdat, file = "predictions.csv", row.names = FALSE, sep = ",")

# Plot raw data and fitted relationship
p <- ggplot(dat, aes(x = coral_prop)) +
  geom_jitter(aes(y = pres.topa), width = 0.002, height = 0.2, alpha = 0.6) +
  geom_ribbon(data = newdat, aes(x = coral_prop, ymin = lower, ymax = upper), alpha = 0.2, fill = "steelblue", inherit.aes = FALSE) +
  geom_line(data = newdat, aes(x = coral_prop, y = pred_mean), color = "steelblue", linewidth = 1, inherit.aes = FALSE) +
  labs(x = "Coral cover (proportion)", y = "Fish abundance (pres.topa)",
       title = paste0("Fish abundance vs coral cover (best model: ", best_name, ")")) +
  theme_minimal()

ggsave("fish_coral_relationship.png", p, width = 7, height = 5, dpi = 300)

# Provide an interpretation file
interpretation <- c(
  paste0("Overdispersion factor (Poisson) = ", round(overdispersion, 2)),
  paste0("Best model selected by AIC: ", best_name),
  "Effect size (see best_model_effects.txt): IRR is multiplicative change in mean abundance per unit increase in coral proportion.",
  "Prediction interval (95% CI) saved in predictions.csv.",
  "Plot saved as fish_coral_relationship.png."
)
writeLines(interpretation, con = "interpretation.txt")

message("Analysis complete. Files written:")
print(list.files(pattern = "^(exploratory|model|poisson|nb_|zip_|zinb_|best_model|predictions|fish_coral_relationship|interpretation).*"))
