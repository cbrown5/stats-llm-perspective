# Evaluate LLM outputs in a simple, loop-based workflow

library(tidyverse)
library(rlang)
library(patchwork)

# Load verified matrix
verified_path <- "scripts/coding-evals/outputs/verified_bray_distance.csv"
verified <- readr::read_csv(verified_path, show_col_types = FALSE)
verified_mat <- verified %>% column_to_rownames("site") %>% as.matrix()

# Backups to evaluate
backup_dir <- "scripts/coding-evals/outputs/reps-backups"
files <- list.files(backup_dir, pattern = "\\.rds$", full.names = TRUE)

rows <- list()

for (f in files) {
    # f <- files[1]
  resp <- readRDS(f)
  txt <- if (is.character(resp)) paste(resp, collapse = "\n") else as.character(resp)

  # Extract code between <code>...</code> if present, otherwise use whole text
  m <- regexpr("<code>([[:space:][:print:]]*?)</code>", txt, perl = TRUE)
  code <- if (m[1] != -1) gsub("^<code>|</code>$", "", regmatches(txt, m)) else txt

# Save code to an md, turning newlines into returns
    # md_filename <- file.path(backup_dir, paste0(tools::file_path_sans_ext(basename(f)), ".md"))
    # md_text <- gsub("\n", "\r\n", code)
    # writeLines(md_text, md_filename)    

  ran <- FALSE
  csv_path <- NA_character_
  cor_val <- NA_real_
  outcome <- "R error"

  # Evaluate code in a clean environment
  tryCatch({
    env <- rlang::env(parent = baseenv())
    eval(parse(text = code), envir = env)
    ran <- TRUE
  }, error = function(e) {})

  # Find a CSV output in a simple way
  expected <- c(
    "scripts/coding-evals/outputs/llm_distance.csv",
    "scripts/coding-evals/outputs/llm_distance_matrix.csv",
    "scripts/coding-evals/outputs/distance_matrix.csv",
    "scripts/coding-evals/outputs/bray_distance.csv"
  )
  existing <- expected[file.exists(expected)]
  if (length(existing) > 0) {
    csv_path <- existing[1]
  } 

  # Compare candidate CSV to verified
  if (ran && !is.na(csv_path) && file.exists(csv_path)) {
    cand <- tryCatch(readr::read_csv(csv_path, show_col_types = FALSE), error = function(e) NULL)
    
    if (!is.null(cand) && "site" %in% names(cand) && all(dim(cand) == c(49, 50))) {
      cand_mat <- cand %>% column_to_rownames("site") %>% as.matrix()
      if (!is.numeric(cand_mat)) cand_mat <- suppressWarnings(apply(cand_mat, 2, as.numeric)) %>% as.matrix()

      common <- match(rownames(verified_mat), rownames(cand_mat))
      if (length(common) >= 2) {
        v <- verified_mat[common, common, drop = FALSE]
        cmat <- cand_mat[common, common, drop = FALSE]
        
        # Calculate proportion of values within 1% error tolerance
        abs_diff <- abs(as.numeric(cmat) - as.numeric(v))
        tol <- 0.01 * abs(as.numeric(v))
        correct <- abs_diff <= tol
        cor_val <- mean(correct, na.rm = TRUE)
        
        outcome <- if (is.finite(cor_val) && cor_val >= 0.98){"Accurate result"} else {"Inaccurate result"}
      } else {
        outcome <- "CSV faulty"
      }
    } else {
      outcome <- "CSV faulty"
    }
  } else if (ran) {
    outcome <- "CSV faulty"
  }

  fname <- basename(f)
  Model <- sub("_.*$", "", tools::file_path_sans_ext(fname))
  Prompt <- if (grepl("detailed", fname, ignore.case = TRUE)) "Detailed" else if (grepl("vague", fname, ignore.case = TRUE)) "Vague" else "unknown"

  rows[[length(rows) + 1]] <- tibble(
    file = f,
    Model = Model,
    Prompt = Prompt,
    outcome = outcome,
    cor = cor_val,
    candidate_csv = csv_path
  ) 
    #Delete existing so it doesn't get re-used for the wrong rep
    if (file.exists(csv_path)) {
      file.remove(csv_path)}
}

# Per-file results for interactive exploration
results <- dplyr::bind_rows(rows)

# Compact summary for plotting
summary <- results %>%
  group_by(Model, Prompt, outcome) %>%
  summarise(Count = n(), .groups = "drop") %>%
  complete(Model, Prompt, outcome, fill = list(Count = 0)) %>%
  arrange(Model, Prompt, outcome)

# Plot outcomes as a bar chart
plt <- summary %>%
  ggplot(aes(x = outcome, y = Count, fill = Prompt)) +
  geom_col(position = position_dodge(width = 0.8)) +
  facet_wrap(~ Model) +
  labs(x = "Outcome", y = "Count") +
  theme_classic(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Plot proportion of accurate results
plt2 <- summary %>%
  group_by(Model, Prompt) %>%
  mutate(Total = sum(Count)) %>%
  ungroup() %>%
  filter(outcome == "Accurate result") %>%
  mutate(Prop = ifelse(Total > 0, Count / Total, 0)) %>%
  ggplot(aes(x = Prompt, y = Prop, fill = Prompt)) +
  geom_col() +
  facet_wrap(~ Model) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(x = "Prompt", y = "Correct results (%)", fill = "Prompt") +
  theme_classic(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

plotall <- plt2 + plt + plot_layout(ncol = 2, guides = "collect") +
  plot_annotation(tag_levels = 'a', tag_suffix = ")", tag_prefix = "(")

# Display plots and save
plotall

ggsave(plotall, filename = "outputs/llm_eval_barchart.png", width = 8, height = 4, dpi = 600)
