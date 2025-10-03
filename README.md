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

TODO, Create a test where I output a specific parameter and assess accuracy. Do a zero shot attempt.... 

## TODO

Revise manuscript to respond to reviews. 
See notes-for-responding-to-reviews.qmd for references to cite, as well as a rough plan for implementing some simulations. 
