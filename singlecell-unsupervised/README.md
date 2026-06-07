 Unsupervised Analysis of Single-Cell RNA-seq under Hypoxia

An unsupervised study of single-cell gene expression in two breast cancer cell
lines (HCC1806 and MCF7) under hypoxia vs normoxia, asking whether the experimental
condition is recoverable from the data without using the labels.

**Type:** Individual project.
**Language:** Python.

## Data

Raw single-cell gene expression counts (Smart-seq), quality-filtered and reduced to
the 3000 most informative genes per cell line. **The single-cell datasets are not
redistributable and are not included in this repository.** The notebook is provided
with all outputs and figures pre-rendered, so the full analysis is viewable without
running it; the expected data format is documented in Section 1.

The hypoxia gene signature used for enrichment is the Buffa hypoxia metagene, loaded
from the public MSigDB resource (no hardcoded gene lists).

## Pipeline

- **Preprocessing:** CP10K normalization + `log1p`, motivated by varying library
  sizes across cells. Gene-level feature selection (lowly-expressed filtering,
  highly-variable genes) is explored but deliberately *not* applied, and labelled as
  such, to keep the pipeline honest at this dataset size.
- **Co-expression analysis:** Spearman correlation hubs + over-representation
  analysis (Fisher exact test with Benjamini-Hochberg FDR) to test, quantitatively,
  whether hypoxia is encoded in the co-expression structure.
- **Dimensionality reduction:** PCA (60 components) as the clustering space; t-SNE
  and UMAP for visualization only.
- **Clustering:** K-means and hierarchical (Ward) clustering, each run on PCA,
  t-SNE, and UMAP spaces; number of clusters chosen via elbow + silhouette.
- **External validation:** clusterings compared to the true condition labels using
  NMI and ARI (labels never used during fitting).
- **Biological interpretation:** marker genes per cluster via Mann-Whitney U
  (one-vs-rest) with FDR correction, visualized as heatmaps.

## Main result

The two cell lines show **opposite regimes**. MCF7 has a strong, essentially linear
condition structure — K-means on PCA separates hypoxia from normoxia almost
perfectly (NMI ~ 0.97). HCC1806 fails on PCA but is recovered on the non-linear UMAP
embedding, indicating genuinely non-linear structure. The co-expression analysis
further shows that the dominant gene modules are organized by proliferation /
cell-cycle rather than by hypoxia.

## Methodology notes

The notebook is explicit about good practice throughout: separating exploratory
steps from applied ones, fitting a separate scaler per dataset to avoid leakage, and
testing visual impressions quantitatively rather than asserting them.

## Files

- `UnsupervisedAnalysis_final_7.ipynb` — full notebook (with rendered outputs).

