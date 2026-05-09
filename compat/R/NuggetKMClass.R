## *****************************************************************************
## This file contains stuff related to the S4 class "NuggetKM" including its
## definition as a class extending "km" from the DiceKriging package.
## ****************************************************************************
    
#if (!requireNamespace("DiceKriging", quietly = TRUE)) {
#    stop("Package \"DiceKriging\" not found")
#}



## *****************************************************************************
#' Create an object of S4 class \code{"NuggetKM"} similar to a
#' \code{km} object in the \pkg{DiceKriging} package.
#' 
#' The class \code{"NuggetKM"} extends the \code{"km"} class of the
#' \pkg{DiceKriging} package, hence has all slots of \code{"km"}. It
#' also has an extra slot \code{"NuggetKriging"} slot which contains a copy
#' of the original object. 
#'
#' @title Create an \code{NuggetKM} Object
#' 
#' @author Yann Richet \email{yann.richet@asnr.fr}
#' 
#' @param formula R formula object to setup the linear trend in
#'     Universal NuggetKriging. Supports \code{~ 1}, ~. and \code{~ .^2}.
#'
#' @param design Data frame. The design of experiments.
#'
#' @param response Vector of output values.
#'
#' @param covtype Covariance structure. For now all the kernels are
#'     tensor product kernels.
#' 
#' @param coef.trend Optional value for a fixed vector of trend
#'     coefficients.  If given, no optimization is done.
#'
#' @param coef.cov Optional value for a fixed correlation range
#'     value. If given, no optimization is done.
#'
#' @param coef.var Optional value for a fixed variance. If given, no
#'     optimization is done.
#' 
#' @param nugget.estim,nugget Should nugget be estimated? (defaults TRUE) or given values.
#' 
#' @param noise.var Not implemented. 
#'
#' @param estim.method Estimation criterion. \code{"MLE"} for
#'     Maximum-Likelihood or \code{"LOO"} for Leave-One-Out
#'     cross-validation.
#' 
#' @param penalty Not implemented yet.
#'
#' @param optim.method Optimization algorithm used in the
#'     optimization of the objective given in
#'     \code{estim.method}. Supports \code{"BFGS"}.
#'
#' @param lower,upper Not implemented yet. 
#'
#' @param parinit Initial values for the correlation ranges which
#'     will be optimized using \code{optim.method}.
#'
#' @param multistart,control,gr,iso Not implemented yet. 
#'
#' @param scaling,knots,kernel, Not implemented yet. 
#'
#' @param ... Ignored.
#'
#' @return A \code{KM} object. See \bold{Details}.
#'
#' @seealso \code{\link[DiceKriging]{km}} in the \pkg{DiceKriging}
#'     package for more details on the slots.
#'
#' @export NuggetKM
#' @examples
#' # a 16-points factorial design, and the corresponding response
#' d <- 2; n <- 16
#' design.fact <- as.matrix(expand.grid(x1 = seq(0, 1, length = 4),
#'                                      x2 = seq(0, 1, length = 4)))
#' y <- apply(design.fact, 1, DiceKriging::branin) + rnorm(nrow(design.fact))
#' 
#' # Using `km` from DiceKriging and a similar `NuggetKM` object 
#' # kriging model 1 : matern5_2 covariance structure, no trend, no nugget effect
#' km1 <- DiceKriging::km(design = design.fact, response = y, covtype = "gauss",
#'                        nugget.estim=TRUE,
#'                        parinit = c(.5, 1), control = list(trace = FALSE))
#' KM1 <- NuggetKM(design = design.fact, response = y, covtype = "gauss",
#'           parinit = c(.5, 1))
#' 
NuggetKM <- function(formula = ~1, design, response,
               covtype = c("matern5_2", "gauss", "matern3_2", "exp"),
               coef.trend = NULL, coef.cov = NULL, coef.var = NULL,
               nugget = NULL, nugget.estim = TRUE, noise.var = NULL,
               estim.method = c("MLE", "LOO"), penalty = NULL,
               optim.method = "BFGS",
               lower = NULL, upper = NULL, parinit = NULL,
               multistart = 1, control = NULL,
               gr = TRUE, iso = FALSE, scaling = FALSE,
               knots = NULL, kernel = NULL,
               ...) {

    covtype <- match.arg(covtype)
    estim.method <- match.arg(estim.method)
    formula <- formula2regmodel(formula)

    ## get rid of unimplemented formals.
    if (!is.null(penalty)) {
        stop("The formal arg 'penalty' can not be used for now.")
    }
    if (!nugget.estim) {
        stop("The formal args 'nugget.estim=FALSE' ",
             "can only be used with KM()")
    }
    if (!is.null(nugget) || !is.null(noise.var)) {
        stop("The formal args 'nugget' and 'noise.var' ",
             "can not be used for now.")
    }
    if (!is.null(control) || !gr || iso) {
         stop("The formal args 'control', 'gr' ",
              "and 'iso' can not be used for now.")
    }
    if (scaling || !is.null(knots) || !is.null(kernel)) {
        stop("The formal args 'scaling', 'knots', 'kernel' ",
             "can not be used for now.")
    }

    ## check the design and response 
    if (!is.matrix(design)) design <- as.matrix(design)
    response <- as.matrix(response)
    if (!is.numeric(response) || (length(response) != nrow(design))) {
        stop("bad 'response'. Must be coercible to a numeric column ",
             "matrix with ", nrow(design), " rows")
    }
    
    if (estim.method == "MLE") estim.method <- "LL"
    else if (estim.method == "LOO") estim.method <- "LOO"
    
    if (optim.method != "BFGS")
        warning("Cannot setup optim.method ", optim.method,". Ignored.")

    ## Make the parameter list. These are coped by their name "sigma",
    ## 'theta' and 'beta'.
    
    parameters <- list()
    if (!is.null(coef.var))
        parameters <- c(parameters, list(sigma2 = coef.var, is_sigma2_estim=FALSE))
    if (!is.null(coef.cov)) {
        parameters <- c(parameters,
                        list(theta = matrix(coef.cov, ncol = ncol(design)), is_theta_estim=FALSE))
        optim.method <- "none"
        ## XXXY 
        warning("Since 'coef.cov' is provided 'optim.method' is set to ",
                "\"none\"")
    }  
    if (!is.null(coef.trend)) {
        parameters <- c(parameters, list(beta = matrix(coef.trend), is_beta_estim=FALSE))
    }
    if (!is.null(parinit)) {
        parameters <- c(parameters,
                        list(theta = matrix(parinit, ncol = ncol(design))))
    }
    if (!is.null(nugget)) {
        parameters <- c(parameters,
                        list(nugget = nugget))
    }
    if (length(parameters) == 0) parameters <- NULL
    
    # DiceKriging standard bounds for theta
    bounds_heuristic = optim_variogram_bounds_heuristic_used()
    optim_use_variogram_bounds_heuristic(FALSE)
    theta_lower_factor = optim_get_theta_lower_factor()
    if (is.null(lower)) lower = 1E-10
    optim_set_theta_lower_factor(lower)
    if (is.null(upper)) upper = 2.0
    theta_upper_factor = optim_get_theta_upper_factor()
    optim_set_theta_upper_factor(upper)

    if (multistart<=1) multistart=""
    r <- rlibkriging::Kriging(y = response, X = design, kernel = covtype,
                               noise = "nugget",
                              regmodel = formula,
                              normalize = FALSE,
                              objective = estim.method,
                              optim = paste0(optim.method, multistart),
                              parameters = parameters)
    
    # Back to previous setup
    optim_use_variogram_bounds_heuristic(bounds_heuristic)
    optim_set_theta_lower_factor(theta_lower_factor)
    optim_set_theta_upper_factor(theta_upper_factor)

    return(as.km.Kriging(r, .call = match.call()))
}

