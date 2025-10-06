# Evaluating ability of LLMs to convert reasoning into R code

**Prompt used to draft the initial eval task** 

I want to create an evalation of the ability of LLMs to turn reasoning into R code. 

The task for the Copilot Agent is to scaffold this evaluation, including code and creating drafts of the prompts. We also need to create an R script that produces the verified solution. 

To do this we need to set-up two prompts. A first prompt that is detailed and specific about the workflow. A second prompt that is more vague. We will then run replicates of each prompt 10 times via API calls to an LLM provider. 

## The aim of the workflow

Create a distance matrix among sites in `scripts/coding-vals/data/benthic-cover.csv' using the mahalonobis distance metric. Save this matrix as a csv file. 

The ideal workflow is

1. Load vegan and tidyverse packages
2. benthic_cover.csv is a long format dataset with columns 'site', 'trans', 'code', 'cover, 'n.pts'. First normalized `cover/n.pts`, then take means by `site` and `cover`, then convert this to wide format data with one column for each species ('code')
3. Use vegdist to compute the 'bray' distance.
4. Save the distance matrix as a .csv file. Both prompts need to include instructions to save a csv file in a standardized way. 

## Evaluations 

Create a system prompt that tells each replicate prompt to output R code in `<code></code>` tags. 
Run 10 replicate prompts. Use R ellmer package and the openrouter API. 
Save each response as you go in case of problems. e.g.

```
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

```

In a new script gather the responses. Parse the R code. Run it. Capture whether the R code executes or not. If it executes, capture the csv file it creates. Then attempt to do a correlation of that csv file with the verified distance matrix from our ideal script. 

Then record for each replicate one of these outcomes: code didn't evaluate, code evaluated but csv faulty or not created, code evaluated and distance matrix produced but not accurate, code evaluated and distance matrix produced but is accurate. If the last one, record the correlation coefficient. 

Then plot the outcomes as a barchart. Any correlation coefficient over 0.98 you can assign as 'accurate'. 

