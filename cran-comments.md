## Submission

This is a feature update of rlibkriging (1.1-0), updating the current CRAN
version 0.9-3. (Version 1.0-0 was a GitHub-only release and was not submitted
to CRAN.)

Main user-visible changes (see NEWS.md):

* new `NestedKriging` class (divide-and-conquer GP for large designs);
* new Vecchia approximated log-likelihood fit objective `"VLL(m)"`;
* `objective` also accepts `"VLL"`/`"VLL(m)"` and `regmodel` accepts
  `"quadratic"`; the `noise` argument of `Kriging()`/`fit()` moved to the last
  position (named calls are unaffected).

## Test environments

Tested via GitHub Actions and R-hub on:

* Ubuntu 22.04, R release, R-devel and R oldrel-1
* macOS (Apple Silicon), R release, R-devel and R oldrel-1
* Windows Server, R release, R-devel and R oldrel-1

using `R CMD check --as-cran`.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking installed package size ... NOTE
  installed size is ~40Mb (sub-directories `lib`, `include`, `libs`).

  rlibkriging bundles the 'libKriging' C++ library together with its C++
  dependencies (Armadillo and lbfgsb) as source and static libraries; the size
  comes entirely from these vendored components, as in the previous CRAN
  release. There is no run-time download.

## Reverse dependencies

There are no reverse dependencies on CRAN. <!-- please confirm before submitting -->
