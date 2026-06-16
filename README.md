# Environmental and behavioural determinants of the personal light exposome

This repository is a Quarto research compendium for the manuscript **"Environmental and behavioural determinants of the personal light exposome"**. It contains the manuscript, analysis notebooks, figures, tables, a frozen `renv` dependency lockfile, and Quarto website configuration for reproducing the analyses and rendered outputs.

The project analyses harmonised personal light exposure data from the MeLiDos field study. Participants across nine sites in Costa Rica, Germany, Ghana, the Netherlands, Spain, Sweden, and Turkey wore calibrated light loggers near the corneal plane and at chest level and completed repeated contextual assessments. The repository documents data preparation, metric preparation, descriptive summaries, and glasses- and chest-level analyses of environmental, behavioural, and individual determinants of personal light exposure.

## Repository contents

- `index.qmd`: manuscript source.
- `data_preparation.qmd`: imports and preprocesses light, sleep, wear-log, and contextual data.
- `metric_preparation.qmd`: derives analysis-ready light exposure metrics.
- `Descriptives.qmd`: descriptive summaries.
- `RQ1.qmd`, `RQ2.qmd`, `RQ3.qmd`: glasses-level analyses of environmental, behavioural, and individual effects.
- `RQ1_chest.qmd`, `RQ2_chest.qmd`, `RQ3_chest.qmd`: corresponding chest-level analyses.
- `_quarto.yml`: Quarto website configuration and render order.
- `renv.lock`: R package versions used for reproducibility.
- `docs/`: rendered website output produced by Quarto.

## Reproducing the results from the command line

These instructions assume a Unix-like shell. Equivalent commands can be run on Windows PowerShell after installing Git, R, and Quarto.

### 1. Install system prerequisites

Install:

1. [Git](https://git-scm.com/)
2. [R](https://cran.r-project.org/) matching the lockfile as closely as possible. The current `renv.lock` records R 4.5.0.
3. [Quarto](https://quarto.org/docs/get-started/) available on your `PATH`.

Check that R and Quarto are available:

```sh
Rscript --version
quarto --version
```

### 2. Clone the repository

```sh
git clone https://github.com/tscnlab/ZaunerEtAl_bioRxiv_2026.git
cd ZaunerEtAl_bioRxiv_2026
```

### 3. Install `renv` if needed

```sh
Rscript -e 'install.packages("renv", repos = "https://cloud.r-project.org")'
```

### 4. Restore the R package library

Restore the project-local R package library from `renv.lock`:

```sh
Rscript -e 'renv::restore(prompt = FALSE)'
```

If packages require compilation, install any system libraries requested by the compiler or by `renv::restore()`, then rerun the restore command.

### 5. Confirm the project can see its restored dependencies

```sh
Rscript -e 'renv::status()'
```

A clean status means the lockfile and project library are synchronized.

### 6. Render the complete Quarto project

The render order is defined in `_quarto.yml` and writes the website to `docs/`.

To force all computations to run, use:

```sh
quarto render --execute
```

For routine rebuilding with Quarto's configured freeze behaviour, use:

```sh
quarto render
```

### 7. Inspect the rendered output

Open the rendered manuscript and analysis website:

```sh
quarto preview
```

Alternatively, open `docs/index.html` directly in a web browser after rendering.

To check reproduction of results, the files in `tables/` and `figures/` should be checked. 

## Data source

The Quarto notebooks load MeLiDos project data via the analysis code. The website sidebar points to the public data source at <https://github.com/MeLiDosProject>. Ensure network access is available for steps that download data or R packages.

## Citation

Citation metadata are provided in [`CITATION.cff`](CITATION.cff). The manuscript metadata list DOI `10.5281/zenodo.20547314`.

## License

This repository is licensed under the Creative Commons Attribution 4.0 International License; see [`LICENSE.md`](LICENSE.md).
