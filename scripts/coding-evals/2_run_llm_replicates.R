# Run LLM replicates for R-coding evaluation using ellmer + OpenRouter
# - Defines system prompt to require R code inside <code></code>
# - Two prompts: detailed and vague per eval-task.md
# - Runs 10 replicates per prompt, saves each raw response RDS into outputs/rep-backups

library(tidyverse)

key <- Sys.getenv("OPENROUTER_API_KEY")

models <- c(
 "openai/gpt-5-nano",
 "openai/gpt-5-mini",
 "openai/gpt-5-codex",
  "openai/gpt-5"
)

system_prompt <- paste(
  "You are an expert R programmer. Respond with valid and fully self-contained R code wrapped in <code></code> tags. For example <code>print('Hello, world!')</code>.",
  sep = "\n"
)

# Data path instruction used by both prompts. Keep consistent save location and filename pattern.

# Prompt A: detailed workflow
prompt_detailed <- glue::glue(
"## Goal 
Write complete R code that can create a Bray-Curtis distance matrix among sites. 

## Workflow

1) Load vegan and tidyverse.
2) Load the long format data from scripts/coding-evals/data/benthic-cover.csv.
3) Data columns are 'site','trans','code','cover','n.pts'. 
4) Compute cover is count of points and needs to be normalized: as proportion_cover = cover/n.pts; then group by sites and code to get the mean of proportion_cover; then pivot wider to sites x codes (fill missing with 0).
5) Use vegan::vegdist(method='bray') on the wide matrix (rows=sites, cols=codes).
6) Convert to a full square matrix, with site names as first column 'site', and write to 'scripts/coding-evals/outputs/llm_distance.csv'.

## Getting started 
You can start with this code to load the data:
<code>
library(tidyverse)
library(vegan)
infile <- 'scripts/coding-evals/data/benthic-cover.csv'
dat <- readr::read_csv(infile, show_col_types = FALSE)
</code>

"
)

# Prompt B: vague workflow
prompt_vague <- glue::glue(
  "Write R code to calculate a distance matrix among sites from the benthic cover dataset using vegan. 
You will need to load the long format data from scripts/coding-evals/data/benthic-cover.csv. Data columns are 'site','trans','code','cover','n.pts'. 
Write results to 'scripts/coding-evals/outputs/llm_distance.csv'. 

## Getting started 
You can start with this code to load the data:
<code>
library(tidyverse)
library(vegan)
infile <- 'scripts/coding-evals/data/benthic-cover.csv'
dat <- readr::read_csv(infile, show_col_types = FALSE)
</code>


"
)

prompts <- list(
  detailed = as.character(prompt_detailed),
  vague = as.character(prompt_vague)
)

backup_dir <- "scripts/coding-evals/outputs/reps-backups"

run_replicates <- function(prompts, model, reps = 10L) {
  results <- list()
  for (prompt_name in names(prompts)) {
    for (rep in seq_len(reps)) {
      # Safe model name for filenames
      safe_model <- gsub("/+", "-", model)
      cat(sprintf("Running model %s | prompt %s | rep %d...\n", model, prompt_name, rep))
      chat <- ellmer::chat_openrouter(
        system_prompt = system_prompt,
        # system_prompt = "You are a helpful assistant who writes R code.",
        model = model,
        echo = "none"
      )
      
      response <- chat$chat(prompts[[prompt_name]])

      # Save response as .md with newlines as returns
      md_filename <- sprintf(
        "%s/%s_%s_rep%d.md",
        backup_dir,
        safe_model,
        prompt_name,
        rep
      )
      md_text <- gsub("\n", "\r\n", response)
      writeLines(md_text, md_filename)

      # Backup each response with a descriptive filename
      backup_filename <- sprintf(
        "%s/%s_%s_rep%d.rds",
        backup_dir,
        safe_model,
        prompt_name,
        rep
      )
      saveRDS(response, backup_filename)

    }
  }
  results
}

for (model in models) {
  # Run replicates          
results <- run_replicates(prompts, model, reps = 10)

}
