## Deprecated compatibility wrapper — use KM(noise.var = ...) instead.

#' @title Create a KM object with heteroscedastic noise (deprecated)
#'
#' @description This is a thin compatibility wrapper. Use
#'     \code{\link{KM}(noise.var = ...)} directly instead.
#'
#' @param ... Arguments passed to \code{\link{KM}}.
#' @param noise.var Numeric vector of known per-point noise variances.
#'
#' @return A \code{KM} object. See \code{\link{KM}}.
NoiseKM <- function(..., noise.var) {
    .Deprecated("KM", msg = "NoiseKM() is deprecated. Use KM(noise.var = ...) instead.")
    KM(..., noise.var = noise.var)
}
