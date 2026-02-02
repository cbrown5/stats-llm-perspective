# stats-llm-perspective

Perspective paper on use of LLMs for statistical advice and implementation. Focus on environment and ecology. 

`render-ms.R` Knits the manuscript. 

## scripts/ 

`diagram.R` Creates the workflow diagram for the paper

### Test 1: How to ask an LLM for statistical advice? 

Scripts 1-3
`1_stats-methods-questions.R` Runs replicate prompts for a number of LLMs to gather responses to a simple questions of how to do a statistical test 
Resulst are saved to `outputs/rep-backups`. Online model reasoning and annotations are then saved to the `online-results` subfolder. 

`2_combine-results.R` combines all results from 1_, which are saved as rds files, into a single csv

`3_analyse-stats-methods.R` Makes plots of the results

### Test 2: How to get consistent implementation

See folder `github-copilot-evals/` 

These tests run the Github Copilot CLI for replicate prompts. Results are stored in the folder `test2`. (`test1` was a pilot). Two prompts were used, a simple prompt and a detailed spec sheet. 

`github-copilot-evals/glm-readme.md` Detailed spec sheet for the second prompt. Simplified version of a spec sheet I used in a more comprehensive analysis of LLM Agent response accuracy https://github.com/cbrown5/agentic-ai-fisheries

`github-copilot-evals/1_loop-copilot-CLI.R` Runs the copilot CLI in a loop for two different prompt strategies. It does this in replicate sub-directories, which stops copilot 'looking' at context outside its sub-directory. 

`github-copilot-evals/2_script_dists.R` Use the `rscc` package and the TF-IDF method to calculate cosine similarity among the R code in each repo. Then it plots the similarities as an ordination. 

`github-copilot-evals/fish-coral.csv` dataset to use for the test runs. 

### Test 3: How to write code that is accurate and evaluates

See folder `scripts/coding-evals/`

These tests evaluate LLM-generated code for accuracy and correctness. Scripts test models' abilities to generate error-free code with simple system prompts, assess code documentation capabilities, and conduct evaluations where models write code and produce output/plots that can be evaluated for accuracy. 

These tests evaluate LLM-generated code for accuracy and correctness. Scripts conduct evaluations where models write code and produce output/plots that can be evaluated for accuracy.

`scripts/coding-evals/1_verified_bray_distance.R` Creates a verified reference output by computing Bray-Curtis distance matrix from benthic cover data. Normalizes cover by points, averages by site and code, pivots to wide format, and computes distances using vegan. Saves verified results to compare against LLM outputs.

`scripts/coding-evals/2_run_llm_replicates.R` Runs 10 replicates per model and prompt using ellmer + OpenRouter. Tests two prompt strategies (detailed workflow vs vague instructions) for calculating distance matrices from benthic cover data. Saves raw LLM responses as RDS files to `outputs/reps-backups`.

`scripts/coding-evals/3_evaluate_llm_outputs.R` Evaluates LLM-generated code by executing it and comparing outputs to the verified reference. Categorizes results as "Accurate result", "Inaccurate result", "CSV faulty", or "R error". Creates bar charts showing proportion of correct results by model and prompt type. 
