#!/usr/bin/env Rscript
#
# Post-copy tweaks to the R binding sources that tools/setup.sh copies from
# src/libK/bindings/R/rlibkriging/R.  Ported verbatim (same behaviour) from the
# former inline `python3` heredocs in tools/setup.sh so that setup.sh depends
# only on R -- always available when building an R package -- and not on a
# python3 interpreter that minimal build images (e.g. rocker/r-ver) lack.
#
# All changes here are cosmetic (R CMD check NOTEs / example file cleanup); none
# of them affect the compiled bindings or NAMESPACE.
#
#   1. R/zzz.R
#      - drop the `rlibkriging:::` self-qualifier on simulate.WarpKriging
#        (R CMD check NOTE: there are ":::" calls to the package's namespace)
#      - insert methods::setOldClass("WarpKriging") immediately before the
#        setMethod("simulate", "WarpKriging", ...) call, so the S3 class is
#        registered in the dispatch context and startup no longer warns
#        'no definition for class "WarpKriging"'
#   2. R/*KrigingClass.R
#      - append `#' unlink(outfile)` after the last line of each roxygen block
#        that passes `outfile` to a function, so run examples leave no file
#        behind.  Only the last use in the block is annotated, so an earlier
#        save(k, outfile) / load.Kriging(outfile) pair still works.

## --- 1. R/zzz.R -----------------------------------------------------------------
zzz <- "R/zzz.R"
if (file.exists(zzz)) {
  x <- readLines(zzz, warn = FALSE)

  # Fix 1: in-package code needs no ::: qualifier
  x <- gsub("rlibkriging:::simulate.WarpKriging", "simulate.WarpKriging",
            x, fixed = TRUE)

  # Fix 2: setOldClass("WarpKriging") just before the setMethod() call.
  # Match the two-line shape:
  #       methods::setMethod(
  #         "simulate", "WarpKriging",
  hit <- which(
    x == "      methods::setMethod(" &
      c(startsWith(x[-1], '        "simulate", "WarpKriging",'), FALSE)
  )
  # insert back-to-front so earlier indices stay valid; skip if already present
  for (i in rev(hit)) {
    if (i > 1L && grepl("setOldClass", x[i - 1L], fixed = TRUE)) next
    x <- append(x, '      methods::setOldClass("WarpKriging")', after = i - 1L)
  }

  writeLines(x, zzz)
  message("  ✓ zzz.R patched")
}

## --- 2. R/*KrigingClass.R -----------------------------------------------------
for (f in Sys.glob("R/*KrigingClass.R")) {
  lines <- readLines(f, warn = FALSE)
  out <- character(0)
  for (i in seq_along(lines)) {
    out <- c(out, lines[i])
    # skip the line we may have inserted on an earlier run, so re-running is a
    # no-op (the original python heredoc was not idempotent)
    if (grepl("#' .*[,(]outfile", lines[i]) &&
        !grepl("unlink(outfile)", lines[i], fixed = TRUE)) {
      has_later <- FALSE
      j <- i + 1L
      while (j <= length(lines) && startsWith(lines[j], "#'")) {
        if (grepl("outfile", lines[j], fixed = TRUE)) {
          has_later <- TRUE
          break
        }
        j <- j + 1L
      }
      if (!has_later) out <- c(out, "#' unlink(outfile)")
    }
  }
  writeLines(out, f)
}
message("  ✓ documentation cleanup added")
