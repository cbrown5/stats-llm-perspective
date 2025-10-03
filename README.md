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

### Test 2: 

## TODO

Revise manuscript to respond to reviews. 
See notes-for-responding-to-reviews.qmd for references to cite, as well as a rough plan for implementing some simulations. 
