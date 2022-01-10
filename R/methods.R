
##' Build a \code{"Kriging"} Object using \bold{libKriging}
##'
##' The hyper-parameters (variance and vector of correlation ranges)
##' are estimated thanks to the optimization of a criterion given by
##' \code{objective}, using the method given in \code{optim}.
##' 
##' @author Yann Richet <yann.richet@irsn.fr>
##' 
##' @param y Array of response values. XXX vector?
##'
##' @param X Numeric matrix of input design.
##'
##' @param kernel Character defining the covariance model:
##'     \code{"gauss"}, \code{"exp"}, ... See XXX.
##'
##' @param regmodel Universal Kriging linear trend.
##'
##' @param normalize Logical. If \code{TRUE} both the input matrix
##'     \code{X} and the response \code{y} in normalized to take
##'     values in the interval \eqn{[0, 1]}.
##'
##' @param optim Character giving the Optimization method used to fit
##'     hyper-parameters. Possible values are: \code{"BFGS"},
##'     \code{"Newton"} which uses both the gradietn and the Hessian
##'     of the objective, and \code{"none"} which simply keeps the
##'     values given in \code{parameters}.
##'
##' @param objective Character giving the bjective function to
##'     optimize. Possible values are: \code{"LL"} for the
##'     log-Likelihood, \code{"LOO"} for the leave-one-out sum of
##'     squares (XXX) \code{"LMP"} for the log Marginal Posterior.
##' 
##' @param parameters Initial values for the hyper-parameters. When
##'     provided this must be named list with elements \code{"sigma2"}
##'     and \code{"theta"} containing the initial value(s) for the
##'     variance and for the range parameters. If \code{theta} is a
##'     matrix with more than one row, each row is used as a starting
##'     point for optimization.
##' 
##' @return An object with S3 class \code{"Kriging"}. Should be used
##'     with its \code{predict}, \code{simulate}, \code{update}
##'     methods.
##' 
##' @export
##' @useDynLib rlibkriging, .registration=TRUE
##' @importFrom Rcpp sourceCpp
##'
##' @examples
##' X <- as.matrix(c(0.0, 0.25, 0.5, 0.75, 1.0))
##' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
##' y <- f(X)
##' ## fit and print
##' (k_R <- Kriging(y, X, kernel = "gauss"))
##' 
##' x <- as.matrix(seq(from = 0, to = 1, length.out =100))
##' p <- predict(k_R, newdata = x, TRUE, FALSE)
##' plot(f)
##' points(X, y)
##' lines(x, p$mean, col = 'blue')
##' polygon(c(x, rev(x)), c(p$mean - 2 * p$stdev, rev(p$mean + 2 * p$stdev)),
##'         border = NA, col = rgb(0, 0, 1, 0.2))
##' s <- simulate(k_R, nsim = 10, seed = 123, x = x)
##' plot(f)
##' points(X,y)
##' matlines(x, s, col = rgb(0, 0, 1, 0.2), type = 'l', lty = 1)
##' k_R <- Kriging(y, X, "gauss")
##' print(k_R)
Kriging <- function(y, X, kernel,
                    regmodel = c("constant", "linear", "interactive"),
                    normalize = FALSE,
                    optim = c("BFGS", "Newton", "none"),
                    objective = c("LL", "LOO", "LMP"),
                    parameters = NULL) {

    regmodel <- match.arg(regmodel)
    objective <- match.arg(objective)
    optim <- match.arg(optim)
    new_Kriging(y = y, X = X, kernel = kernel,
                regmodel = regmodel,
                normalize = normalize,
                optim = optim,
                objective = objective,
                parameters = parameters)
    
} 

##' Coerce a \code{Kriging} Object into a List
##'
##' @author Yann Richet \email{yann.richet@irsn.fr}
##' 
##' @param x An object with class \code{"Kriging"}.
##' @param ... Ignored
##'
##' @return A list with its elements copying the content of the
##'     \code{Kriging} object fields: \code{kernel}, \code{optim},
##'     \code{objective}, \code{theta} (vector of ranges),
##'     \code{sigma2} (variance), \code{X}, \code{centerX},
##'     \code{scaleX}, \code{y}, \code{centerY}, \code{scaleY},
##'     \code{regmodel}, \code{F}, \code{T}, \code{M}, \code{z},
##'     \code{beta}.
##' 
##' @export as.list
##' @method as.list Kriging
##' @aliases as.list,Kriging,Kriging-method
##' @examples
##' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x ) + 2 * cos(7 * x) * x^5 + 0.7)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' r <- Kriging(y, X, kernel = "gauss")
##' l <- as.list(r)
##' cat(paste0(names(l), " =" , l, collapse = "\n"))
as.list.Kriging <- function(x, ...) {
    if (length(L <- list(...)) > 0) warnOnDots(L)
    kriging_model(x)
}

setMethod("as.list", "Kriging", as.list.Kriging)


##' Print Kriging object content
##'
##' @author Yann Richet (yann.richet@irsn.fr)
##'
##' @param x S3 Kriging object
##' @param ... Ignored
##'
##' @return NULL
##'
##' @method print Kriging
##' @export print
##' @aliases print,Kriging,Kriging-method
##' @examples
##' f = function(x) 1-1/2*(sin(12*x)/(1+x)+2*cos(7*x)*x^5+0.7)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' r <- Kriging(y, X, "gauss")
##' print(r)
print.Kriging <- function(x, ...) {
    
    if (length(L <- list(...)) > 0) warnOnDots(L)
    k <- kriging_model(x)
    p <- "Kriging model:\n"
    p <-  paste0(p,"\n  * data: ", paste0(collapse = " x ", dim(k$X)), " -> ",
                 paste0(collapse =" x ", dim(k$y)))
    p <- paste0(p,"\n  * trend ", k$regmodel, ifelse(k$estim_beta," (est.)",""),
                ": ", paste0(collapse = ",", k$beta))
    ##,"(",paste0(collapse=",",k$F),")")
    p <- paste0(p,"\n  * variance", ifelse(k$estim_sigma2," (est.)", ""),
                ": ", k$sigma2)
    p <- paste0(p,"\n  * covariance:")
    p <- paste0(p,"\n    * kernel: ", k$kernel)
    p <- paste0(p,"\n    * range", ifelse(k$estim_theta, " (est.)", ""),
                ": ", paste0(collapse = ", ", k$theta))
    p <- paste0(p,"\n    * fit: ")
    p <- paste0(p,"\n      * objective: ", k$objective)
    p <- paste0(p,"\n      * optim: ", k$optim)
    p <- paste0(p,"\n")
    cat(p)
    ## return(p)
}

setMethod("print", "Kriging", print.Kriging)

##' Predict Kriging Model at Given Points
##' 
##' @author Yann Richet (yann.richet@irsn.fr)
##' 
##' @param object S3 Kriging object
##' 
##' @param x points in model input space where to predict
##'
##' @param stdev return also standard deviation (default TRUE)
##'
##' @param cov return covariance matrix between x points (default FALSE)
##'
##' @param ... Ignored
##'
##' @return list containing: mean, stdev, cov
##'
##' @importFrom stats predict
##' @method predict Kriging
##' @export predict
##' @aliases predict,Kriging,Kriging-method
##' 
##' @examples
##' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
##' plot(f)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' points(X, y, col = 'blue')
##' r <- Kriging(y, X, "gauss")
##' x <-seq(from = 0, to = 1, length.out = 101)
##' p_x <- predict(r, x)
##' lines(x, p_x$mean, col = 'blue')
##' lines(x, p_x$mean - 2 * p_x$stdev, col = 'blue')
##' lines(x, p_x$mean + 2 * p_x$stdev, col = 'blue')
predict.Kriging <- function(object, x, stdev = TRUE, cov = FALSE, ...) {
    if (length(L <- list(...)) > 0) warnOnDots(L)
    k <- kriging_model(object) 
    if (!is.matrix(x)) x <- matrix(x, ncol = ncol(k$X))
    if (ncol(x) != ncol(k$X))
        stop("Input x must have ", ncol(k$X), " columns (instead of ",
             ncol(x),")")
    return(kriging_predict(object, x, stdev, cov))
}

## predict <- function (...) UseMethod("predict")
## setMethod("predict", "Kriging", predict.Kriging)


##' Simulate (conditional) Kriging model at given points
##' 
##' @author Yann Richet (yann.richet@irsn.fr)
##' 
##' @param object S3 Kriging object
##' @param nsim number of simulations to perform
##' @param seed random seed used
##' @param x points in model input space where to simulate
##' @param ... Ignored
##'
##' @return length(x) x nsim matrix containing simulated path at x points
##'
##' @importFrom stats simulate runif
##' @method simulate Kriging
##' @export simulate
##' @aliases simulate,Kriging,Kriging-method
##' 
##' @examples
##' f <- function(x) 1-1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
##' plot(f)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' points(X, y, col = 'blue')
##' r <- Kriging(y, X, kernel = "gauss")
##' x <- seq(from = 0, to = 1, length.out = 101)
##' s_x <- simulate(r, nsim = 3, x = x)
##' lines(x, s_x[ , 1], col = 'blue')
##' lines(x, s_x[ , 2], col = 'blue')
##' lines(x, s_x[ , 3], col = 'blue')
simulate.Kriging <- function(object, nsim = 1, seed = 123, x,  ...) {
    if (length(L <- list(...)) > 0) warnOnDots(L)
    k <- kriging_model(object) 
    if (!is.matrix(x)) x = matrix(x, ncol = ncol(k$X))
    if (ncol(x) != ncol(k$X))
        stop("Input x must have ", ncol(k$X), " columns (instead of ",
             ncol(x),")")
    ## XXXY
    if (is.null(seed)) seed <- floor(runif(1) * 99999)
    return(kriging_simulate(object, nsim = nsim, seed = seed, X = x))
}

## simulate <- function (...) UseMethod("simulate")
setMethod("simulate", "Kriging", simulate.Kriging)

##' Update \code{Kriging} model with new points
##' 
##' @author Yann Richet (yann.richet@irsn.fr)
##' 
##' @param object S3 Kriging object
##' @param newy new points in model output space.
##' @param newX new points in model input space.
##' @param normalize Logical. Normalize \code{X} and \code{y} in \eqn{[0,1]}.
##' @param ... Ignored
##' 
##' @importFrom stats update
##' @method update Kriging
##' @export update
##' @aliases update,Kriging,Kriging-method
##' 
##' @examples
##' f <- function(x) 1-1/2*(sin(12*x)/(1+x)+2*cos(7*x)*x^5+0.7)
##' plot(f)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' points(X, y, col='blue')
##' r <- Kriging(y, X, "gauss")
##' x = seq(0,1,,101)
##' p_x = predict(r, x)
##'   lines(x,p_x$mean,col='blue')
##'   lines(x,p_x$mean-2*p_x$stdev,col='blue')
##'   lines(x,p_x$mean+2*p_x$stdev,col='blue')
##' newX <- as.matrix(runif(3))
##' newy <- f(newX)
##'   points(newX,newy,col='red')
##' update(r,newy,newX)
##' x = seq(0,1,,101)
##' p2_x = predict(r, x)
##'   lines(x,p2_x$mean,col='red')
##'   lines(x,p2_x$mean-2*p2_x$stdev,col='red')
##'   lines(x,p2_x$mean+2*p2_x$stdev,col='red')
##' 
update.Kriging <- function(object, newy, newX, normalize = FALSE, ...) {
    
  if (length(L <- list(...)) > 0) warnOnDots(L)
  k <- kriging_model(object) 
  if (!is.matrix(newX)) newX <- matrix(newX, ncol = ncol(k$X))
  if (!is.matrix(newy)) newy <- matrix(newy, ncol = ncol(k$y))
  if (ncol(newX) != ncol(k$X))
      stop("Object 'newX' must have ", ncol(k$X), " columns (instead of ",
           ncol(newX), ")")
  if (nrow(newy) != nrow(newX))
      stop("Objects 'newX' and 'newy' must have the same number of rows.")
  kriging_update(object, newy, newX, normalize = normalize)
}

## update <- function(...) UseMethod("update")
## setMethod("update", "Kriging", update.Kriging)
## setGeneric(name = "update", def = function(...) standardGeneric("update"))


##' Compute log-Likelihood of Kriging model
##' 
##' @author Yann Richet (yann.richet@irsn.fr)
##' 
##' @param object S3 Kriging object
##' @param theta range parameters to evaluate
##' @param grad return Gradient ? (default is TRUE)
##' @param hess return Hessian ? (default is FALSe)
##'
##' @return log-Likelihood computed for given theta
##' 
##' @method logLikelihood Kriging
##' @export logLikelihood
##' @aliases logLikelihood,Kriging,Kriging-method
##' 
##' @examples
##' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' r <- Kriging(y, X, kernel = "gauss")
##' print(r)
##' ll <- function(theta) logLikelihood(r, theta)$logLikelihood
##' t <- seq(from = 0.0001, to = 2, length.out = 101)
##' plot(t, ll(t), type = 'l')
##' abline(v = as.list(r)$theta, col = 'blue')
##' 
logLikelihood.Kriging <- function(object, theta, grad = FALSE, hess = FALSE) {
  k <- kriging_model(object) 
  if (!is.matrix(theta)) theta <- matrix(theta, ncol = ncol(k$X))
  if (ncol(theta) != ncol(k$X))
      stop("Input theta must have ", ncol(k$X), " columns (instead of ",
           ncol(theta),")")
  out <- list(logLikelihood = matrix(NA, nrow = nrow(theta)),
              logLikelihoodGrad = matrix(NA,nrow=nrow(theta), ncol = ncol(theta)),
              logLikelihoodHess = array(NA,c(nrow(theta), ncol(theta), ncol(theta))))
  for (i in 1:nrow(theta)) {
      ll <- kriging_logLikelihood(object, theta[i, ],
                                  grad = isTRUE(grad), hess = isTRUE(hess))
      out$logLikelihood[i] <- ll$logLikelihood
      if (isTRUE(grad)) out$logLikelihoodGrad[i, ] <- ll$logLikelihoodGrad
      if (isTRUE(hess)) out$logLikelihoodHess[i, , ] <-  ll$logLikelihoodHess
  }
  if (!isTRUE(grad)) out$logLikelihoodGrad <- NULL
  if (!isTRUE(hess)) out$logLikelihoodHess <- NULL
  return(out)
}

##' Compute Model log-Likelihood at Given Args
##'
##' @param ... args
##'
##' @return log-Likelihood
##' @export
logLikelihood <- function (...) UseMethod("logLikelihood")
setMethod("logLikelihood", "Kriging", logLikelihood.Kriging)
setGeneric(name = "logLikelihood",
           def = function(...) standardGeneric("logLikelihood"))


##' Compute leave-One-Out of Kriging model
##' 
##' @author Yann Richet (yann.richet@irsn.fr)
##' 
##' @param object S3 Kriging object
##' @param theta range parameters to evaluate
##' @param grad return Gradient ? (default is TRUE)
##'
##' @return leave-One-Out computed for given theta
##' 
##' @method leaveOneOut Kriging
##' @export leaveOneOut
##' @aliases leaveOneOut,Kriging,Kriging-method
##' 
##' @examples
##' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' r <- Kriging(y, X, kernel = "gauss", objective = "LOO")
##' print(r)
##' loo <-  function(theta) leaveOneOut(r,theta)$leaveOneOut
##' t <-  seq(from = 0.0001, to = 2, length.out = 101)
##' plot(t, loo(t), type = 'l')
##' abline(v = as.list(r)$theta, col = 'blue')
leaveOneOut.Kriging <- function(object, theta, grad = FALSE) {
    k <- kriging_model(object) 
    if (!is.matrix(theta)) theta <- matrix(theta,ncol=ncol(k$X))
    if (ncol(theta) != ncol(k$X))
        stop("Input theta must have ", ncol(k$X), " columns (instead of ",
             ncol(theta),")")
    out <- list(leaveOneOut = matrix(NA, nrow = nrow(theta)),
                leaveOneOutGrad = matrix(NA, nrow = nrow(theta),
                                         ncol = ncol(theta)))
    for (i in 1:nrow(theta)) {
        loo <- kriging_leaveOneOut(object,theta[i,],isTRUE(grad))
        out$leaveOneOut[i] <- loo$leaveOneOut
        if (isTRUE(grad)) out$leaveOneOutGrad[i, ] <- loo$leaveOneOutGrad
    }    
    if (!isTRUE(grad)) out$leaveOneOutGrad <- NULL
    return(out)
}


##' Compute model leave-One-Out error at given args
##'
##' @param ... args
##'
##' @return leave-One-Out
##' @export
leaveOneOut <- function (...) UseMethod("leaveOneOut")
setMethod("leaveOneOut", "Kriging", leaveOneOut.Kriging)
setGeneric(name = "leaveOneOut",
           def = function(...) standardGeneric("leaveOneOut"))


##' Compute log-Marginal-Posterior of Kriging model
##' 
##' @author Yann Richet (yann.richet@irsn.fr)
##' 
##' @param object S3 Kriging object
##' @param theta range parameters to evaluate
##' @param grad return Gradient ? (default is TRUE)
##'
##' @return log-MargPost computed for given theta
##' 
##' @method logMargPost Kriging
##' @export logMargPost
##' @aliases logMargPost,Kriging,Kriging-method
##' 
##' @examples
##' f = function(x) 1-1/2*(sin(12*x)/(1+x)+2*cos(7*x)*x^5+0.7)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' r <- Kriging(y, X, "gauss")
##' print(r)
##' lmp <- function(theta) logMargPost(r,theta)$logMargPost
##' t <- seq(from = 0.0001, to = 2, length.oput = 101)
##' plot(t, lmp(t), type = 'l')
##' abline(v = as.list(r)$theta, col = 'blue')
logMargPost.Kriging <- function(object, theta, grad=FALSE) {
    k <- kriging_model(object) 
  if (!is.matrix(theta)) theta=matrix(theta,ncol=ncol(k$X))
    if (ncol(theta)!=ncol(k$X))
        stop("Input theta must have ", ncol(k$X), " columns (instead of ",
             ncol(theta),")")
    out <- list(logMargPost = matrix(NA, nrow = nrow(theta)),
                logMargPostGrad = matrix(NA, nrow = nrow(theta), ncol = ncol(theta)))
    for (i in 1:nrow(theta)) {
        lmp <- kriging_logMargPost(object, theta[i, ], grad = isTRUE(grad))
        out$logMargPost[i] <- lmp$logMargPost
        if (isTRUE(grad)) out$logMargPostGrad[i, ] <- lmp$logMargPostGrad
    }
    if (!isTRUE(grad)) out$logMargPostGrad <- NULL
    return(out)
}

##' Compute model log-Marginal-Posterior at given args
##'
##' @param ... args
##'
##' @return log-Marginal-Posterior
##'  @export
logMargPost <- function (...) UseMethod("logMargPost")
setMethod("logMargPost", "Kriging", logMargPost.Kriging)
setGeneric(name = "logMargPost",
           def = function(...) standardGeneric("logMargPost"))


