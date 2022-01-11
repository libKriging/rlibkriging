library(testthat)
library(DiceKriging)

f <- function(x) 1-1/2*(sin(12*x)/(1+x)+2*cos(7*x)*x^5+0.7)
#plot(f)
n <- 5
set.seed(123)
X <- as.matrix(runif(n))
y <-  f(X)
#points(X,y)
k <- km(design = X, response = y, covtype = "gauss", control = list(trace = FALSE))
library(rlibkriging) 
r <- Kriging(y, X, kernel = "gauss", regmodel = "constant",
             normalize = FALSE, optim = "none", objective = "LL",
             parameters = list(sigma2 = k@covariance@sd2,
                               has_sigma2 = TRUE,
                               theta = matrix(k@covariance@range.val),
                               has_theta = TRUE))
## m = as.list(r)

ntest <- 100
Xtest <- as.matrix(runif(ntest))
ptest <- predict(k, Xtest, type = "UK", cov.compute = TRUE, checkNames = FALSE)
Yktest <- ptest$mean
sktest <- ptest$sd
cktest <- c(ptest$cov)
Ytest <- predict(r, x = Xtest, stdev = TRUE, cov = TRUE)

precision <- 1e-5
test_that(desc = paste0("prediction mean is the same as with DiceKriging:\n ",
                      paste0(collapse = ",", Yktest), "\n ",
                      paste0(collapse = ",", Ytest$mean)),
          expect_equal(array(Yktest), array(Ytest$mean),
                       tol = precision))

test_that(desc="prediction sd is the same as with DiceKriging:", 
          expect_equal(array(sktest), array(Ytest$stdev),
                       tol = precision))

test_that(desc="prediction covariance is the same as with DiceKriging:", 
          expect_equal(cktest, c(Ytest$cov), tol = precision))
