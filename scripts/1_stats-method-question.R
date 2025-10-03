library(ellmer)

nreps <- 10

# models <- c("openai/gpt-5", "openai/gpt-5:online", "anthropic/claude-sonnet-4.5", 
            # "moonshotai/kimi-k2-0905", "openai/gpt-4.1")
# models <- c("openai/gpt-5", "moonshotai/kimi-k2-0905")
models <- c("anthropic/claude-sonnet-4.5", 
            "openai/gpt-4.1")


prompts <- list(
  prompt1 = "How can I test the relationship between two continuous variables?",
  prompt2 = "How can I test the relationship between fish abundance and coral cover?",
  prompt3 = "What statistical method can I use to quantify the relationship between fish abundance and coral cover?",
  prompt4 = "What statistical method can I use to quantify the relationship between fish abundance and coral cover? I have observations of coral cover (continuous percentage) and fish abundance (count of number of fish). Observations were made at 49 different locations. Observations were made with standardized surveys, so the area surveyed at each site was the same."
)

# Store results
results <- list()
backup_dir <- "outputs/rep-backups"

# Loop over models and prompts
for (model in models) {
  for (prompt_name in names(prompts)) {
    for (rep in 1:nreps){
    
    cat("Testing", model, "with", prompt_name, "\n")
    cat("rep:", rep, "\n")
    
    chat <- chat_openrouter(
      system_prompt = "You are a helpful assistant. Respond in 200 words or less.", 
      model = model, 
      echo = "none"
    )
    response <- chat$chat(prompts[[prompt_name]])
    
    # Backup each response in outputs/rep-backups with a descriptive filename
    
    backup_filename <- sprintf(
      "%s/%s_%s_rep%d.rds",
      backup_dir,
      gsub("/", "-", model),
      prompt_name,
      rep
    )
    saveRDS(response, backup_filename)

    results[[paste(model, prompt_name, rep, sep = "_")]] <- list(
      model = model,
      prompt = prompt_name,
      rep = rep,
      system_prompt = "You are a helpful assistant. Respond in 200 words or less.",
      response = response
    )

    Sys.sleep(5)
    }
  }
}

# Save results
saveRDS(results, "outputs/model_prompt_comparison.rds")


# Additional test with different system prompt for gpt5
for (prompt_name in names(prompts)[4]) {
    for (rep in 1:nreps){
  cat("Testing openai/gpt5 with ecological expert prompt and", prompt_name, "\n")
  
  chat <- chat_openrouter(
    system_prompt = "You are a helpful assistant who is an expert in ecological data analysis. Respond in 200 words or less.", 
    model = "openai/gpt-5", 
    echo = "none"
  )
  
  response <- chat$chat(prompts[[prompt_name]])

   backup_filename <- sprintf(
      "%s/%s_%s_rep%d.rds",
      backup_dir,
      gsub("/", "-", model),
      paste(prompt_name, "expert", sep = "_"),
      rep
    )
    saveRDS(response, backup_filename)

  
  results[[paste("openai/gpt5_expert", prompt_name,rep, sep = "_")]] <- list(
    model = "openai/gpt-5",
    prompt = prompt_name,
    rep = rep, 
    system_prompt = "You are a helpful assistant who is an expert in ecological data analysis. Respond in 200 words or less.",
    response = response
  )

  Sys.sleep(5)
    }
}

#one more for an online search 

library(httr)
library(jsonlite)
openrouter_api_key <- Sys.getenv("OPENROUTER_API_KEY")

for (prompt_name in names(prompts)[3]) {
    for (rep in 1:nreps){
      # prompt_name <- names(prompts)[3]
      # rep <- 1
  cat("Testing openai/gpt5 with web search", prompt_name, "\n", "rep", rep)
  
   response <- POST(
    url = "https://openrouter.ai/api/v1/chat/completions",
    add_headers(
      "Content-Type" = "application/json",
      "Authorization" = paste("Bearer", openrouter_api_key)
    ),
    body = toJSON(list(
      model = "openai/gpt-5:online",
      messages = list(
        list(
          role = "system",
          content = "You are a helpful assistant who is an expert in ecological data analysis. Respond in 200 words or less."
        ),  
        list(
          role = "user",
          content = paste("Search the web to tell me:", prompts[[prompt_name]])
        )
      ),
      web_search_options = list(
        search_context_size = "medium"
      )
    ), auto_unbox = TRUE),
    encode = "raw"
  )

   backup_filename <- sprintf(
      "%s/%s_%s_rep%d.rds",
      backup_dir,
      gsub("/", "-", "gpt-5:online"),
      paste(prompt_name,  sep = "_"),
      rep
    )

  r3 <- fromJSON(content(response, "text"))
    
    
    saveRDS(r3$choices$message$content[[1]], backup_filename)

    # Save reasoning and annotations as separate files
    reasoning_filename <- sprintf(
      "%s/%s_%s_rep%d_reasoning.rds",
      paste0(backup_dir, "/online-results"),
      gsub("/", "-", "gpt-5:online"),
      paste(prompt_name, sep = "_"),
      rep
    )
    annotations_filename <- sprintf(
      "%s/%s_%s_rep%d_annotations.rds",
      paste0(backup_dir, "/online-results"),
      gsub("/", "-", "gpt-5:online"),
      paste(prompt_name, sep = "_"),
      rep
    )
    saveRDS(r3$choices$message$reasoning[[1]], reasoning_filename)
    saveRDS(r3$choices$message$annotations[[1]], annotations_filename)
    

  Sys.sleep(5)
    }
}

# Save results
# saveRDS(results, "outputs/online-model_prompt_comparison.rds")

