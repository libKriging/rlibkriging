## Submission

This is a bugfix update of rlibkriging (1.1-1), fixing a check timeout in the
previous submission (1.1-0). No user-visible feature changes.

The 1.1-0 check failed with 1 ERROR on r-devel-linux-x86_64-fedora-clang and
r-devel-linux-x86_64-fedora-gcc: `tests/test-NestedKriging.R` exceeded the
45-minute test time limit on these (apparently slower) workers, while passing
comfortably on all other 11 platforms (Linux Debian/patched/release, Windows,
macOS). The test itself was not failing logically; it was simply too costly
(it chains about ten `Kriging`/`NestedKriging` fits, each O(n^3) per BFGS
iteration). We have reduced the design/test sample sizes used in that test
file (see NEWS.md), cutting its runtime by roughly two orders of magnitude
while keeping the same (relative) assertions and coverage.

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
