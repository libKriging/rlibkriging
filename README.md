This repository is just a wrapper to emulate a "standard" R package from https://github.com/libKriging/bindings/R/rlibkriging content,
so you can install it using `install.packages('devtools'); devtools::install_github("libKriging/rlibkriging")`.

Requirements are 'cmake' and 'gfortran', which should be installed using:

  * Linux: `apt/yum/... install cmake gfortran`
  * OSX: `brew install cmake gfortran`
  * Windows:
    * install Rtools using https://cran.r-project.org/bin/windows/Rtools/rtools42/files/rtools42-5253-5107-signed.exe
    * `choco install cmake`
    or manually (even w/o admin rights) by unzipping https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2-windows-x86_64.zip and adding '.../cmake-*/bin' to your '%PATH%'


