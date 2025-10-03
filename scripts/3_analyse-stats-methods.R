library(tidyverse)

# Read data (expects outputs/model_prompt_comparison.csv to exist)
dat <- readr::read_csv("outputs/model_prompt_comparison.csv")

# Keywords / regex categories to search for in the `Response` field.
# We normalize case before matching and include alternative phrasings.
# The classification below assigns a single test-type to each response using
# a precedence order (specialised models first -> general tests last).

# Helper: safe lower-case string (handles NA)
safe_lower <- function(x) {
	x <- as.character(x)
	x[is.na(x)] <- ""
	tolower(x)
}

# Ensure key fields are in expected types (CSV columns are lowercase: model,prompt,response,rep,expert)
dat <- dat %>%
	mutate(
		response_lc = safe_lower(response),
		rep = as.numeric(rep),
		rep = ifelse(is.na(rep), 1, rep),
		expert = case_when(
			tolower(as.character(expert)) %in% c("true","t","1") ~ TRUE,
			tolower(as.character(expert)) %in% c("false","f","0") ~ FALSE,
			TRUE ~ as.logical(expert)
		),
		# keep the Expert-suffixed label for display, and preserve the base prompt factor for colouring/order
		Prompt2 = paste0(prompt, if_else(expert, " (Expert)", " (Not expert)"))
	)

dat$PromptBase <- factor(dat$Prompt2, labels = c("Non-specific", "Specific 1", "Specific 2", "Detailed expert", "Detailed"))
dat$PromptBase <- factor(dat$PromptBase, levels = c("Non-specific", "Specific 1", "Specific 2", "Detailed", "Detailed expert"))

# --- NEW: multi-label detection patterns and mention columns ---
# Define regex patterns matching the earlier classify_response rules, in same order as test_levels
patterns <- c(
		"auto[- ]?correl|autocorrel|durbin[- ]?watson",
		"mixed[- ]?effect|mixed effects|random[- ]?effect|multilevel|hierarchical|lme|lmer|mixed model",
	"zero[- ]?inflat|zero inflat|zero[- ]?inflation|hurdle|zinb",
	"negative[- ]?binom|neg[- ]?binom|nbinom|negative binomial",
	"poisson( regression)?\\b|poisson glm|poisson model",
	"\\bgam\\b|generalized additive model|generalised additive model|additive model",
	"\\bglm\\b|generalized linear model|generalised linear model|logistic regression|binomial regression|quasi-",
	"linear regression|regression(?!.*glm)|\\blm\\b|ordinary least squares|ols\\b",
	"anova|analysis of variance|\\bkruskal|friedman test|repeated measures anova",
	"t[- ]?test|ttest|paired t|welch",
	"correlat|pearson|spearman|kendall|\\bcor\\b",
	""  # placeholder for "Other / Unspecified" handled below
)

# Define test levels in same order as patterns
test_levels <- c(
	"Autocorrelation",
	"Mixed effects model",
	"Zero-inflated model",
	"Negative binomial",
	"Poisson model",
	"Generalized additive model",
	"Generalized linear model",
	"Linear regression",
	"ANOVA / Kruskal-Wallis",
	"T-test",
	"Correlation",
	"Other / Unspecified"
)

# helper to make safe column names for each test level
sanitize <- function(x) {
  x <- make.names(x)            # converts to syntactically valid names
  x <- gsub("\\.+", "_", x)    # collapse dots to underscores for readability
  x
}
mention_cols <- sanitize(test_levels)

# add mention columns (0/1) to dat based on the patterns; Other/Unspecified set if no other pattern matched
for (i in seq_along(test_levels)) {
  col <- mention_cols[i]
  if (i < length(test_levels)) {
    pat <- patterns[i]
    dat[[col]] <- as.integer(str_detect(dat$response_lc, regex(pat, ignore_case = TRUE)))
  } else {
    # Other: set to 1 only when none of the previous mention cols matched
    prev_cols <- mention_cols[1:(length(mention_cols)-1)]
    dat[[col]] <- as.integer(rowSums(as.data.frame(dat[prev_cols])) == 0)
  }
}

# Summarise counts by Model, Prompt2 and TestType summing Rep as requested
# Convert mention columns to long form so each mention is counted (rep * mention_flag)
summary_df <- dat %>%
	select(-response, - response_lc) %>% 
	pivot_longer(cols = all_of(mention_cols), names_to = "MentionCol", values_to = "MentionFlag") %>%
	# filter(model == "anthropic/claude-sonnet-4.5" & Prompt2 == "prompt1 (Not expert)") 
	group_by(model, PromptBase, MentionCol) %>%
	summarise(Count = sum(MentionFlag, na.rm = TRUE), .groups = "drop") %>%
	# Ensure x-axis uses test_levels labels and preserves their order
	mutate(MentionCol = factor(MentionCol, levels = mention_cols, labels = test_levels))

# define a light->dark blue palette with same order as levels(dat$prompt2)
palette_base <- colorRampPalette(c("#dbeeff", "#08306b"))(nlevels(dat$PromptBase))
names(palette_base) <- levels(dat$PromptBase)

# Plot: one panel per Model, x = TestType, y = Count, color by PromptBase (ordered as in line 18)
plot_file <- "outputs/test_type_barchart.png"

g <- ggplot(summary_df, aes(x = MentionCol, y = Count, fill = PromptBase)) +
	geom_col(position = position_dodge2(preserve = "single"), colour = "black", width = 0.7) +
	facet_wrap(~model, ncol = 1, scales = "free_y") +
	scale_fill_manual(values = palette_base, breaks = levels(dat$PromptBase), name = "Prompt (base)") +
	labs(x = "Test / Model type", y = "Count (sum of Rep)", fill = "Prompt") +
	theme_classic() +
	theme(
		axis.text.x = element_text(angle = 45, hjust = 1),
		strip.text = element_text(face = "bold")
	)
g
# Save plot
ggsave(plot_file, g, width = 9, height = 12, dpi = 300)


# count rows that mention at least one of Zero-inflated / Poisson / Negative binomial ---

  # pick the sanitized column names for the three tests
  target_tests <- c("Zero-inflated model", "Negative binomial", "Poisson model")
  target_cols <- mention_cols[which(test_levels %in% target_tests)]

  # create per-row indicator (respecting rep as weight)
  dat <- dat %>%
    mutate(any_zpn = as.integer(rowSums(across(all_of(target_cols)))>0))

  # summarise: for each model × PromptBase count how many (weighted by rep) had at least one mention
  summary_zpn <- dat %>%
    group_by(model, PromptBase) %>%
    summarise(Count = sum(any_zpn, na.rm = TRUE), .groups = "drop") %>%
    # ensure prompt order preserved
    mutate(PromptBase = factor(PromptBase, levels = levels(dat$PromptBase)))

  # Plot: prompts on x-axis, models as discrete colours
  plot_file2 <- "outputs/zero_poisson_nbinom_by_prompt.png"

library(RColorBrewer)
model_levels <- unique(summary_zpn$model)
palette_models <- brewer.pal(max(3, length(model_levels)), "Dark2")[seq_along(model_levels)]
names(palette_models) <- model_levels

g2 <- summary_zpn %>% 
filter(PromptBase != "Detailed expert") %>%
ggplot(aes(x = PromptBase, y = 10)) +
	geom_col(aes(y = Count, fill = model), colour = "black", width = 0.7, position = position_dodge2(preserve = "single")) +
	scale_fill_manual(values = palette_models, name = "Model") +
	labs(x = "Prompt", y = "Count (mentions of Zero inf./\n Poisson/NBinom)", fill = "Model") +
	scale_y_continuous(breaks = c(0, 5, 10)) +
	theme_classic() +
	theme(axis.text.x = element_text(angle = 45, hjust = 1), strip.text = element_text(face = "bold"))

g2

ggsave(plot_file2, g2, width = 8, height = 4, dpi = 300)

