# Ames House Prices — Regression with Feature Engineering

Predicting house sale prices on the Ames Housing dataset, with an emphasis on
extensive, domain-driven feature engineering feeding a regularized linear model.

**Type:** Individual project.
**Language:** Python (scikit-learn).

## Data

The [Ames Housing dataset](https://www.kaggle.com/c/house-prices-advanced-regression-techniques)
(also available on [OpenML](https://www.openml.org/d/42165)) — a public dataset of
residential property sales with ~80 features. Publicly available, so it can be
downloaded directly from the links above.

The target (`SalePrice`) is right-skewed and modelled as `log1p(SalePrice)`.

## Approach

The core of the project is a **custom scikit-learn transformer** (`fit`/`transform`)
that performs:

- Missing-value handling tailored to the domain (e.g. `None`/`0` for features where
  absence is meaningful, neighborhood-median imputation for `LotFrontage`).
- Domain-driven engineered features: house/remodel/garage age, total surface area,
  an outdoor score, total bathrooms, simplified basement and exterior categories.
- Data-driven feature selection: dropping near-constant columns, multicollinearity
  reduction, and target-correlation filtering.

The engineered features feed a regularized linear model — **LassoCV** and
**ElasticNetCV** — chosen for built-in feature selection in a high-dimensional,
correlated space.

## A note on target leakage (honest disclosure)

Some preprocessing steps use the target during `fit`: target-correlation-based
feature selection and target-mean encoding (`NeighborhoodScore`). Because these live
inside a transformer whose `fit` only sees training-fold data, the risk is largely
contained when run inside a cross-validation pipeline — but it is not fully
eliminated (e.g. the mean encoding has no out-of-fold scheme or smoothing). This is
flagged openly in the notebook. A production-grade version would move all
target-dependent steps strictly inside the CV folds and use out-of-fold/smoothed
target encoding.

## Files

- `DiMarco_ames_notebook.ipynb` — full notebook (with rendered outputs).

## How to run

Install `scikit-learn`, `pandas`, `numpy`, `matplotlib`, download the dataset from
the link above, and update the file paths at the top of the notebook.
