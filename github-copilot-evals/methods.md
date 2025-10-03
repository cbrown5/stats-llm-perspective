# Methods

## Overview
This study evaluates how prompt specificity influences the structure of R code produced by an AI assistant (Copilot CLI). Twenty independent project directories (fish-coral1..20) were generated under two prompt regimes (Simple vs Detailed). Code artifacts were collected and analyzed using token-based cosine similarity and ordination.

## Script 1: 1_loop-copilot-CLI.R (Data Generation)
- Purpose: Automate creation of replicate analysis projects using the Copilot CLI.
- Inputs:
  - fish-coral.csv (primary dataset)
  - glm-readme.md (only for detailed prompt condition)
- Experimental Design:
  - 20 replicates total.
  - Replicates 1–10: simple analysis prompt (not regenerated in current loop range 11–20 but part of design).
  - Replicates 11–20: mixture of simple (11–15) and detailed (16–20) prompts (current loop segment).
- Prompt Conditions:
  - Simple: Direct request to perform full analysis.
  - Detailed: Instructs agent to consult glm-readme.md (added to directory).
- Containment:
  - Each replicate isolated in its own subdirectory.
  - Tools restricted: deny shell(cd), shell(git), shell(pwd) to limit scope.
- Execution:
  - For each replicate: create directory, copy data (and readme if needed), invoke Copilot CLI with selected prompt.
  - Copilot is allowed all other tools to read/write and run R scripts.
- Outcome:
  - A set of heterogeneous R scripts and outputs per replicate for later comparative analysis.

## Script 2: 2_script_dists.R (Code Similarity & Ordination)
- Purpose: Quantify structural/code-level similarity among replicate projects and visualize clustering by prompt type.
- Collection:
  - All .R files per replicate directory concatenated into a single document (repository-level code corpus).
- Tokenization & Feature Space:
  - rscc::documents() invoked with types:
    - funs: function names.
    - names: combined function and variable identifiers.
  - Term-weighting: tf-idf via rscc::tfidf() to normalize for common vs distinctive identifiers.
- Similarity Metric:
  - Cosine similarity on tf-idf vectors -> sim_matrix.
  - Converted to dissimilarity: dist = 1 - similarity.
- Ordination:
  - monoMDS (vegan) with k = 2 dimensions; metaMDS not used here to retain direct control (already standardized).
  - Stress recorded per token set (funs vs names).
  - One axis in first plot negated for improved visual separation (sign indeterminacy).
- Repository Metadata:
  - File count per replicate (recursive) used to explore complexity/size differences vs prompt type.
- Visualization:
  - Paired MDS scatterplots (functions vs names) colored by prompt type with stress annotation.
  - Histogram of file counts by prompt category.
- Output:
  - Combined MDS panel saved to outputs/mds_plots.png.
- Interpretation:
  - Tighter clustering suggests convergence under a given prompt style.
  - Divergence reflects variability induced by prompt specificity.

## Reproducibility Notes
1. Run 1_loop-copilot-CLI.R to (re)generate replicate directories.
2. Ensure required packages installed: rscc, vegan, ggplot2, patchwork.
3. Run 2_script_dists.R to produce similarity analysis and figures.
4. Randomness: Copilot generation may introduce non-determinism; results represent one realization.

## Limitations
- Identifier-based similarity ignores control flow and semantics.
- Concatenation removes intra-file structure.
- Copilot outputs may vary across runs (model nondeterminism).
- No filtering of automatically generated auxiliary files (only .R considered).

## Potential Extensions
- Add AST-based structural distance.
- Include code complexity metrics (cyclomatic, LOC).
- Bootstrap stability of ordination.
- Incorporate semantic embeddings (e.g., via LLM embedding models) for comparison.

