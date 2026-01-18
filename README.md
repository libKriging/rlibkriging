This repository is just a wrapper to emulate a "standard" R package
from https://github.com/libKriging/bindings/R/rlibkriging content,
so you can install it just using:

```r
install.packages('devtools')
devtools::install_github("libKriging/rlibkriging")

# Or install a specific tagged version
devtools::install_github("libKriging/rlibkriging@0.9-3")
```

**Note:** When installing via `install_github()`, the package automatically initializes git submodules (`src/libK`, `src/slapack`) at the correct versions using the pinned commits recorded in `.gitmodules-shas`. This ensures you get the exact versions of dependencies that were used when the release was tagged.

The stable version is available from CRAN [![Downloads
(monthly)](https://cranlogs.r-pkg.org/badges/rlibkriging)](https://cran.r-project.org/package=rlibkriging) :

```r
install.packages('rlibkriging')
```


## Requirements

* `c++` and `cmake`, should be installed using:
  * Linux/OSX: `brew/apt/yum/... install cpp cmake`
  * Windows: install Rtools (see https://cran.r-project.org/bin/windows/Rtools/)
    Note:
      * R>=4.2 & Rtools>=42 are required for this 'devtools::install_github'
      * for older R/Rtools, refer to manual install: https://github.com/libKriging/libKriging#compilation-for-linuxmacwindows-using-r-toolchain

Note: this repository mainly contains modified Makefiles, inspired by https://github.com/astamm/nloptr wrapper.

## CRAN

When submitting to CRAN, `./tools/setup.sh` should be run before `R CMD build rlibkriging` to fit CRAN policy.

## Submodule Version Management

For maintainers: when updating submodules, always run `./tools/update_submodule_shas.sh` to record the new commit SHAs. This ensures users who install via `install_github()` get the correct submodule versions. See `SUBMODULE_VERSION_MANAGEMENT.md` for details.
