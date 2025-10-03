# -------------------------------------------------------------------
# Method Summary:
# Automates generation of replicate analysis environments to study
# how prompt specificity affects AI-produced R analysis pipelines.
#
# Workflow:
# 1. Defines two prompt conditions (simple vs detailed reference doc).
# 2. Iterates over replicate indices, creating isolated directories.
# 3. Copies core dataset (fish-coral.csv) into each directory.
# 4. For "detailed" condition, also copies glm-readme.md.
# 5. Invokes Copilot CLI with restricted shell capabilities to
#    prevent directory traversal and external tool usage (git, pwd).
# 6. Allows writing/reading and R execution inside the sandbox.
#
# Experimental Design Notes:
# - Total conceptual design = 20 replicates (1–10 simple, 11–15 simple,
#   16–20 detailed). Current loop covers 11–20 segment.
# - Isolation ensures no cross-contamination of generated code.
# - Tool denial enforces reproducible, scope-limited behavior.
#
# Outputs:
# - Each replicate directory contains AI-generated R scripts, output
#   figures, and intermediate artifacts for downstream similarity
#   analysis (see 2_script_dists.R).
#
# Reproducibility:
# - Non-determinism arises from Copilot model variability.
# - Rerunning may produce different scripts while preserving structure
#   of experimental manipulation.
# -------------------------------------------------------------------
# run the copilot CLI in a loop 
# CJ Brown 2025-10-03

# The first five replicates use a simple prompt, the second 5 replicates point the agent to a detailed readme file. 
#
# The script creates each sub-directory and copies relevant files into that sub-directory. We don't allow the copilot agent to cd to other directories, to control the scope of what it can see. 

# Configuration
n_replicates <- 20
base_dir <- "github-copilot-evals"
data_file <- file.path(base_dir, "fish-coral.csv")

#Directory for test repos
test_dir <- "test2"

# Your prompt for Copilot CLI
copilot_prompt <- "I want to quantify the dependence of fish abundance on coral cover. The data is in the fish-coral.csv data file. Fish abundance is the variable `pres.topa`. Coral cover is the variable `CB_cover`. Do the complete analysis for me and save all the results as figures and text files. Use the R program. Run Rscripts from the terminal with quote around the file like: Rscript 'my-scripts.R'."

copilot_prompt2 <- "See glm-readme.md for instructions."


# Create subdirectories and run replicates
for (i in 11:20) {
    # i <- 1
  # Create subdirectory name
  subdir_name <- file.path(test_dir, paste0("fish-coral", i))
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
  
  # Set-up prompt and copy glm-readme.md to subdirectory if needed
  
  if (i <= 15) {
    prompt_use <- copilot_prompt
  } else {
    prompt_use <- copilot_prompt2
    dest_file2 <- file.path(subdir_path, "glm-readme.md")
    file.copy("github-copilot-evals/glm-readme.md", dest_file2, overwrite = TRUE)
    cat("Copied readme to:", dest_file2, "\n")
  }

  # Build Copilot CLI command
#   copilot_cmd <- sprintf(
#     "cd '%s' && copilot -p '%s' --model gpt-5 --allow-tool 'write' --allow-tool 'read' --allow-tool 'shell(Rscript)'",
#     subdir_path,
#     copilot_prompt
#   )
  
 copilot_cmd <- sprintf(
    "cd '%s' && copilot -p '%s' --allow-all-tools --deny-tool 'shell(cd)' --deny-tool 'shell(git)' --deny-tool 'shell(pwd)'",
    subdir_path,
    prompt_use
  )

  # Run Copilot CLI
  cat("Running replicate", i, "in", subdir_name, "\n")
  system(copilot_cmd)
  cat("Completed replicate", i, "\n\n")
}
