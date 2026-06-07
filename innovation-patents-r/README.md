# What Drives a Country's Innovation?

Predicting the intensity of patenting activity across countries from demographic,
socio-economic, and technological indicators.

**Authors:** Mia Di Marco and Elisa Sofia (joint course project).
**Language:** R.

## Question

How well can a country's yearly patenting intensity be predicted from structural
features such as R&D expenditure, number of researchers, internet usage,
urbanization, population density, and age structure? The analysis is purely
statistical: results are interpreted as correlations, not causal effects.

## Data

Cross-country indicators from the United Nations Data Retrieval System, focused on
2022 (the most recent year with good coverage). A few slow-moving indicators were
carried forward from earlier years where 2022 was missing. The links to all source
CSVs are listed in the report. Final sample: 104 countries.

The response variable (resident patent filings per million) is heavily
right-skewed, so it is modelled as `log(Patents + 1)`; population density is
similarly log-transformed.

## Methods

- Exploratory analysis: distributions, Box-Cox justification for the log transform,
  per-predictor scatter plots, externally studentized residuals to inspect
  high-leverage economies (Korea, China, Israel, Japan — kept, as their values are
  substantively meaningful).
- Model comparison: OLS vs three regularized linear estimators (Ridge, LASSO,
  Elastic Net) via `glmnet`, motivated by strong multicollinearity among predictors.
- Tuning: 10-fold cross-validation; for Elastic Net, the mixing parameter is also
  tuned over a grid.
- Evaluation: repeated random 80/20 splitting (Monte Carlo cross-validation,
  200 repetitions), comparing out-of-sample RMSE.
- Diagnostics on the OLS fit: Shapiro-Wilk (normality), Breusch-Pagan
  (heteroskedasticity), Q-Q and residual plots.
- A Welch two-sample t-test comparing patenting intensity between high- and
  low-urbanization countries.

## Main findings

- **Ridge regression** gave the most stable out-of-sample accuracy (lowest mean
  RMSE), outperforming OLS, LASSO, and Elastic Net in the presence of correlated
  predictors.
- R&D expenditure, number of researchers, and internet usage are the indicators
  most strongly associated with patenting intensity. Population density contributes
  comparatively little.
- Urbanization is associated with higher patenting in the raw data, though this
  comparison does not control for other covariates.

## Files

- `innovation-patents-r.R` — full analysis script.
- `innovation-patents-r.pdf` — written report with figures and discussion.

## How to run

Open the R script and install the required packages
(`MASS`, `dplyr`, `tidyr`, `ggplot2`, `ggrepel`, `glmnet`, `lmtest`, `conflicted`),
then download the UN CSVs linked in the report into the working directory.
