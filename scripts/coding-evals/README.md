# LLM R-coding evaluation: vegan distance task

This folder contains three scripts to evaluate whether LLMs can turn reasoning into working R code for a vegan distance workflow.

## Files
- `1_verified_bray_distance.R` – Creates the verified Bray–Curtis distance matrix from `scripts/coding-evals/data/benthic-cover.csv` (tolerates minor path typos) and writes `outputs/verified_bray_distance.csv`.
- `2_run_llm_replicates.R` – Uses the `ellmer` package with the OpenRouter API to run two prompts (detailed and vague) 10 times each, saving raw responses to `outputs/rep-backups/`.
- `3_evaluate_llm_outputs.R` – Parses `<code>...</code>` from backups, executes the code in a clean environment, looks for a produced CSV, compares it to the verified matrix, classifies outcomes, and plots a barchart.

## Requirements
- R packages: `tidyverse`, `vegan`, `rlang`, `glue`, and `ellmer`.
- OpenRouter: set `OPENROUTER_API_KEY` in your environment, and optionally `OPENROUTER_MODEL` (defaults to `anthropic/claude-3.5-sonnet`).
- Data file: `scripts/coding-evals/data/benthic-cover.csv` with columns `site, trans, code, cover, n.pts`.

## How to run
1. Verified result
   - Run `1_verified_bray_distance.R` to create `outputs/verified_bray_distance.csv`.
2. LLM replicates
   - Ensure your OpenRouter API key is set and the `ellmer` package is installed.
   - Run `2_run_llm_replicates.R` to generate and back up responses into `outputs/rep-backups/`.
3. Evaluation
   - Run `3_evaluate_llm_outputs.R` to classify runs and produce:
     - `outputs/llm_eval_results.csv`
     - `outputs/llm_eval_barchart.png`

Outcome categories:
- code didn't evaluate
- code evaluated but csv faulty or not created
- code evaluated and distance matrix produced but not accurate
- code evaluated and distance matrix produced but is accurate (correlation ≥ 0.98)

Tips:
- If the data path is slightly different (e.g., `coding-vals` or `benthic_cover.csv`), the verified script tries common variants.
- To change the model: `export OPENROUTER_MODEL="openai/gpt-4o-mini"` (or similar).