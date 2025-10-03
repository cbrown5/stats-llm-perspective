
# Read all RDS backups and save as CSV
library(dplyr)
library(purrr)
library(tibble)
library(stringr)

# List all .rds files in backup_dir
rds_files <- list.files(backup_dir, pattern = "\\.rds$", full.names = TRUE)


#CHeck one reasoning model 

x <- readRDS("outputs/rep-backups/online-results/gpt-5:online_prompt3_rep3_annotations.rds")
x <- readRDS("outputs/rep-backups/online-results/gpt-5:online_prompt3_rep3_reasoning.rds")
x <- readRDS("outputs/rep-backups/gpt-5:online_prompt3_rep3.rds")
x
#drop the online models, they didn't work (ellmer doesn't deal with online models properly)
# rds_files <- rds_files[!str_detect(rds_files, "online")]

# Function to extract info from filename
parse_filename <- function(filename) {
    # Remove directory and extension
    fname <- basename(filename)
    fname <- str_remove(fname, "\\.rds$")
    # Split by underscores
    parts <- str_split(fname, "_")[[1]]
    # Model is always the first part (replace first '-' with '/')
    model <- str_replace(parts[1], "-", "/")

    # Find the rep token (starts with 'rep') - usually the last token
    rep_idx <- which(str_detect(parts, "^rep\\d+"))
    rep <- NA_integer_
    if (length(rep_idx) > 0) {
        rep <- as.integer(str_remove(parts[rep_idx[1]], "^rep"))
    }

    # Middle parts (between model and rep) form the prompt; keep underscore if prompt has multiple parts
    if (length(parts) >= 2 && length(rep_idx) > 0) {
        middle_parts <- parts[2:(rep_idx[1] - 1)]
    } else if (length(parts) >= 2) {
        middle_parts <- parts[2:length(parts)]
    } else {
        middle_parts <- character(0)
    }

    # If 'expert' appears as its own token among middle parts, treat that as expert=TRUE
    # Otherwise, if the prompt token itself contains 'expert' (e.g. 'prompt4_expert'), keep it as part of prompt
    expert_flag <- any(middle_parts == "expert")
    prompt_parts <- middle_parts[middle_parts != "expert"]
    prompt <- if (length(prompt_parts) == 0) NA_character_ else paste(prompt_parts, collapse = "_")

    tibble(
        model = model,
        prompt = prompt,
        expert = expert_flag,
        rep = rep
    )
}

# Read and combine all RDS files
all_results <- map_dfr(rds_files, function(f) {
    info <- parse_filename(f)
    response <- readRDS(f)
    tibble(
        model = info$model,
        prompt = info$prompt,
        expert = info$expert,
        rep = info$rep,
        response = as.character(response)
    )
})

# Save as CSV
write.csv(all_results, "outputs/model_prompt_comparison.csv", row.names = FALSE)
