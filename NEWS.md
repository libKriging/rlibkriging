# rlibkriging 1.2-2

Based on libKriging 1.2.2. Supersedes 1.2-1, which failed to install on CRAN
(the submitted `NAMESPACE` lacked `importFrom(DiceKriging, km)` and the
`KM` / `as.km` exports).

## Breaking changes

* The Vecchia objective introduced in 1.1-0 is renamed: `objective = "VLL"` /
  `"VLL(m)"` becomes `"LLVecchia"` / `"LLVecchia(m)"`. No alias is kept, so
  `"VLL(m)"` now raises `Unsupported fit objective`. Results are unchanged.

## New features

* New `LLNystrom(k)` objective: a fixed-landmark Nystrom low-rank
  approximation of the covariance for large designs, costing O(n k^2) per
  evaluation. The `$nystrom_rank()` accessor gives the rank of such a fit.
* New `subsetOfData()`: k-means (or random) pre-fit row subsetting for large
  designs (indices are 1-based).
* `WarpKriging` now has the same accessors as `Kriging`: `noise()`,
  `warp_params()`, `optim()`, `objective()` and `covMat(X1, X2)`. It also
  accepts numeric `parameters` seeds with `optim = "none"` (to rebuild a model
  with frozen hyper-parameters), and `update(..., noise_u =)` /
  `update_simulate(..., noise_u =)`. `noise =` and `parameters =` can now be
  used together.

## Fixes

* `predict(..., return_deriv = TRUE)` returned derivatives off by a factor `scaleX`
  when the model was fitted with `normalize = TRUE`.
* `WarpKriging`: the analytical warp-parameter gradient was wrong for every
  continuous warp, so the optimizer never found a non-trivial warp. Warpings
  that assume inputs in `[0, 1]` (`knots`, `kumaraswamy`, `boxcox`,
  `neural_mono`, `mlp`, `mlp_joint`) now rescale inputs from their training
  range; fits on inputs spanning exactly `[0, 1]` are unchanged.
* `optim = "none"` with a light Vecchia fit ignored the `LLVecchia(m)`
  objective.
* Faster `fit()`, `predict()` and above all `update(refit = FALSE)`: the
  inverse covariance matrix is now computed only when a gradient needs it.
* `simulate.WarpKriging` no longer self-qualifies with `:::`, `WarpKriging` is
  registered with `setOldClass` (no load-time warning), and the `save` / `load`
  examples remove their temporary file.
* Packaging: `NAMESPACE` no longer depends on `roxygen2` succeeding at build
  time, and hidden files of the bundled libKriging sources are no longer
  shipped.

# rlibkriging 1.1-1

## Fixes

* Shrink `test-NestedKriging.R` design/test sizes to avoid a check timeout on
  slow CRAN workers (e.g. `r-devel-linux-x86_64-fedora-*`, which exceeded the
  45-minute test time limit under 1.1-0).

# rlibkriging 1.1-0

## New features

* New `NestedKriging` class: a divide-and-conquer Gaussian process for large
  designs. The data are partitioned into groups, one `Kriging` submodel is
  fitted per group with a common prior, and predictions are aggregated with the
  optimal nested-kriging aggregation (`"NK"`, interpolating) or a
  product-of-experts rule (`"PoE"`, `"gPoE"`, `"BCM"`, `"rBCM"`).

* New Vecchia approximated log-likelihood objective for large designs: fit a
  `Kriging` model with `objective = "VLL(m)"` (or `"VLL"`, default `m = 30`),
  costing O(n m^3) per evaluation instead of O(n^3).

## Changes

* `Kriging()` / `fit()`: `objective` now also accepts `"VLL"` / `"VLL(m)"`, and
  `regmodel` now accepts `"quadratic"`.

* `Kriging()` / `fit()`: the `noise` argument has been moved to the **last**
  position, for consistency with `WarpKriging` and the other language bindings.
  Code that passes `noise` by name is unaffected; positional calls that relied
  on `noise` being the 4th argument must be updated.

## Fixes

* Fix a possible deadlock when forking after threads were created.
* Numerous build and portability fixes (Windows, macOS deployment target).
