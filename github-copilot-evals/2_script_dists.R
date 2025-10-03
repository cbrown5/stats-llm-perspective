
# Make an ordination of R scripts from multiple repos using cosine similarity

library(rscc)
library(vegan)
library(ggplot2)
library(patchwork)

# Set path to repos
base_dir <- "github-copilot-evals/test2"

# Get all repo subdirectories
repo_dirs <- list.dirs(base_dir, full.names = TRUE, recursive = FALSE)

prompt_dat <- data.frame(
  repo = paste('fish-coral', 1:20, sep=''),
  prompt_type = c(rep("Simple", 5), rep("Detailed and specific", 5), rep("Simple", 5), rep("Detailed and specific", 5))
)

# For each repo, find all .R files and combine into one document
repo_files <- lapply(repo_dirs, function(repo) {
  list.files(repo, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
})
names(repo_files) <- basename(repo_dirs)


# Read and combine all R scripts per repo
repo_code <- lapply(repo_files, function(files) {
  # Read all files, collapse into one string
  code <- unlist(lapply(files, function(f) readLines(f, warn = FALSE)))
  paste(code, collapse = "\n")
})

# Recursively count the number of files in each repo, including all files in all subdirectories
repo_file_counts <- sapply(repo_dirs, function(idir) {
    length(list.files(idir, recursive = TRUE))})

#Make a dataframe and join to  prompt_dat
repo_info <- data.frame(repo = names(repo_code), file_count = repo_file_counts, stringsAsFactors = FALSE)
prompt_dat <- merge(prompt_dat, repo_info, by = "repo", all.x = TRUE)

# Create a temporary file per repo to use with rscc::sourcecode
tmp_files <- mapply(function(code, name) {
  tf <- tempfile(pattern = paste0(name, "_"), fileext = ".R")
  writeLines(code, tf)
  tf
}, repo_code, names(repo_code), USE.NAMES = TRUE)

# Use rscc to create sourcecode objects
prgs <- sourcecode(tmp_files, title = names(tmp_files), silent = TRUE)

# MDS using vegan
# Repeat MDS for both sim_matrix_funs and sim_matrix_names

# Helper function to calculate similarity run MDS and prepare data
run_mds <- function(prgs, label) {
    # ---------------------------------------------------------------
    # run_mds:
    # Input:
    #   prgs  - rscc sourcecode object.
    #   label - token type selector ("funs" or "names").
    # Process:
    #   1. Extract documents(prgs, type = label).
    #   2. Compute tf-idf similarity matrix (cosine).
    #   3. Convert to dissimilarity and apply monoMDS (2D).
    #   4. Return list with:
    #        $points (data.frame: MDS1, MDS2, repo, prompt_type, stress)
    #        $mds    (monoMDS object for diagnostics).
    # Justification:
    #   monoMDS chosen for direct monotonic scaling without additional
    #   data standardization (inputs already similarity-derived).
    # ---------------------------------------------------------------
    docs <- documents(prgs, type = label)
    #vars for variable names, including declared variables and variables read in from files
    # funs for function names
    # names for functions and variable names

    # Calculate cosine similarity using tfidf
    sim_matrix <- tfidf(docs)

# Set row/col names to repo names
    rownames(sim_matrix) <- colnames(sim_matrix) <- names(repo_code)
    
    #do distance matrix and MDS
    dist_matrix <- 1 - sim_matrix
    mds <- monoMDS(dist_matrix, k = 2, trymax = 20, autotransform = FALSE)
    mds_points <- as.data.frame(mds$points)
    mds_points$repo <- rownames(mds_points)
    mds_points <- merge(mds_points, prompt_dat, by = "repo", all.x = TRUE)
    mds_points$mds_type <- label
    mds_points$stress <- mds$stress
    
    list(points = mds_points, mds = mds)
}

#Run MDS for both function names and variable names
mds_funs <- run_mds(prgs, "funs")
mds_names <- run_mds(prgs, "names")

# Combine for plotting if needed


# Plot MDS with ggplot2
g1 <- ggplot(mds_funs$points, aes(x = -MDS1, y = MDS2, color = prompt_type, label = repo)) +
    geom_point(size = 3) +
    # geom_text(vjust = -0.7, size = 3) +
    annotate("text", x = Inf, y = Inf, label = paste0("Stress = ", round(mds_funs$mds$stress, 3)), 
                     hjust = 1.1, vjust = 1.5, size = 4) +
    labs(color = "Prompt Type", x = "MDS1", y = "MDS2") +
    theme_classic()

g2 <- ggplot(mds_names$points, aes(x = MDS1, y = MDS2, color = prompt_type, label = repo)) +
    geom_point(size = 3) +
    # geom_text(vjust = -0.7, size = 3) +
    annotate("text", x = Inf, y = Inf, label = paste0("Stress = ", round(mds_names$mds$stress, 3)), 
                     hjust = 1.1, vjust = 1.5, size = 4) +
    labs(color = "Prompt Type", x = "MDS1", y = "MDS2") +
    theme_classic()

gall <- g1 + g2 + plot_layout(guides = "collect",ncol = 2) + 
    plot_annotation(tag_levels = "a", tag_prefix = "(", 
    tag_suffix = ")") 
gall

ggsave(gall, file = "outputs/mds_plots.png", width = 10, height = 5)

# Make a histogram of number of files, colour by repo type
ggplot(prompt_dat, aes(x = file_count, fill = prompt_type)) +
    geom_histogram(binwidth = 1, position = "dodge", color = "black") +
    labs(title = "Distribution of Number of Files per Repo",
         x = "Number of Files",
         y = "Count") +
    theme_minimal() +
    scale_fill_brewer(palette = "Set1")


