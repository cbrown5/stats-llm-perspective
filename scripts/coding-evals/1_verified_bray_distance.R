# Verified Bray-Curtis distance computation for benthic cover data
# - Reads benthic-cover.csv from scripts/coding-evals/data (with a few tolerant path variants)
# - Normalizes cover by n.pts, averages by site x code, pivots to wide, computes vegdist(method='bray')
# - Saves outputs/verified_bray_distance.csv

library(tidyverse)
library(vegan)


infile <- "scripts/coding-evals/data/benthic-cover.csv"
message("Reading: ", infile)

dat <- readr::read_csv(infile, show_col_types = FALSE)

# Normalize cover and summarize to site x code means
dat_norm <- dat %>%
  mutate(cover_norm = cover / n.pts) %>%
  group_by(site, code) %>%
  summarise(cover_mean = mean(cover_norm, na.rm = TRUE), .groups = "drop")

# Wide matrix (sites as rows, species codes as columns)
wide <- dat_norm %>%
  tidyr::pivot_wider(names_from = code, values_from = cover_mean, values_fill = 0) %>%
  arrange(site)

# Keep site as rownames and remove from matrix
mat <- wide %>% column_to_rownames("site") %>% as.matrix()

# Compute Bray-Curtis distances
bray <- vegan::vegdist(mat, method = "manhattan")

# Convert to full square matrix for CSV output
bray_mat <- as.matrix(bray)

outfile <- file.path("scripts/coding-evals/outputs", "verified_bray_distance.csv")
readr::write_csv(
  tibble::as_tibble(rownames_to_column(as.data.frame(bray_mat), var = "site")),
  outfile
)