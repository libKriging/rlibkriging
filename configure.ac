## -*- mode: autoconf; autoconf-indentation: 4; -*-
##
##  rlibkriging configure.ac
##
##  rlibkriging -- R interface to libKriging
##
##  Copyright (C) 2014-2022  Dirk Eddelbuettel
##
## This file is licensed under the GPL-2 or later just like most of my
## Open Source code, and is granted an exemption (should it be needed)
## for inclusion into rlibkriging

# require at least autoconf 2.61
AC_PREREQ([2.69])
AC_INIT([rlibkriging],[0.6.0])

## Set R_HOME, respecting an environment variable if set
: ${R_HOME=$(R RHOME)}
if test -z "${R_HOME}"; then
   AC_MSG_ERROR([Could not determine R_HOME.])
fi

CXX=`"${R_HOME}/bin/R" CMD config CXX`
if test -z "${CXX}"; then
    AC_MSG_ERROR([No C++ compiler available])
fi
CXXFLAGS=`"${R_HOME}/bin/R" CMD config CXXFLAGS`
CPPFLAGS=`"${R_HOME}/bin/R" CMD config CPPFLAGS`
CXX11FLAGS=`"${R_HOME}/bin/R" CMD config CXX11FLAGS`
AC_LANG(C++)
AC_REQUIRE_CPP
AC_PROG_CXX

## Default to build from source
need_to_build="yes"

## But: Can we use pkg-config?
AC_PATH_PROG(have_pkg_config, pkg-config, no)
## If yes, also check for whether pkg-config knows libkriging
if test x"${have_pkg_config}" != x"no"; then
    AC_MSG_CHECKING([if pkg-config knows libKriging])
    if pkg-config --exists libkriging; then
        AC_MSG_RESULT([yes])
        ## Since libkriging has been found, test for minimal version requirement
        AC_MSG_CHECKING([for pkg-config checking libKriging version])
        if pkg-config --atleast-version=0.6.0 libkriging; then
            AC_MSG_RESULT([>= 0.6.0])
            libkriging_include=$(pkg-config --cflags libkriging)
            libkriging_libs=$(pkg-config --libs libkriging)
            AC_SUBST([libKriging_INCLUDE], "${libkriging_include}")
            AC_SUBST([libKriging_LIBS],    "${libkriging_libs}")
            need_to_build="no"
        else
            AC_MSG_RESULT([insufficient: libKriging 0.6.0 or later is preferred.])
        fi
    else
        AC_MSG_RESULT([no])
    fi
fi

## So do we need to build
if test x"${need_to_build}" != x"no"; then
    AC_PATH_PROG(have_cmake, cmake, no)
    if test x"${have_cmake}" == x"no"; then
       . inst/scripts/cmake_config.sh
       if test -z "${CMAKE_BIN}"; then
          ## also error to end configure here
          AC_MSG_ERROR([Could not find 'cmake'.])
       fi
    fi
    ## 'uname -m' on M1 give x86_64 which is ... not helping
    machine=`"${R_HOME}/bin/Rscript" -e 'cat(Sys.info()[["machine"]])'`
    AC_MSG_RESULT([using libKriging via local cmake build on ${machine} ])
    inst/scripts/build.sh
    ## build.sh installs into libkriging/lib, headers are copied
    libkriging_include="-include "libKriging/utils/lkalloc.hpp" -DARMA_ALIEN_MEM_ALLOC_FUNCTION=lkalloc::malloc -DARMA_ALIEN_MEM_FREE_FUNCTION=lkalloc::free"
    libkriging_libs="-lKriging -larmadillo -llbfgsb"
    #"../inst/libKriging/build/installed/lib/libKriging.a ../inst/libKriging/build/installed/lib/libarmadillo.a ../inst/libKriging/build/installed/lib/liblbfgsb.a"
fi

## Now use all the values
#AC_SUBST([libKriging_CPPFLAGS],["$libkriging_include"])
#AC_SUBST([libKriging_LIBS],["$libkriging_libs"])
#AC_CONFIG_FILES([src/Makevars])
#AC_OUTPUT

AC_OUTPUT([src/Makevars])
