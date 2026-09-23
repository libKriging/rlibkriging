## Submission

This is an update of rlibkriging to 1.2-2 (currently 1.1-1 on CRAN), based on
libKriging 1.2.2. See NEWS.md for the user-visible changes (a renamed
objective, new large-design methods and several numerical fixes).

It also fixes the installation error of the previous submission (1.2-1):
the submitted `NAMESPACE` lacked `importFrom(DiceKriging, km)` and the
`KM` / `as.km` exports, so installation failed with "no definition of
superclass km". `NAMESPACE` is now built without relying on roxygen2
succeeding at package-preparation time. The hidden files of the bundled
libKriging sources flagged by the same check are no longer shipped.

## Test environments

Tested locally (Ubuntu 24.04, R 4.6.1) and via GitHub Actions and R-hub on:

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
