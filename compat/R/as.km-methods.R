##' Coerce an object into an object with S4 class \code{"km"} from the
##' \pkg{DiceKriging} package.
##'
##' Such a coercion is typically used to compare the performance of
##' the methods implemented in the current \pkg{rlibkriging} package to
##' those which are available in the \pkg{DiceKriging} package.
##'
##' @title Coerce an Object into a \code{km} Object
##'
##' @param x Object to be coerced.
##' @param ... Further arguments for methods.
##' @return An object with S4 class \code{"km"}.
##' 
##' @export 
as.km <- function(x, ...) {
    UseMethod("as.km")
}

#' Coerce a \code{Kriging} object into the \code{"km"} class of the
#' \pkg{DiceKriging} package.
#'
#' @author Yann Richet \email{yann.richet@asnr.fr}
#'
#' @param x An object with S3 class \code{"Kriging"}.
#' @param .call Force the \code{call} slot to be filled in the
#'     returned \code{km} object.
#' @param ... Not used.
#'
#' @return An object of having the S4 class \code{"KM"} which extends
#'     the \code{"km"} class of the \pkg{DiceKriging} package and
#'     contains an extra \code{Kriging} slot.
#'
#' @importFrom methods new
#' @importFrom stats model.matrix
#' @export
#' @method as.km Kriging
#' @aliases as.km,Kriging,Kriging-method
#' 
#' @examples
#' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
#' set.seed(123)
#' X <- as.matrix(runif(10))
#' y <- f(X)
#'
#' k <- Kriging(y, X, "matern3_2")
#' print(k)
#'
#' k_km <- as.km(k)
#' print(k_km)
as.km.Kriging <- function(x, .call = NULL, ...) {
    if (length(L <- list(...)) > 0) warnOnDots(L)
    ## loadDiceKriging()
    ## if (! "DiceKriging" %in% installed.packages())
    ##     stop("DiceKriging must be installed to use its wrapper from libKriging.")

    if (!requireNamespace("DiceKriging", quietly = TRUE))
        stop("Package \"DiceKriging\" not found")

    model <- new("KM")
    model@Kriging <- x

    if (is.null(.call))
        model@call <- match.call()
    else
        model@call <- .call

    m <- kriging_model(x)
    data <- data.frame(m$X)
    model@trend.formula <- regmodel2formula(m$regmodel)
    model@trend.coef <- as.numeric(m$beta)
    model@X <- m$X
    model@y <- m$y
    model@d <- ncol(m$X)
    model@n <- nrow(m$X)
    model@F <- m$F
    colnames(model@F) <- colnames(model.matrix(model@trend.formula,data))
    model@p <- ncol(m$F)
    model@noise.flag <- FALSE
    model@noise.var <- 0

    if (m$is_sigma2_estim)
      model@case <- "LLconcentration_beta_sigma2"
    else 
      model@case <- "LLconcentration_beta"

    isTrend = !m$is_beta_estim
    isCov = !m$is_theta_estim
    isVar = !m$is_sigma2_estim
    if (isCov) {
        known.covparam <- "All"
    } else {
        known.covparam <- "None"
    }
    model@param.estim <- NA
    model@method <- m$objective
    model@optim.method <- m$optim

    model@penalty <- list()
    model@lower <- 0
    model@upper <- Inf
    model@control <- list()

    model@gr <- FALSE

    model@T <- t(m$T) * sqrt(m$sigma2)
    model@z <- as.numeric(m$z) / sqrt(m$sigma2)
    model@M <- m$M / sqrt(m$sigma2)

    covStruct <-  new("covTensorProduct", d = model@d, name = m$kernel,
                      sd2 = m$sigma2, var.names = names(data),
                      nugget = 0, nugget.flag = FALSE, nugget.estim = FALSE,
                      known.covparam = known.covparam)

    if (isTrend && isCov && isVar) {
        model@known.param <- "All"
    } else if ((isTrend) && ((!isCov) || (!isVar))) {
        model@known.param <- "Trend"
    } else if ((!isTrend) && isCov && isVar) {
        model@known.param <- "CovAndVar"
    } else {    # In the other cases: All parameters are estimated (at this stage)
        model@known.param <- "None"
    }

    covStruct@range.names <- "theta"
    covStruct@paramset.n <- as.integer(1)
    covStruct@param.n <- as.integer(model@d)
    covStruct@range.n <- as.integer(model@d)
    covStruct@range.val <- as.numeric(m$theta)
    model@covariance <- covStruct

    return(model)
}

#' Coerce a \code{NuggetKriging} object into the \code{"km"} class of the
#' \pkg{DiceKriging} package.
#'
#' @author Yann Richet \email{yann.richet@asnr.fr}
#'
#' @param x An object with S3 class \code{"NuggetKriging"}.
#' @param .call Force the \code{call} slot to be filled in the
#'     returned \code{km} object.
#' @param ... Not used.
#'
#' @return An object of having the S4 class \code{"KM"} which extends
#'     the \code{"km"} class of the \pkg{DiceKriging} package and
#'     contains an extra \code{NuggetKriging} slot.
#'
#' @importFrom methods new
#' @importFrom stats model.matrix
#' @export
#' @method as.km NuggetKriging
#'
#' @examples
#' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
#' set.seed(123)
#' X <- as.matrix(runif(10))
#' y <- f(X) + 0.1 * rnorm(nrow(X))
#'
#' k <- NuggetKriging(y, X, "matern3_2")
#' print(k)
#'
#' k_km <- as.km(k)
#' print(k_km)
as.km.NuggetKriging <- function(x, .call = NULL, ...) {
    if (length(L <- list(...)) > 0) warnOnDots(L)
    ## loadDiceKriging()
    ## if (! "DiceKriging" %in% installed.packages())
    ##     stop("DiceKriging must be installed to use its wrapper from libKriging.")

    if (!requireNamespace("DiceKriging", quietly = TRUE))
        stop("Package \"DiceKriging\" not found")

    model <- new("NuggetKM")
    model@NuggetKriging <- x

    if (is.null(.call))
        model@call <- match.call()
    else
        model@call <- .call

    m <- nuggetkriging_model(x)
    data <- data.frame(m$X)
    model@trend.formula <- regmodel2formula(m$regmodel)
    model@trend.coef <- as.numeric(m$beta)
    model@X <- m$X
    model@y <- m$y
    model@d <- ncol(m$X)
    model@n <- nrow(m$X)
    model@F <- m$F
    colnames(model@F) <- colnames(model.matrix(model@trend.formula,data))
    model@p <- ncol(m$F)
    model@noise.flag <- FALSE
    model@noise.var <- 0

    model@case <- "LLconcentration_beta_v_alpha"

    isTrend = !m$is_beta_estim
    isCov = !m$is_theta_estim
    isVar = !m$is_sigma2_estim
    if (isCov) {
        known.covparam <- "All"
    } else {
        known.covparam <- "None"
    }
    model@param.estim <- NA
    model@method <- m$objective
    model@optim.method <- m$optim

    model@penalty <- list()
    model@lower <- 0
    model@upper <- Inf
    model@control <- list()

    model@gr <- FALSE

    model@T <- t(m$T) * sqrt(m$sigma2)
    model@z <- as.numeric(m$z) / sqrt(m$sigma2)
    model@M <- m$M / sqrt(m$sigma2)

    covStruct <-  new("covTensorProduct", d = model@d, name = m$kernel,
                      sd2 = m$sigma2, var.names = names(data),
                      nugget = m$nugget, nugget.flag = TRUE, nugget.estim = TRUE,
                      known.covparam = known.covparam)

    if (isTrend && isCov && isVar) {
        model@known.param <- "All"
    } else if ((isTrend) && ((!isCov) || (!isVar))) {
        model@known.param <- "Trend"
    } else if ((!isTrend) && isCov && isVar) {
        model@known.param <- "CovAndVar"
    } else {    # In the other cases: All parameters are estimated (at this stage)
        model@known.param <- "None"
    }

    covStruct@range.names <- "theta"
    covStruct@paramset.n <- as.integer(1)
    covStruct@param.n <- as.integer(model@d)
    covStruct@range.n <- as.integer(model@d)
    covStruct@range.val <- as.numeric(m$theta)
    model@covariance <- covStruct

    return(model)
}

#' Coerce a \code{NoiseKriging} object into the \code{"km"} class of the
#' \pkg{DiceKriging} package.
#'
#' @author Yann Richet \email{yann.richet@asnr.fr}
#'
#' @param x An object with S3 class \code{"NoiseKriging"}.
#' @param .call Force the \code{call} slot to be filled in the
#'     returned \code{km} object.
#' @param ... Not used.
#'
#' @return An object of having the S4 class \code{"KM"} which extends
#'     the \code{"km"} class of the \pkg{DiceKriging} package and
#'     contains an extra \code{NoiseKriging} slot.
#'
#' @importFrom methods new
#' @importFrom stats model.matrix
#' @export
#' @method as.km NoiseKriging
#' @aliases as.km,NoiseKriging,NoiseKriging-method
#'
#' @examples
#'f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
#'set.seed(123)
#'X <- as.matrix(runif(10))
#'y <- f(X) + X/10 * rnorm(nrow(X)) # add noise dep. on X
#'## fit and print
#'k <- NoiseKriging(y, noise=(X/10)^2, X, kernel = "matern3_2")
#'print(k)
#'
#' k_km <- as.km(k)
#' print(k_km)
as.km.NoiseKriging <- function(x, .call = NULL, ...) {
    if (length(L <- list(...)) > 0) warnOnDots(L)
    ## loadDiceKriging()
    ## if (! "DiceKriging" %in% installed.packages())
    ##     stop("DiceKriging must be installed to use its wrapper from libKriging.")

    if (!requireNamespace("DiceKriging", quietly = TRUE))
        stop("Package \"DiceKriging\" not found")

    model <- new("NoiseKM")
    model@NoiseKriging <- x

    if (is.null(.call))
        model@call <- match.call()
    else
        model@call <- .call

    m <- noisekriging_model(x)
    data <- data.frame(m$X)
    model@trend.formula <- regmodel2formula(m$regmodel)
    model@trend.coef <- as.numeric(m$beta)
    model@X <- m$X
    model@y <- m$y
    model@d <- ncol(m$X)
    model@n <- nrow(m$X)
    model@F <- m$F
    colnames(model@F) <- colnames(model.matrix(model@trend.formula,data))
    model@p <- ncol(m$F)
    model@noise.flag <- TRUE
    model@noise.var <- as.numeric(m$noise)

    model@case <- "LLconcentration_beta"

    isTrend = !m$is_beta_estim
    isCov = !m$is_theta_estim
    isVar = !m$is_sigma2_estim
    if (isCov) {
        known.covparam <- "All"
    } else {
        known.covparam <- "None"
    }
    model@param.estim <- NA
    model@method <- m$objective
    model@optim.method <- m$optim

    model@penalty <- list()
    model@lower <- 0
    model@upper <- Inf
    model@control <- list()

    model@gr <- FALSE

    model@T <- t(m$T) * sqrt(m$sigma2)
    model@z <- as.numeric(m$z) / sqrt(m$sigma2)
    model@M <- m$M / sqrt(m$sigma2)

    covStruct <-  new("covTensorProduct", d = model@d, name = m$kernel,
                      sd2 = m$sigma2, var.names = names(data),
                      nugget = 0, nugget.flag = FALSE, nugget.estim = FALSE,
                      known.covparam = known.covparam)

    if (isTrend && isCov && isVar) {
        model@known.param <- "All"
    } else if ((isTrend) && ((!isCov) || (!isVar))) {
        model@known.param <- "Trend"
    } else if ((!isTrend) && isCov && isVar) {
        model@known.param <- "CovAndVar"
    } else {    # In the other cases: All parameters are estimated (at this stage)
        model@known.param <- "None"
    }

    covStruct@range.names <- "theta"
    covStruct@paramset.n <- as.integer(1)
    covStruct@param.n <- as.integer(model@d)
    covStruct@range.n <- as.integer(model@d)
    covStruct@range.val <- as.numeric(m$theta)
    model@covariance <- covStruct

    return(model)
}
