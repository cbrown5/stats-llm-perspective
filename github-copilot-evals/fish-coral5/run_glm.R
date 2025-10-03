# Negative binomial GLM of fish abundance (pres.topa) vs proportional coral cover (CB_cover / n_pts)
# Reads fish-coral.csv in working directory, fits model, writes results and plots.

# Load required package
suppressPackageStartupMessages({
  if (!requireNamespace("MASS", quietly = TRUE)) {
    stop("Package MASS is required but not installed.")
  }
})

# Read data
fname <- "fish-coral.csv"
if (!file.exists(fname)) stop("Data file not found: ", fname)

dat <- read.csv(fname, stringsAsFactors = FALSE)

# Create proportional coral cover
if (!all(c("CB_cover", "n_pts", "pres.topa") %in% names(dat))) {
  stop("Required columns missing in data.")
}

# Guard against division by zero
if (any(dat$n_pts <= 0, na.rm = TRUE)) stop("n_pts contains non-positive values.")

dat$coral_prop <- dat$CB_cover / dat$n_pts

# Fit negative binomial GLM
library(MASS)
model <- glm.nb(pres.topa ~ coral_prop, data = dat)

# Write model summary to file
sink("glm_results.txt")
cat("Negative binomial GLM of pres.topa ~ coral_prop\n\n")
print(summary(model))
cat("\nModel theta (dispersion):", model$theta, " SE(theta):", model$SE.theta, "\n")
# Pseudo R^2 (McFadden)
ll_full <- as.numeric(logLik(model))
ll_null <- as.numeric(logLik(update(model, . ~ 1)))
mcFadden <- 1 - (ll_full/ll_null)
cat("McFadden pseudo R^2:", round(mcFadden, 4), "\n")
sink()

# Diagnostic plots
png("diagnostic_plots.png", width = 1000, height = 500)
par(mfrow = c(1,2))
# Residuals vs fitted
dev_res <- residuals(model, type = "deviance")
fit <- fitted(model)
plot(fit, dev_res, pch = 19, col = "steelblue", xlab = "Fitted values", ylab = "Deviance residuals",
     main = "Residuals vs Fitted")
abline(h = 0, lty = 2, col = "red")
# QQ plot of deviance residuals
qqnorm(dev_res, pch = 19, col = "steelblue", main = "QQ Plot Deviance Residuals")
qqline(dev_res, col = "red", lwd = 2)
dev.off()

# Prediction over range of coral cover
newdat <- data.frame(coral_prop = seq(min(dat$coral_prop, na.rm = TRUE),
                                      max(dat$coral_prop, na.rm = TRUE), length.out = 200))

pred_link <- predict(model, newdata = newdat, type = "link", se.fit = TRUE)
newdat$fit <- exp(pred_link$fit)
newdat$lower <- exp(pred_link$fit - 1.96 * pred_link$se.fit)
newdat$upper <- exp(pred_link$fit + 1.96 * pred_link$se.fit)

# Plot observed vs predicted
png("predicted_abundance.png", width = 800, height = 600)
plot(dat$coral_prop, dat$pres.topa, pch = 19, col = rgb(0,0,0,0.5),
     xlab = "Proportional coral cover", ylab = "Fish abundance (pres.topa)",
     main = "Observed and Predicted Fish Abundance vs Coral Cover")
lines(newdat$coral_prop, newdat$fit, col = "blue", lwd = 2)
lines(newdat$coral_prop, newdat$lower, col = "blue", lwd = 1, lty = 2)
lines(newdat$coral_prop, newdat$upper, col = "blue", lwd = 1, lty = 2)
legend("topright", legend = c("Observed", "Predicted", "95% CI"),
       col = c(rgb(0,0,0,0.5), "blue", "blue"), pch = c(19, NA, NA),
       lwd = c(NA, 2, 1), lty = c(NA,1,2), bty = "n")
dev.off()

message("Analysis complete. Files written: glm_results.txt, diagnostic_plots.png, predicted_abundance.png")
