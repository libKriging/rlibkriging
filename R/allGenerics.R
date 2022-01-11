
## True generic
setGeneric(name = "logLikelihood",
           def = function(object, ...) standardGeneric("logLikelihood"))

setGeneric(name = "logMargPost",
           def = function(object, ...) standardGeneric("logMargPost"))

setGeneric(name = "leaveOneOut",
           def = function(object, ...) standardGeneric("leaveOneOut"))

##' Coerce an object into an object with S4 class \code{"km"} from the
##' DiceKriging package.
##'
##' Such a coercion is typically used to compare the performance of
##' the methods implemented in the current rlibkriging package to
##' those which are available in the DiceKriging package.
##'
##' @title Coerce an Object into a \code{km} Object
##' @param x An object to be coerced.
##' @param ... Further arguments for methods.
##' @return An object with S4 class \code{"km"}.
##' @export 
as.km <- function(x, ...) {
    UseMethod("as.km")
}

##' Compute model leave-One-Out error at given args
##'
##' @title Compute Leave-One-Out.
##' 
##' @param object An object representing a fitted model.
##'
##' @param ... Further arguments for methods.
##'
##' @return The Leave-One-Out sum of squares.
##' @export
leaveOneOut <- function (object, ...) {
    UseMethod("leaveOneOut")
}
## setMethod("leaveOneOut", "Kriging", leaveOneOut.Kriging)

##' Compute model log-Likelihood at given args
##'
##' @title Compute Log-Likelihood.
##'
##' @param object An object representing a fitted model.
##' 
##' @param ... Further arguments for methods.
##'
##' @return The log-likelihood.
##' @export
logLikelihood <- function (object, ...) {
    UseMethod("logLikelihood")
}

#' Compute model log-Marginal Posterior at given args
##'
##' @title Compute log-Marginal Posterior.
##'
##' @param object An object representing a fitted model.
##' 
##' @param ... Further arguments for methods.
##'
##' @return The log-marginal posterior.
##' @export
logMargPost <- function (object, ...) {
    UseMethod("logMargPost")
}
