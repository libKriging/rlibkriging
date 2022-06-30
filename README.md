This repository is just a wrapper to emulate a "standard" R package from https://github.com/libKriging/bindings/R/rlibkriging content,
so you can install it using:

```r
install.packages('devtools')
devtools::install_github("libKriging/rlibkriging")
```

Requirements are 'c++', 'cmake' and 'gfortran', which should be installed using:

  * Linux: `apt/yum/... install cpp cmake gfortran`
  * OSX: `brew install cpp cmake gfortran`
  * Windows: install Rtools using https://cran.r-project.org/bin/windows/Rtools/rtools42/files/rtools42-5253-5107-signed.exe


Note: this repository mainly contains modified Makefiles, inspired by https://github.com/astamm/nloptr wrapper for NLOpt.

