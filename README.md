This repository is just a wrapper to emulate a "standard" R package from https://github.com/libKriging/bindings/R/rlibkriging content,
so you can install it using:

```r
install.packages('devtools')
devtools::install_github("libKriging/rlibkriging")
```

Requirements are 'c++', 'cmake' and 'gfortran', which should be installed using:

  * Linux: `apt/yum/... install cpp cmake gfortran`
  * OSX: `brew install cpp cmake gfortran`
  * Windows:
    * 'c++' & 'gfortran': install Rtools using https://cran.r-project.org/bin/windows/Rtools/rtools42/files/rtools42-5253-5107-signed.exe
    * 'cmake': `choco install cmake` \
    or manually (even w/o admin rights) by unzipping https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2-windows-x86_64.zip \
    and then adding '.../cmake-*/bin' to your '%PATH%'


