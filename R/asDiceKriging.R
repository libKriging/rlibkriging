## XXXY added by Yves

if (!requireNamespace("DiceKriging", quietly = TRUE)) {
    stop("Package \"DiceKriging\" not found")
}
    
## register the S3 class "Kriging"
setOldClass("Kriging")

##' @title S4 class for Kriging Models Extending the \code{"km"} Class
##' 
##' @description This class is intended to be used either by using its
##'     own dedicated S4 methods or by using the S4 methods inherited
##'     from the \code{"km"} class of the \pkg{libKriging} package.
##'
##'
##' @slot d,n,X,y,p,F Number of (numeric) inputs, number of
##'     observations, design matrix, response vector, number of trend
##'     variables, trend matrix.
##' 
##' @slot trend.formula,trend.coef Formula used for the trend, vector
##' \eqn{\hat{\boldsymbol{\beta}}}{betaHat} of estimated (or fixed)
##' trend coefficients with length \eqn{p}.
##'
##' @slot covariance A
##' 
##' @section Useful material:
##'
##' @author Yann Richet \email{yann.richet@irsn.fr}
##'
##' @rdname KM-class
##'
##' @seealso \code{\link[DiceKriging]{km-class}} in the
##'     \bold{DiceKriging} package. The creator \code{\link{KM}}.
##' @export
setClass("KM", slots = c("Kriging" = "Kriging"), contains = "km")


##' Coerce a \code{Kriging} object into the class
##' \code{"km"} from the DiceKriging package.
##'
##' @title Coerce a \code{Kriging} Object into the Class \code{"km"}
##' 
##' @author Yann Richet \email{yann.richet@irsn.fr}
##' 
##' @param x An object with S3 class \code{"Kriging"}.
##' 
##' @param .call Force the "call" to be filled in \code{km} object.
##'
##' @return An object of having the S4 class \code{"KM"} which
##'     extends \code{DiceKriging::km} and contains an extra
##'     \code{"Kriging"} slot.
##'
##' ## @importFrom utils installed.packages XXXY
##'
##' @method as.km Kriging
##' @importFrom methods new
##' @importFrom stats model.matrix
##' @export KM
##' @aliases KM,Kriging,Kriging-method
##' @examples
##' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' r <- Kriging(y, X, "gauss")
##' print(r)
##' k <- KM(r)
##' print(k)
##' 
as.km.Kriging <- function(x, .call = NULL) {
    
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
    
    model@case <- "LLconcentration_beta_sigma2"
    
    model@known.param <- "None"
    model@param.estim <- NA
    model@method <- m$objective
    model@optim.method <- m$optim
    
    model@penalty <- list()
    model@lower <- 0
    model@upper <- Inf
    model@control <- list()
    
    model@gr <- FALSE
    
    model@T <- m$T
    model@z <- as.numeric(m$z)
    model@M <- m$M
    
    covStruct <-  new("covTensorProduct", d = model@d, name = m$kernel, 
                      sd2 = m$sigma2, var.names = names(data), 
                      nugget = 0, nugget.flag = FALSE, nugget.estim = FALSE,
                      known.covparam = "")
    
    covStruct@range.names <- "theta" 
    covStruct@paramset.n <- as.integer(1)
    covStruct@param.n <- as.integer(model@d)
    covStruct@range.n <- as.integer(model@d)
    covStruct@range.val <- as.numeric(m$theta)
    model@covariance <- covStruct 
    
    return(model)
}

##' Create an object of S4 class \code{"KM"} similar to a
##' \code{"km"} object in the DiceKriging package.
##' 
##' The class \code{"KM"} extends the \code{"km"} class of the
##' \bold{DiceKriging} package, hence has all slots of \code{"km"}. It
##' also has an extra slot \code{"Kriging"} slot which contains a copy
##' of the original object. 
##'
##' @title Create an \code{KM} Object
##' 
##' @author Yann Richet \email{yann.richet@irsn.fr}
##' 
##' @param formula R formula object to setup the linear trend in
##'     Universal Kriging. Supports \code{~ 1}, ~. and \code{~ .^2}.
##' @param design Data frame. The design of experiments.
##' @param response Array of output values. XXXY ?
##' @param covtype Covariance structure. Supports \code{"gauss"},
##'     \code{"exp"}, ... XXXY What values?
##' @param coef.cov Opitonal value for a fixed correlation range
##'     value. If given, no optimization is done.
##' @param coef.var Optional value for a fixed variance. If given, no
##'     optimization is done.
##' @param coef.trend Optional value for a fixed vector of trend
##'     coefficients.  If given, no optimization is done.
##' @param estim.method Estimation criterion. \code{"MLE"} for
##'     Maximum-Likelihood or \code{"LOO"} for Leave-One-Out
##'     cross-validation.
##' @param optim.method Optimization algorithm used in the
##'     optimization of the objective given in
##'     \code{estim.method}. Supports \code{"BFGS"}.
##' @param parinit Initial values for the correlation ranges which
##'     will be optimized using \code{optim.method}.
##' @param ... Ignored.
##'
##' @return KM object. See \bold{Details}. 
##'
##' @export KM
##' @examples
##' # a 16-points factorial design, and the corresponding response
##' d <- 2; n <- 16
##' design.fact <- expand.grid(x1 = seq(0, 1, length = 4), x2 = seq(0, 1, length = 4))
##' y <- apply(design.fact, 1, DiceKriging::branin) 
##' 
##' # Using `km` from DiceKriging and a similar `KM` object 
##' # kriging model 1 : matern5_2 covariance structure, no trend, no nugget effect
##' km1 <- km(design = design.fact, response = y, covtype = "gauss",
##'           parinit = c(.5, 1), control = list(trace = FALSE))
##' KM11 <- KM(design = design.fact, response = y, covtype = "gauss",
##'            parinit = c(.5, 1))
##' 
KM <- function(formula = ~1, design, response, covtype = "matern5_2",
               coef.cov = NULL, coef.var = NULL, coef.trend = NULL,
               estim.method = c("MLE", "LOO"), optim.method = "BFGS",
                          parinit = NULL,
               ...) {

    estim.method <- match.arg(estim.method)
    formula <- formula2regmodel(formula)
    
    if (!is.matrix(design)) design <- as.matrix(design)
    if (!is.matrix(response)) response <- matrix(response, nrow = nrow(design))
    
    if (estim.method == "MLE") estim.method <- "LL"
    else if (estim.method == "LOO") estim.method <- "LOO"
    else stop("Unsupported 'estim.method' ", estim.method)
    
    if (!(covtype %in% c("gauss", "exp", "matern3_2", "matern5_2")))
        stop("Unsupported 'covtype' ", covtype)
    
    if (optim.method != "BFGS")
        warning("Cannot setup optim.method ", optim.method,". Ignored.")
    
    parameters <- list()
    if (!is.null(coef.var))
        parameters <- c(parameters,list(sigma2 = coef.var))
    if (!is.null(coef.cov)) {
        parameters <- c(parameters,
                        list(theta = matrix(coef.cov, ncol = ncol(design))))
        optim.method <- "none"
    }  
    if (!is.null(coef.trend)) {
        parameters <- c(parameters, list(beta = matrix(coef.trend)))
    }
    if (!is.null(parinit)) {
        parameters <- c(parameters,
                        list(theta = matrix(parinit, ncol = ncol(design))))
    }
    if (length(parameters) == 0)  parameters <- NULL
    
    r <- rlibkriging::Kriging(y = response, X = design, kernel = covtype,
                             regmodel = formula,
                             normalize = FALSE, 
                             objective = estim.method, optim = optim.method,
                             parameters = parameters)
    
    return(as.km.Kriging(r, .call = match.call()))
    
}


## setMethod("KM", "Kriging", KM.Kriging)
## setGeneric(name = "KM", def = function(...) standardGeneric("KM"))

##' Overload DiceKriging::predict.km for \code{KM} objects (expected faster).
##'
##' @author Yann Richet \email{yann.richet@irsn.fr}
##' 
##' @param object An \code{KM} object.
##' @param newdata Matrix of points where to perform prediction.
##' @param type Character giving the kriging type. For now only
##'     \code{"UK"} is possible.
##' @param se.compute Logical. Should the standard error be computed?
##' @param cov.compute Logical. Should the covariance matrix between
##'     newdata points be computed?
##' @param light.return return no other intermediate objects (like T
##'     matrix).
##' @param bias.correct fix UK variance and covaariance (defualt is
##'     FALSE)
##' @param checkNames check consistency between object design data: X
##'     and newdata (default is FALSE)
##' @param ... Ignored
##'
##' @return list of predict data: mean, sd, trend, cov, upper95 and
##'     lower95 quantiles.
##' 
##' @importFrom stats qt
##' @method predict KM
##' @export predict
##' @aliases predict,KM,KM-method
##'
##' @examples
##' ## a 16-points factorial design, and the corresponding response
##' d <- 2; n <- 16
##' design.fact <- expand.grid(x1 = seq(0, 1, length = 4), x2 = seq(0, 1, length = 4))
##' y <- apply(design.fact, 1, DiceKriging::branin) 
##' 
##' ## library(DiceKriging)
##' ## kriging model 1 : matern5_2 covariance structure, no trend, no nugget effect
##' ## m1 <- km(design = design.fact, response = y, covtype = "gauss",
##' ##          parinit = c(.5, 1), control = list(trace=F))
##' as_m1 <- KM(design = design.fact, response = y, covtype = "gauss",
##'                parinit = c(.5, 1))
##' as_p <- predict(as_m1,newdata = matrix(.5,ncol = 2), type = "UK",
##'                 checkNames = FALSE, light.return = TRUE)
predict.KM <- function(object, newdata, type = "UK",
                          se.compute = TRUE,
                          cov.compute = FALSE,
                          light.return = TRUE,
                          bias.correct = FALSE, checkNames = FALSE,...) {

    if (length(L <- list(...)) > 0) warnOnDots(L)
    
    if (isTRUE(checkNames)) stop("'checkNames = TRUE' unsupported.")
    if (isTRUE(bias.correct)) stop("'bias.correct = TRUE' unsupported.")
    if (!isTRUE(light.return)) stop("'light.return = FALSE' unsupported.")
    if (type != "UK") stop("'type != UK' unsupported.")
    
    y.predict <- predict.Kriging(object@Kriging, x = newdata,
                                stdev = se.compute, cov = cov.compute)
    
    output.list <- list()
    ## output.list$trend <- y.predict.trend
    output.list$mean <- y.predict$mean
    
    if (se.compute) {		
        s2.predict <- y.predict$stdev^2
        q95 <- qt(0.975, object@n - object@p)
        
        lower95 <- y.predict$mean - q95 * sqrt(s2.predict)
        upper95 <- y.predict$mean + q95 * sqrt(s2.predict)
        
        output.list$sd <- sqrt(s2.predict)
        output.list$lower95 <- lower95
        output.list$upper95 <- upper95
    }
    
    if (cov.compute) {		
        output.list$cov <- y.predict$cov
    }
    
    F.newdata <- model.matrix(object@trend.formula, data = data.frame(newdata))
    output.list$trend <- F.newdata %*% object@trend.coef
    
    return(output.list)
}

setMethod("predict", "KM", predict.KM)


##' Overload the \code{simulate} method from DiceKriging for
##' \code{KM} objects. This is expected to be faster.
##'
##' @title Simulation from a \code{KM} Object
##' 
##' @author Yann Richet \email{yann.richet@irsn.fr}
##' 
##' @param object An \code{KM} object.
##'
##' @param nsim Integer: number of response vectors to simulate.
##'
##' @param seed Random seed.
##' 
##' @param newdata Numeric matrix with it rows giving the points where
##'     the simulation is to be performed.
##'
##' @param cond Logical telling wether the simulation is conditional
##'     or not. Only \code{TRUE} is accepted for now.
##'
##' @param nugget.sim Numeric. A postive nugget effect used to avoid
##'     numerical instability.
##'
##' @param checkNames Check consistency between the design data
##'     \code{X} within \code{object} and \code{newdata}. The default
##'     is \code{FALSE}. XXXY Not used!!!
##'
##' @param ... Ignored.
##'
##' @return A numeric matrix with \code{nrow(newdata)} rows and
##'     \code{nsim} columns containing as its columns the simulated
##'     paths at the input points given in \code{newdata}.
##' 
##' @method simulate KM
##' @export simulate
##' @aliases simulate,KM,KM-method
##'
##' @examples
##' f <-  function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
##' plot(f)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' points(X, y, col = 'blue')
##' k <- KM(design = X, response = y, covtype = "gauss")
##' x <- seq(from = 0, to = 1, length.out = 101)
##' s_x <- simulate(k, nsim = 3, newdata = x)
##' lines(x, s_x[ , 1], col = 'blue')
##' lines(x, s_x[ , 2], col = 'blue')
##' lines(x, s_x[ , 3], col = 'blue')
simulate.KM <- function(object, nsim = 1, seed = NULL, newdata,
                           cond = TRUE, nugget.sim = 0,
                           checkNames = FALSE, ...) {
  if (length(L <- list(...)) > 0) warnOnDots(L)
  if (isTRUE(checkNames)) stop("'checkNames = TRUE' unsupported.")
  if (!isTRUE(cond)) stop("'cond = FALSE' unsupported.")
  if (nugget.sim!=0) stop("'nugget.sim != 0' unsupported.")
  
  return(simulate.Kriging(object = object@Kriging,
                          x = newdata,nsim = nsim, seed = seed))
}

setMethod("simulate", "KM", simulate.KM)


##' Overload DiceKriging::update.km method for `KM` objects (expected faster).
##'
##' @title Overload the `update` Method from \bold{DiceKriging}
##'
##' @author Yann Richet \email{yann.richet@irsn.fr}
##' 
##' @param object KM object
##' @param newX new design points: matrix of object@d columns
##' @param newy new response points
##' @param newX.alreadyExist if TRUE, newX contains some ppoints
##'     already in object@X
##' @param cov.reestim fit object to newdata: estimate theta (only
##'     supports TRUE)
##' @param trend.reestim fit object to newdata: estimate beta (only
##'     supports TRUE)
##' @param nugget.reestim fit object to newdata: estimate nugget
##'     effect (only support FALSE)
##' @param newnoise.var add noise to newy response
##' @param kmcontrol parametrize fit (unsupported)
##' @param newF New trend matrix.
##' @param ... Ignored
##'
##' @method update KM
##' @export update
##' @aliases update,KM,KM-method
##' @examples
##' f <- function(x) 1 - 1 / 2 * (sin(12 * x) / (1 + x) + 2 * cos(7 * x) * x^5 + 0.7)
##' plot(f)
##' set.seed(123)
##' X <- as.matrix(runif(5))
##' y <- f(X)
##' points(X,y,col='blue')
##' k <- KM(design=X, response=y,covtype = "gauss")
##' x <-  seq(from = 0, to = 1, length.out = 101)
##' p_x <- predict(k, x)
##' lines(x, p_x$mean, col = 'blue')
##' lines(x, p_x$lower95, col = 'blue')
##' lines(x, p_x$upper95, col = 'blue')
##' newX <- as.matrix(runif(3))
##' newy <- f(newX)
##' points(newX, newy, col = 'red')
##' update(k, newy, newX)
##' x <- seq(from = 0, to = 1, length.out = 101)
##' p2_x <- predict(k, x)
##' lines(x, p2_x$mean, col = 'red')
##' lines(x, p2_x$lower95, col = 'red')
##' lines(x, p2_x$upper95, col = 'red')
update.KM <- function(object,
                         newX,
                         newy,
                         newX.alreadyExist =  FALSE,
                         cov.reestim = TRUE,trend.reestim = cov.reestim,
                         nugget.reestim=FALSE,
                         newnoise.var = NULL, kmcontrol = NULL, newF = NULL,
                         ...) {
    
    if (length(list(...)) > 0) warnOnDots()
    
    if (isTRUE(newX.alreadyExist)) stop("'newX.alreadyExist = TRUE' unsupported.")
    if (!is.null(newnoise.var)) stop("'newnoise.var != NULL' unsupported.")
    if (!is.null(kmcontrol)) stop("'kmcontrol != NULL' unsupported.")
    if (!is.null(newF)) stop("'newF != NULL' unsupported.")
    
    update.Kriging(object@Kriging,newy,newX)
  
    return(object)
    
}

setMethod("update", "KM", update.KM)


## XXXY use 'identical' with formula objects seesm cleaner
formula2regmodel = function(form) {
    if (format(form) == "~1")
        return("constant")
    else if (format(form) == "~.")
        return("linear")
    else if (format(form) == "~.^2")
        return("interactive")
    else stop("Unsupported formula ", form)
}


regmodel2formula = function(regmodel) {
  if (regmodel == "constant")
    return(~1)
  else if (regmodel == "linear")
    return(~.)
  else if (regmodel == "interactive")
    return(~.^2)
  else stop("Unsupported regmodel ",regmodel)
}
