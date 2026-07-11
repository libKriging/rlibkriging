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
