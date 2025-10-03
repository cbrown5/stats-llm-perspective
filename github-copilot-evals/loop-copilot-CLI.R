# Configuration
n_replicates <- 10
base_dir <- "github-copilot-evals"
data_file <- file.path(base_dir, "fish-coral.csv")

# Your prompt for Copilot CLI
copilot_prompt <- "Create and run a generalized linear model of fish abundance against coral cover. The data is in fish-coral.csv data file. Fish abundance is the variable `pres.topa`. Coral cover is the variable `CB_cover` and needs to be divided by `n_pts` to get proportional cover before analysis. Fish abundances is count data, so use a negative binomial family for the GLM. Create verification plots and plots of predicted fish abundance against the range of coral covers. Write the results of the GLM to a file. Use the R program for analyses and plots."

# Create subdirectories and run replicates
for (i in 1:n_replicates) {
    # i <- 1
  # Create subdirectory name
  subdir_name <- paste0("fish-coral", i)
  subdir_path <- file.path(base_dir, subdir_name)
  
  # Create subdirectory if it doesn't exist
  if (!dir.exists(subdir_path)) {
    dir.create(subdir_path, recursive = TRUE)
    cat("Created directory:", subdir_path, "\n")
  }
  
  # Copy data file to subdirectory
  dest_file <- file.path(subdir_path, "fish-coral.csv")
  file.copy(data_file, dest_file, overwrite = TRUE)
  cat("Copied data to:", dest_file, "\n")
  
  # Build Copilot CLI command
#   copilot_cmd <- sprintf(
#     "cd '%s' && copilot -p '%s' --model gpt-5 --allow-tool 'write' --allow-tool 'read' --allow-tool 'shell(Rscript)'",
#     subdir_path,
#     copilot_prompt
#   )
  
 copilot_cmd <- sprintf(
    "cd '%s' && copilot -p '%s' --model gpt-5 --allow-all-tools --deny-tool 'shell(cd)' --deny-tool 'shell(git)'",
    subdir_path,
    copilot_prompt
  )

  # Run Copilot CLI
  cat("Running replicate", i, "in", subdir_name, "\n")
  system(copilot_cmd)
  cat("Completed replicate", i, "\n\n")
}

cat("All replicates completed!\n")
