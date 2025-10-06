# Evaluate LLM outputs: parse code, execute, collect CSV, compare to verified, classify outcomes, and plot

library(tidyverse)
library(rlang)

# Helper to extract R code between <code>...</code> tags
extract_code <- function(txt) {
  if (is.character(txt)) {
    s <- paste(txt, collapse = "\n")
  } else {
    s <- as.character(txt)
  }
  m <- regexpr("<code>([[:space:][:print:]]*?)</code>", s, perl = TRUE)
  if (m[1] == -1) return(NA_character_)
  code <- regmatches(s, m)
  # remove tags
  code <- gsub("^<code>|</code>$", "", code)
  code
}

# Load verified matrix
verified_path <- "scripts/coding-evals/outputs/verified_bray_distance.csv"

verified <- readr::read_csv(verified_path, show_col_types = FALSE)
verified_mat <- verified %>% column_to_rownames("site") %>% as.matrix()

# Where to look for backups
backup_dir <- "scripts/coding-evals/outputs/reps-backups"
files <- list.files(backup_dir, pattern = "\\.rds$", full.names = TRUE)

# Attempt to run code and capture generated CSV path
safe_eval <- function(code_str) {
  # Prepare a clean env, and ensure outputs dir exists
  env <- rlang::env(parent = baseenv())

  # After execution, look for expected CSVs
  expected <- c(
    "scripts/coding-evals/outputs/llm_distance.csv",
    "scripts/coding-evals/outputs/llm_distance_matrix.csv",
    "scripts/coding-evals/outputs/distance_matrix.csv",
    "scripts/coding-evals/outputs/bray_distance.csv"
  )

  out <- list(ran = FALSE, error = NULL, found_csv = FALSE, csv = NULL)
  tryCatch({
    eval(parse(text = code_str), envir = env)
    out$ran <- TRUE
    # Check for expected files in priority order
    existing <- expected[file.exists(expected)]
    if (length(existing) > 0) {
      out$found_csv <- TRUE
      out$csv <- existing[[1]]
    } else {
      # also scan outputs/ for any csv created recently
      csvs <- list.files("outputs", pattern = "\\.csv$", full.names = TRUE)
      if (length(csvs) > 0) {
        # pick the most recently modified
        mt <- file.info(csvs)$mtime
        pick <- csvs[order(mt, decreasing = TRUE)][1]
        out$found_csv <- TRUE
        out$csv <- pick
      }
    }
    out
  }, error = function(e) {
    out$error <- conditionMessage(e)
    out
  })
}

compare_matrices <- function(candidate_path, verified_mat) {
  # Try to read and align shapes
  cand <- tryCatch(readr::read_csv(candidate_path, show_col_types = FALSE), error = function(e) NULL)
  if (is.null(cand)) return(list(status = "csv faulty", cor = NA_real_))

  # require a 'site' column
  if (!"site" %in% names(cand)) {
    # maybe rownames were written without a column; attempt to fabricate index alignment
    return(list(status = "csv faulty", cor = NA_real_))
  }

  cand_mat <- tryCatch({
    cand %>% column_to_rownames("site") %>% as.matrix()
  }, error = function(e) NULL)
  if (is.null(cand_mat)) return(list(status = "csv faulty", cor = NA_real_))

  # Ensure symmetric numeric matrix
  if (!is.numeric(cand_mat)) cand_mat <- suppressWarnings(apply(cand_mat, 2, as.numeric))
  cand_mat <- as.matrix(cand_mat)

  # Align to verified by intersecting sites and ordering
  common <- intersect(rownames(verified_mat), rownames(cand_mat))
  if (length(common) < 2) return(list(status = "csv faulty", cor = NA_real_))
  v <- verified_mat[common, common, drop = FALSE]
  c <- cand_mat[as.numeric(common), as.numeric(common), drop = FALSE]

  # Compare lower triangles as vectors
  lv <- v[lower.tri(v, diag = FALSE)]
  lc <- c[lower.tri(c, diag = FALSE)]
  if (length(lv) != length(lc)) return(list(status = "not accurate", cor = NA_real_))

  cor_val <- suppressWarnings(stats::cor(lv, lc, use = "pairwise.complete.obs"))
  if (is.na(cor_val)) return(list(status = "not accurate", cor = NA_real_))

  status <- if (cor_val >= 0.98) "accurate" else "not accurate"
  list(status = status, cor = unname(cor_val))
}

records <- list()
for (f in files) {
    # f <- files
  resp <- readRDS(f)

  # ellmer responses usually have content/text fields; support a few cases
  raw_txt <- tryCatch({
    if (!is.null(resp$content)) resp$content else if (!is.null(resp$text)) resp$text else as.character(resp)
  }, error = function(e) as.character(resp))

  code <- extract_code(raw_txt)
  rec <- list(file = f, code_found = !is.na(code))
  if (is.na(code)) {
    rec$outcome <- "R error"
    rec$cor <- NA_real_
  } else {
    ev <- safe_eval(code)
    if (!isTRUE(ev$ran)) {
      rec$outcome <- "R error"
      rec$cor <- NA_real_
    } else if (!isTRUE(ev$found_csv)) {
    #   rec$outcome <- "Code evaluated but csv faulty or not created"
      rec$outcome <- "CSV faulty"
      rec$cor <- NA_real_
    } else {
      cmp <- compare_matrices(ev$csv, verified_mat)
      if (cmp$status == "csv faulty") {
        rec$outcome <- "CSV faulty"
        rec$cor <- NA_real_
      } else if (cmp$status == "accurate") {
        # rec$outcome <- "Code evaluated and distance matrix produced and is accurate"
        rec$outcome <- "Accurate result"
        rec$cor <- cmp$cor
      } else {
        # rec$outcome <- "Code evaluated and distance matrix produced and not accurate"
        rec$outcome <- "Inaccurate result"
        rec$cor <- cmp$cor
      }
      rec$candidate_csv <- ev$csv
    }
  }
  records[[length(records) + 1]] <- rec
}

results <- dplyr::bind_rows(lapply(records, tibble::as_tibble)) %>%
    # derive Model and Prompt from filename
    mutate(
        fname = basename(file),
        Model = sub("_.*$", "", tools::file_path_sans_ext(fname)),
        Prompt = case_when(
            grepl("detailed", fname, ignore.case = TRUE) ~ "Detailed",
            grepl("vague", fname, ignore.case = TRUE) ~ "Vague",
            TRUE ~ "unknown"
        )
    ) %>%
    select(-fname) %>%
    # aggregate by Model + Prompt + outcome
    group_by(Model, Prompt, outcome) %>%
    summarise(Count = n(), .groups = "drop") %>%
    arrange(Model, Prompt, outcome) %>%
    complete(Model, Prompt, outcome, fill = list(Count = 0)) %>%
    mutate(Count = ifelse(is.na(Count), 0, Count))

# readr::write_csv(results, file.path("scripts/coding-evals/outputs", "llm_eval_results.csv"))

# Plot outcomes as barchart (faceted by Model)
plt <- results %>%
    ggplot(aes(x = outcome, y = Count, fill = Prompt)) +
    geom_col(position = position_dodge(width = 0.8)) +
    facet_wrap(~ Model) +
    labs(x = "Outcome", y = "Count") +
    theme_classic(base_size = 12) + 
    theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
    ) +
    scale_y_continuous(limits = c(0, 10), 
    breaks = seq(0, 10, by = 2)
    )
plt

# Plot proportion of accurate results for each prompt, faceted by Model
plt2 <- results %>%
  group_by(Model, Prompt) %>%
  mutate(Total = sum(Count)) %>%
  ungroup() %>%
  filter(outcome %in% c("Accurate result")) %>%
  mutate(Prop = ifelse(Total > 0, Count / Total, 0)) %>%
  ggplot(aes(x = Prompt, y = Prop, fill = Prompt)) +
  geom_col(position = position_dodge(width = 0.8)) +
  facet_wrap(~ Model) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(x = "Prompt", y = "Correct results (%)", fill = "Prompt") +
  theme_classic(base_size = 12) + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
plt2

library(patchwork)

plotall <- plt2 + plt + plot_layout(ncol =2, guides = "collect") + plot_annotation(tag_levels = 'a', tag_suffix = ")", tag_prefix = "(") 

plotall

ggsave(plotall, filename = "outputs/llm_eval_barchart.png", width = 8, height = 4, dpi = 600)
