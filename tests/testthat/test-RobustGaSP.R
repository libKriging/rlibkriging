library(testthat)

## RobustGaSP first example
library(RobustGaSP)
##------------------------
## a 3 dimensional example
##------------------------
## dimensional of the inputs
dim_inputs <- 3    
## number of the inputs
num_obs <- 30       
## uniform samples of design
input <- matrix(runif(num_obs * dim_inputs), nrow = num_obs, ncol = dim_inputs) 

####
## outputs from the 3 dim dettepepel.3.data function

output = matrix(0,num_obs,1)
for(i in 1:num_obs){
  output[i]<-dettepepel.3.data (input[i,])
}

## use constant mean basis, with no constraint on optimization
## and marginal posterior mode estimation
m1 <- rgasp(design = input, response = output,
            ## Default parameters:
            trend = matrix(1.0, nrow = length(output), ncol = 1),
            zero.mean = "No", nugget = 0,
            nugget.est = FALSE ,
            range.par = NA,
            method = 'post_mode', prior_choice = 'ref_approx',
            a = 0.2,
            b = 1.0 / (length(output))^{1.0 / dim(as.matrix(input))[2]} *
                (0.2 + dim(as.matrix(input))[2]),
            kernel_type = 'matern_5_2', isotropic = FALSE,R0 = NA, optimization = 'lbfgs',
            alpha = rep(1.9,dim(as.matrix(input))[2]),
            lower_bound = TRUE, max_eval = max(30, 20 + 5 * dim(input)[2]),
            initial_values = NA, num_initial_values = 2)

pack <- list.files(file.path("bindings","R"), pattern = ".tar.gz", full.names = TRUE)
install.packages(pack, repos = NULL)
library(rlibkriging)
mK <- Kriging(output, input, 
              kernel = "matern5_2", 
              regmodel = "constant", normalize = FALSE, 
              optim = "BFGS", 
              objective = "LMP", parameters = NULL)

## XXXY I can not understand what is tested here
lm1 <- as.list(mK)
mK
lm1$theta
