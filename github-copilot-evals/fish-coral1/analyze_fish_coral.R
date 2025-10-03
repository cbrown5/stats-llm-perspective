#!/usr/bin/env Rscript

# Analysis: Negative binomial GLM of fish abundance (pres.topa) vs proportional coral cover (CB_cover / n_pts)

suppressPackageStartupMessages({
  if (!requireNamespace("MASS", quietly = TRUE)) install.packages("MASS", repos = "https://cloud.r-project.org")
  if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2", repos = "https://cloud.r-project.org")
})

library(MASS)
library(ggplot2)

# Read data
csv_file <- "fish-coral.csv"
if (!file.exists(csv_file)) stop("Data file not found: ", csv_file)
dat <- read.csv(csv_file, stringsAsFactors = FALSE)

# Create proportional coral cover
if (!all(c("CB_cover", "n_pts", "pres.topa") %in% names(dat))) stop("Required columns missing in data.")
dat$CB_cover_prop <- dat$CB_cover / dat$n_pts

# Fit negative binomial GLM
model <- glm.nb(pres.topa ~ CB_cover_prop, data = dat)

# Write model summary to file
res_file <- "glm_results.txt"
summary_out <- capture.output({
  cat("Negative Binomial GLM: pres.topa ~ CB_cover_prop\n\n")
  print(summary(model))
  cat("\nAIC:", AIC(model), "\n")
})
writeLines(summary_out, con = res_file)

# Diagnostics plots
png("diagnostic_plots.png", width = 1400, height = 900, res = 150)
par(mfrow = c(2,2))
# 1 Fitted vs Residuals
plot(fitted(model), resid(model, type = "pearson"),
     xlab = "Fitted values", ylab = "Pearson residuals", main = "Residuals vs Fitted")
abline(h = 0, col = "red", lty = 2)
# 2 QQ plot
qqnorm(resid(model, type = "pearson"), main = "QQ Plot (Pearson Residuals)")
qqline(resid(model, type = "pearson"), col = "red")
# 3 Scale-Location
sqrt_abs_res <- sqrt(abs(resid(model, type = "pearson")))
plot(fitted(model), sqrt_abs_res, xlab = "Fitted values", ylab = "Sqrt(|Pearson residuals|)", main = "Scale-Location")
# 4 Observed vs Fitted
plot(dat$pres.topa, fitted(model), xlab = "Observed pres.topa", ylab = "Fitted pres.topa", main = "Observed vs Fitted")
abline(0,1,col="blue", lty=2)
par(mfrow = c(1,1))
dev.off()

# Prediction over coral cover range
newdata <- data.frame(CB_cover_prop = seq(min(dat$CB_cover_prop), max(dat$CB_cover_prop), length.out = 200))
preds <- predict(model, newdata = newdata, type = "link", se.fit = TRUE)
newdata$fit_link <- preds$fit
newdata$se_link <- preds$se.fit
# Transform to response scale
newdata$fit <- exp(newdata$fit_link)
newdata$lwr <- exp(newdata$fit_link - 1.96 * newdata$se_link)
newdata$upr <- exp(newdata$fit_link + 1.96 * newdata$se_link)

p <- ggplot(dat, aes(x = CB_cover_prop, y = pres.topa)) +
  geom_point(alpha = 0.7) +
  geom_ribbon(data = newdata, aes(x = CB_cover_prop, ymin = lwr, ymax = upr), fill = "skyblue", alpha = 0.3, inherit.aes = FALSE) +
  geom_line(data = newdata, aes(x = CB_cover_prop, y = fit), color = "blue", size = 1) +
  labs(x = "Proportional coral cover", y = "Fish abundance (pres.topa)", title = "Predicted fish abundance vs coral cover") +
  theme_minimal()

ggsave("predicted_fish_abundance_vs_coral_cover.png", p, width = 7, height = 5, dpi = 150)

# Also save prediction data
write.csv(newdata, file = "predictions.csv", row.names = FALSE)

cat("Analysis complete. Outputs generated:\n",
    paste0(" - ", res_file, "\n"),
    " - diagnostic_plots.png\n",
    " - predicted_fish_abundance_vs_coral_cover.png\n",
    " - predictions.csv\n")
