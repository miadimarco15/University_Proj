# Binary Classification on Imbalanced Tabular Data

A supervised classification project comparing a Linear Support Vector Machine and a
Random Forest on a tabular dataset with numerical and categorical features, missing
values, and mild class imbalance (~60:40).

**Type:** Individual project.
**Language:** Python (scikit-learn).

## Goal

Build and compare two models for a binary classification task, with careful
attention to preprocessing, validation strategy, and a metric choice appropriate
for imbalanced classes.

## Data

A course-provided tabular dataset (numerical + categorical features, missing
values, hidden test set). **The dataset is not redistributable and is not included
in this repository.** The notebook is provided with outputs and figures
pre-rendered, so the full analysis is viewable without running it.

## Workflow

- **EDA:** target balance, numerical and categorical distributions, missing-value
  analysis, feature–target relationships, correlation structure.
- **Preprocessing pipeline:** median imputation for numerical features (robust to
  skew/outliers), most-frequent imputation for categoricals, standardization,
  one-hot encoding.
- **Validation:** stratified train/test split for a held-out set; stratified
  5-fold cross-validation for tuning. The test set is used only for final
  evaluation, never for model selection.
- **Metrics:** F1-score alongside accuracy, given the class imbalance.

## Models

- **Linear SVM:** baseline, then polynomial feature expansion, then L1
  regularization. Cross-validated F1 improved from ~0.71 (baseline) to ~0.90
  (polynomial degree 2 + L1), indicating meaningful non-linear interactions.
- **Random Forest:** tuned via randomized search; test F1 around 0.85–0.87.
- **Feature importance:** both models consistently surface the same two features as
  the most discriminative, agreeing with the EDA and with a shallow decision tree.

## Final model

A `LinearSVC` with L1 penalty, balanced class weights, polynomial degree 2, and a
cross-validated penalty `C`, selected for the highest performance across metrics.

## Note

The notebook includes an **LLM audit section** that critically documents how an LLM
was used during development, including its limitations — kept for transparency.

## Files

- `individual_proj_DiMarco.ipynb` — full notebook (with rendered outputs).
