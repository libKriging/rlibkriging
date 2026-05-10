## Deprecated compatibility wrapper — use KM(nugget.estim = TRUE) instead.

#' @title Create a KM object with nugget effect (deprecated)
#'
#' @description This is a thin compatibility wrapper. Use
#'     \code{\link{KM}(nugget.estim = TRUE)} directly instead.
#'
#' @param ... Arguments passed to \code{\link{KM}}.
#'
#' @return A \code{KM} object. See \code{\link{KM}}.
NuggetKM <- function(...) {
    .Deprecated("KM", msg = "NuggetKM() is deprecated. Use KM(nugget.estim = TRUE) instead.")
    KM(..., nugget.estim = TRUE)
}
