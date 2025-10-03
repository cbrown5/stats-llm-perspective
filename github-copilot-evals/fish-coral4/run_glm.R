# R script to fit negative binomial GLM of fish abundance vs proportional coral cover
# Reads fish-coral.csv in working directory
# Outputs model summary to glm_results.txt and creates diagnostic and prediction plots.

# Load required package
suppressPackageStartupMessages({
  if(!require(MASS)) {
    stop('MASS package is required')
  }
})

# Read data
Dat <- read.csv('fish-coral.csv', stringsAsFactors = FALSE)

# Create proportional coral cover variable
Dat$coral_prop <- Dat$CB_cover / Dat$n_pts

# Fit negative binomial GLM
model <- tryCatch({
  MASS::glm.nb(pres.topa ~ coral_prop, data = Dat)
}, error = function(e){
  stop('Model fitting failed: ', e$message)
})

# Write summary to file
glm_sum <- summary(model)
cap <- capture.output({
  cat('Negative Binomial GLM: pres.topa ~ coral_prop\n')
  cat('\nModel call:\n')
  print(model$call)
  cat('\nSummary:\n')
  print(glm_sum)
  cat('\nTheta (NB dispersion parameter):', model$theta, ' Std.Err:', model$SE.theta, '\n')
  cat('\nAIC:', AIC(model), '\n')
  cat('\nLikelihood ratio test vs. null (intercept-only) model:\n')
  null_mod <- MASS::glm.nb(pres.topa ~ 1, data = Dat)
  lr_stat <- 2 * (logLik(model) - logLik(null_mod))
  p_val <- pchisq(lr_stat, df = attr(logLik(model), 'df') - attr(logLik(null_mod), 'df'), lower.tail = FALSE)
  cat('  LR stat =', as.numeric(lr_stat), ' df =', attr(logLik(model), 'df') - attr(logLik(null_mod), 'df'), ' p-value =', p_val, '\n')
})
writeLines(cap, 'glm_results.txt')

# Create diagnostic plots
png('diagnostic_plots.png', width = 1200, height = 800, res = 150)
par(mfrow = c(2,2))
# Fitted vs observed
plot(fitted(model), Dat$pres.topa, pch=19, col='steelblue',
     xlab='Fitted values', ylab='Observed pres.topa', main='Observed vs Fitted')
abline(0,1,lty=2,col='red')
# Residuals vs fitted
plot(fitted(model), residuals(model, type='pearson'), pch=19, col='darkorange',
     xlab='Fitted values', ylab='Pearson residuals', main='Residuals vs Fitted')
abline(h=0,lty=2)
# QQ plot of residuals
res <- residuals(model, type='pearson')
qqnorm(res, main='QQ Plot (Pearson residuals)', pch=19, col='purple')
qqline(res, col='red')
# Histogram of residuals
hist(res, breaks=10, col='gray', border='white', main='Histogram Residuals', xlab='Pearson residual')
par(mfrow=c(1,1))
dev.off()

# Prediction across range of coral_prop
newdat <- data.frame(coral_prop = seq(min(Dat$coral_prop, na.rm=TRUE), max(Dat$coral_prop, na.rm=TRUE), length.out=200))
newdat$pred <- predict(model, newdata=newdat, type='response')
# 95% CI using standard errors on link scale
pred_link <- predict(model, newdata=newdat, type='link', se.fit=TRUE)
newdat$pred_lwr <- NA  # placeholder removed; will fill after CI computation
# Replace with calculated CIs
crit <- qnorm(0.975)
link_lwr <- pred_link$fit - crit * pred_link$se.fit
link_upr <- pred_link$fit + crit * pred_link$se.fit
newdat$pred_lwr <- model$family$linkinv(link_lwr)
newdat$pred_upr <- model$family$linkinv(link_upr)

# Save predictions
write.csv(newdat, 'predicted_abundance.csv', row.names = FALSE)

# Plot predictions with data
png('prediction_plot.png', width=1000, height=800, res=150)
plot(Dat$coral_prop, Dat$pres.topa, pch=19, col='grey40',
     xlab='Proportional coral cover', ylab='Fish abundance (pres.topa)',
     main='Negative Binomial GLM: Fish abundance vs Coral cover')
lines(newdat$coral_prop, newdat$pred, col='blue', lwd=2)
lines(newdat$coral_prop, newdat$pred_lwr, col='blue', lwd=1, lty=2)
lines(newdat$coral_prop, newdat$pred_upr, col='blue', lwd=1, lty=2)
legend('topleft', legend=c('Observed','Predicted','95% CI'),
       col=c('grey40','blue','blue'), pch=c(19,NA,NA), lty=c(NA,1,2), bty='n')
dev.off()

message('Analysis complete. Outputs: glm_results.txt, diagnostic_plots.png, prediction_plot.png, predicted_abundance.csv')
