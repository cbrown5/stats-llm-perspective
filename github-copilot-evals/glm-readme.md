# Analysis of fish dependence on coral habitat

## Introduction
This project will ask how abundance of fish juveniles depends on coral cover. The fish is called 'topa'. 

## Aims of the analysis 

1. Does fish abundance depend on branching coral cover? 
2. What is the direction and strength of the relationship between fish abundance and branching coral cover? 

## Data methodology

The data was collected with the point intersect transect method. Divers swam along transects. There were several transects per site.  Along each transect they dropped points and recorded the type of benthic organism (in categories) on that point. Percentage cover for one organism type can then be calculated as the number of points with that organism divided by the total number of points on that transect. In our data we have percent cover of branching corals. 
Transects were averaged to give a single value for each site. 
At each site divers also counted the number of juvenile 'topa' along dive transects of the same length. 

## Analysis methodology 

We will use generalized linear models to analyze the relationship between topa and the two coral cover types. 

The variable `CB_cover` needs to be normalized by `n_pts` to get the proportional cover. 

Topa abundance is probably over-dispersed, so we we will need to use a negative binomial family. We will use R and the MASS package: 

```
MASS::glm.nb(pres.topa ~ CB_cover_percent, data = fish_coral_cover_sites)
```

We will use likelihood ratio tests to test the significance of CB_cover_percent. For example:

```
m1 <- MASS::glm.nb(pres.topa ~ CB_cover_percent, data = fish_coral_cover_sites)
m2 <- MASS::glm.nb(pres.topa ~ 1, data = fish_coral_cover_sites)
anova(m1, m2, test = "Chisq")
```

You will need to do model diagnostics. These will include checking residuals and the dispersion parameter. Save these as png files. 

### Tech context
- We will use the R program
- Each script should be modular and save intermediate results as datafiles and figures. 
- tidyverse packages for data manipulation
- ggplot2 for data visualization
- use `theme_set(theme_classic())` for plots
- Use the `MASS` package for the negative binomial model, however don't load it globally with `library(MASS)`, instead use `MASS::glm.nb()` to avoid namespace conflicts.
- Use `visreg` package for plotting model effects and confidence intervals

Keep your scripts short and modular to facilitate debugging. Don't complete all of the steps below in one script. Finish scripts where it makes sense and save intermediate datasets. 

When using Rscript to run R scripts in terminal put quotes around the file, e.g. `Rscript "1_model.R"`

### Workflow 

1. Create a todo list and keep track of progress
2. Data processing including standardizing coral variables by number of points
3. Model selection and verification, produce diagnostic plots
4. Create model diagnostic plots 
5. Create plots of predictions from the final model

### Directory structure 

```
glm-test-case/
├── data/                   # Processed data files and intermediate datasets
├── fish-coral.csv          # Raw data file with fish and coral cover measurements
├── outputs/                # Generated output files
│   ├── results/            # Text files of model results
│   └── plots/              # Diagnostic plots and visualization outputs (PNG files)
└── scripts/                # R scripts for data analysis and modeling
```

## Meta data 

### fish-coral.csv

Location: `data/fish-coral.csv`

Variables
- site: Unique site IDs, use to join to benthic_cover.csv
- reef.ID: Unique reef ID
- pres.topa: number of Topa counted (local name for Bolbometopon)
- pres.habili: number of Habili counted (local name for Cheilinus) 
- secchi: Horizontal secchi depth (m), higher values mean the water is less turbid
- flow: Factor indicating if tidal flow was "Strong" or "Mild" at the site
- logged: Factor indicating if the site was in a region with logging "Logged" or without logging "Not logged"
- coordx: X coordinate in UTM zone 57S
- coordy: Y coordinate in UTM zone 57S
- CB_cover: Number of PIT points for branching coral cover
- soft_cover: Number of PIT points for soft coral cover
- n_pts: Number of PIT points at this site (for normalizing cover to get per cent cover)
- dist_to_logging_km: Linear distance to nearest log pond (site where logging occurs) in kilometres. 