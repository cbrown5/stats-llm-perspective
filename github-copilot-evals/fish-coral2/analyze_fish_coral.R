# Analysis of fish abundance vs coral cover using Negative Binomial GLM
# Reads fish-coral.csv, computes proportional coral cover, fits model, saves outputs.

suppressPackageStartupMessages({
  if (!requireNamespace("MASS", quietly = TRUE)) {
    stop("Package 'MASS' required but not installed.")
  }
})

library(MASS)

# Input / output paths
input_file <- "fish-coral.csv"
results_file <- "glm_results.txt"
plot_diagnostic_file <- "diagnostic_plots.png"
plot_prediction_file <- "predicted_abundance_vs_coral.png"

# Load data
Dat <- read.csv(input_file, stringsAsFactors = FALSE)

# Defensive checks
if (!all(c("pres.topa", "CB_cover", "n_pts") %in% names(Dat))) {
  stop("Required columns not found in data file.")
}

# Proportional coral cover
Dat$prop_coral <- Dat$CB_cover / Dat$n_pts

# Fit Negative Binomial GLM
m1 <- glm.nb(pres.topa ~ prop_coral, data = Dat)

# Save model summary
sink(results_file)
cat("Negative Binomial GLM: pres.topa ~ prop_coral\n\n")
print(summary(m1))
cat("\nAIC:", AIC(m1), "\n")
# Overdispersion check (ratio residual deviance / df)
overdispersion <- m1$deviance / m1$df.residual
cat("Overdispersion ratio (deviance/df):", round(overdispersion, 3), "\n")

# Likelihood ratio test vs null model
m0 <- update(m1, . ~ 1)
cat("\nLikelihood ratio test (vs null):\n")
print(anova(m0, m1, test = "Chisq"))

sink()

# Diagnostic plots
png(plot_diagnostic_file, width = 1600, height = 800, res = 150)
par(mfrow = c(1,3))
# 1. Residuals vs Fitted
plot(fitted(m1), resid(m1, type = "pearson"),
     xlab = "Fitted values", ylab = "Pearson residuals",
     main = "Residuals vs Fitted")
abline(h = 0, col = "red", lty = 2)
# 2. QQ plot of residuals
res <- resid(m1, type = "pearson")
qqnorm(res, main = "QQ Plot (Pearson Residuals)")
qqline(res, col = "red")
# 3. Cook's distance
plot(cooks.distance(m1), type = "h", main = "Cook's Distance", ylab = "Cook's D")
abline(h = 4/length(res), col = "red", lty = 2)
par(mfrow = c(1,1))
dev.off()

# Prediction grid across observed range
newdat <- data.frame(prop_coral = seq(min(Dat$prop_coral, na.rm = TRUE),
                                      max(Dat$prop_coral, na.rm = TRUE), length.out = 100))
pr <- predict(m1, newdata = newdat, type = "link", se.fit = TRUE)
newdat$fit <- exp(pr$fit)
newdat$lcl <- exp(pr$fit - 1.96 * pr$se.fit)
newdat$ucl <- exp(pr$fit + 1.96 * pr$se.fit)

# Plot predicted abundance
png(plot_prediction_file, width = 1200, height = 900, res = 150)
plot(pres.topa ~ prop_coral, data = Dat, pch = 19, col = "grey40",
     xlab = "Proportional coral cover", ylab = "Fish abundance (pres.topa)",
     main = "Predicted fish abundance vs coral cover")
lines(newdat$prop_coral, newdat$fit, col = "blue", lwd = 2)
lines(newdat$prop_coral, newdat$lcl, col = "blue", lty = 2)
lines(newdat$prop_coral, newdat$ucl, col = "blue", lty = 2)
legend("topright", legend = c("Observed", "Predicted", "95% CI"),
       col = c("grey40", "blue", "blue"), pch = c(19, NA, NA),
       lty = c(NA, 1, 2), bty = "n")
dev.off()

message("Analysis complete. Outputs written:")
message(" - ", results_file)
message(" - ", plot_diagnostic_file)
message(" - ", plot_prediction_file)
