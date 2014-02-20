dglm <- function (data.set, dist="gamma", J=FALSE, write=FALSE,
          types=c("C","F",rep("F",ncol(data.set)-2)), minpos=2,
          lnorm.init=FALSE, weight.vector=rep(1,nrow(data.set)),
          jack.noise=1, ig.scale=1)
{
    options(contrasts = c("contr.treatment", "contr.poly"))

    # make sure that initial vector of row names is sequential from 1:n (bug fix)
    rownames(data.set) <- 1:nrow(data.set)

    # check if 'types' argument is of correct length and form
    if (length(types) != ncol(data.set))
    {
        stop("'types' argument must define the response and all explanatory variables.")
    }

    # lnorm.init only necessary for fitting gamma and inverse gaussian distributions
    if (lnorm.init==TRUE && dist=="lognormal")
    {
        stop("Setting lnorm.init=TRUE is only valid for dist='gamma' or 'inverse.gaussian'")
    }

    # check if length of 'weight.vector' equals the number of observations
    if (length(weight.vector) != nrow(data.set))
    {
        stop("Length of 'weight.vector' does not match number of records in data.")
    }

    # use 'types' argument to define class of each variable
    for (i in 1:ncol(data.set))
    {
      if(types[i]=="C")
      {
        data.set[[i]] <- as.numeric(data.set[[i]])
      }
      if(types[i]=="F")
      {
        data.set[[i]] <- as.factor(data.set[[i]])
      }
      if(types[[i]]!="C" & types[[i]]!="F")
      {
        stop("Invalid variable type. Must be 'C' (continuous) or 'F' (factor).")
      }
    }

    #  ensure that response variable is of class 'numeric'
    if (types[[1]] != "C")
    {
        stop("Response must be of type 'C' (continuous).")
    }

    # ensure that first explanatory variable is of class 'factor'
    if (types[[2]] != "F")
    {
        stop("First explanatory variable must be of type 'factor.'")
    }

    # if jackknife routine is enabled, set minpos=2 to make it possible
    # to calculate variance (can't calculate for minpos <= 1)
    if (J==TRUE)
    {
       if(minpos<2)
       {
          minpos <- 2
          print("minpos argument set equal to 2 in order to stabilize jackknife routine.")
       }
       else minpos <- minpos
    }

    # define the distribution for positive observations (Gamma=default),
    # describe for summary output, and assign correct name to output
    if(dist == 'lognormal')
    {
        fam <- gaussian(link="identity")
        fam.out <- c("Lognormal distribution assumed for positive observations.")
        on.exit({
           assign("deltalognormal.results", results, pos = 1)
           assign("deltalognormal.summary", glmdelta.summary, pos = 1)
        })
    }
    if(dist == 'gamma')
    {
        fam <- Gamma(link="log")
        fam.out <- c("Gamma distribution assumed for positive observations.")
        on.exit({
           assign("deltagamma.results", results, pos = 1)
           assign("deltagamma.summary", glmdelta.summary, pos = 1)
        })
    }
    if(dist == 'inverse.gaussian')
    {
        fam <- inverse.gaussian(link="log")
        fam.out <- c("Inverse gaussian distribution assumed for positive observations.")
        on.exit({
           assign("deltainvgau.results", results, pos = 1)
           assign("deltainvgau.summary", glmdelta.summary, pos = 1)
        })
    }

    # this section automatically defines the model formulas from the data;
    # ("main-effects" only, see 'update' command in R documentation for
    #  testing interactions, etc.)
    if(dist == 'lognormal')
    {
       formula1 <- as.formula(paste(paste("log(", names(data.set)[1], ")", "~",
                           sep = ""), paste(names(data.set)[-1], sep = "",
                           collapse = "+")))
    }

    if(dist == 'gamma' || dist == 'inverse.gaussian')
    {
       formula1 <- as.formula(paste(paste(names(data.set)[1], "~", sep = ""),
                           paste(names(data.set)[-1], sep = "", collapse = "+")))
    }

    formula2 <- as.formula(paste(paste(names(data.set)[1], "~", sep = ""),
                        paste(names(data.set)[-1], sep = "", collapse = "+")))

    # describe model formulas for summary outpus
    bin.form <- c(paste("Formula for binomial GLM:", formula2[2], formula2[1], formula2[3]))
    pos.form <- c(paste("Formula for", fam$family, "GLM:", formula1[2], formula1[1], formula1[3]))

# define function to extract 'least squares means' from fitted glm objects
get.effects <- function(glm.obj, target.col)
{
  if(target.col==1) stop('Response variable can not be target of get.effects function')
  glm.data <- glm.obj$model
  dum.coef <- dummy.coef(glm.obj)
  glm.fam <- glm.obj$family$family
  col.num <- ifelse(glm.fam=="binomial", ncol(glm.data), ncol(glm.data)-1)
  var.class <- NULL
  for (i in 1:col.num)
  {
    var.class[i] <- class(glm.data[[i]])
  }
  if(var.class[1]!="numeric") stop('Response variable must be of class numeric')

  # define Estimated Marginal Means (Searle et al., 1980)
  emm.values <- rep(NA,col.num)
  if(col.num>2)
  {
    dum.index <- c(1:col.num)           # define index vector of correct length
    dum.index <- dum.index[-target.col] # exclude target column
    dum.index <- dum.index[-1]          # exclude response column
    for (i in dum.index)                # loop over remaining variables
    {
      if(var.class[i]=="factor") emm.values[i] <- mean(dum.coef[[i]])
      if(var.class[i]=="numeric") emm.values[i] <- dum.coef[[i]]*mean(glm.data[[i]])
      if(var.class[i]!="numeric" & var.class[i]!="factor")
      {
        stop('Variable class not recognized in EMM calculation')
      }
    }
  }

  if(glm.fam == "binomial")
  {
    if(class(glm.data[[target.col]])=="factor")
    {
      x <- exp(dum.coef[[1]] + dum.coef[[target.col]] + sum(emm.values, na.rm=T))
      bin.eff <- x/(1+x)
    }
    if(class(glm.data[[target.col]])=="numeric")
    {
      bin.eff <- dum.coef[[target.col]]
    }
    return(bin.eff)
  }

  if(glm.fam == "Gamma" || glm.fam == "inverse.gaussian")
  {
    if(class(glm.data[[target.col]])=="factor")
    {
      pos.eff <- exp(dum.coef[[1]] + dum.coef[[target.col]] + sum(emm.values, na.rm=T))
    }
    if(class(glm.data[[target.col]])=="numeric")
    {
      pos.eff <- dum.coef[[target.col]]
    }
    return(pos.eff)
  }

  if(glm.fam == "gaussian")
  {
    if(class(glm.data[[target.col]])=="factor")
    {
      pos.eff <- exp(dum.coef[[1]] + dum.coef[[target.col]] +
                 sum(emm.values, na.rm=T) + 0.5*summary(glm.obj)$dispersion)
    }
    if(class(glm.data[[target.col]])=="numeric")
    {
      pos.eff <- dum.coef[[target.col]]
    }
    return(pos.eff)
  }
}

# extract positive records

    posdat <- data.set[data.set[, 1] > 0, ]

# generate vector of weights for fitting gamma or lognormal GLM
# need to extract only the weights corresponding to positive observations
    posweights <- weight.vector[as.numeric(rownames(posdat))]

### SECTION 2 ###
#----------------
# 'backup' original data (prior to filtering data)
    data.set.orig <- data.set
    allpos <- posdat

# only want to filter by qualitative variables, so first identify them
  classes <- NULL
  for (i in 1:ncol(data.set)) classes[i] <- class(data.set[[i]])
  factors <- names(data.set)[classes=="factor"]

# First, create temp data set that only includes the factors
posdat <- cbind.data.frame(posdat[1],posdat[,factors])

# next, record which levels have fewer positives than 'minpos' specification
factor.freq.list <- as.list(rep(NA,ncol(posdat)-1))
factor.drop.list <- as.list(rep(NA,ncol(posdat)-1))
for (i in 2:ncol(posdat))
{
    factor.freq.list[[i-1]] <- table(posdat[[i]])
    if(length(factor.freq.list[[i-1]][factor.freq.list[[i-1]]<minpos])>0)
    {
        factor.drop.list[[i-1]] <- names(factor.freq.list[[i-1]][factor.freq.list[[i-1]]<minpos])
    }
    else
    {
        factor.drop.list[[i-1]] <- NA
    }
}

for(i in 1:length(factor.drop.list))
{
    attributes(factor.drop.list)$names[i] <- names(data.set[i+1])
}

# 'save' list containing names of levels that fall below 'minpos' threshold.
deleted.levels <- factor.drop.list

# record value of 'minpos' for summary output
minpos.val <- c(paste("Data filter threshold set at", minpos, "positive observations."))

# BEGIN 'WHILE' LOOP (data filter)
all.freq <- minpos-1
while (min(all.freq) < minpos)
{
    # update 'posdat' with each pass through the 'while' loop
    posdat <- data.set[data.set[, 1] > 0, ]

    # create temp data set that only includes the factors
    posdat <- cbind.data.frame(posdat[1],posdat[,factors])

    # create vector of frequencies (all.freq) for all levels of all factors
    # this vector determines when the 'while' loop will stop
    all.freq <- table(posdat[[2]])
    if (ncol(posdat)>2)
    {
       for (i in 3:ncol(posdat))
       {
          all.freq <- append(all.freq,table(posdat[[i]]))
       }
    }

    # create list containing names of levels that fall below 'minpos' threshold
    for (i in 2:ncol(posdat))
    {
        factor.freq.list[[i-1]] <- table(posdat[[i]])
        factor.drop.list[[i-1]] <- names(factor.freq.list[[i-1]][factor.freq.list[[i-1]]<minpos])
        for(i in 1:length(factor.drop.list))
        {
            attributes(factor.drop.list)$names[i] <- names(data.set[i+1])
        }
    }

    # remove 'offending' factor levels from the data set
    # i = index for number of components in list
    # j = index for number of elements in each component
    for(i in 1:length(factor.drop.list))
    {
        if(length(factor.drop.list[[i]])>0)
        {
            for (j in 1:length(factor.drop.list[[i]]))
            {
                data.set <- data.set[data.set[names(factor.drop.list)[i]]!=
                                              factor.drop.list[[i]][j],]

            }
        }
    }

    # extract weights relevant to 'filtered' data set
    weight.vector <- weight.vector[as.numeric(rownames(data.set))]

    # redefine factor levels to represent levels remaining in filtered data set
    for (i in 1:ncol(data.set))
    {
        if(class(data.set[[i]])=="factor") data.set[[i]] <- factor(data.set[[i]])
    }

    # renumber rownames of data.set to allow indexing of weight vector by posdat rownames
    rownames(data.set) <- 1:nrow(data.set)

}
# END 'WHILE' LOOP

# redefine data frame of positive records & weight vector (post-filter)
    posdat <- data.set[data.set[, 1] > 0, ]
    posweights <- weight.vector[as.numeric(rownames(posdat))]
    names(posweights) <- rownames(posdat)

# display the total number of records and pos. records that were deleted
    print(paste(nrow(data.set.orig)-nrow(data.set),
        "(total) records were removed by filter."))
    print(paste(nrow(allpos)-nrow(posdat),
        "positive records removed by filter."))

### SECTION 3 ###
#----------------
# calculate delta-GLM index

    # GLM fit to positive data (either Gamma or Lognormal)
    # save vector of coefficients (pos.coefs) to speed up the jackknife iterations
    if(dist == 'lognormal')
    {
        pos.fit <- glm(formula1, weights = posweights, family = fam,
                       data = posdat, maxit = 1000)
        pos.coefs <- as.numeric(coef(pos.fit))
    }

    if(dist == 'gamma')
    {
        if(lnorm.init == TRUE)
        {
            # create formula for fitting lognormal 'GLM'
            lnorm.formula <- as.formula(paste(paste("log(", formula1[[2]], ")", "~",
                                                    sep = ""),
                                              paste(names(data.set)[-1], sep = "",
                                                    collapse = "+")
                                             )
                                       )
            # initial values for fitting Gamma GLM (antilog of coef's from lnorm fit)
            lnorm.coefs <- as.numeric(exp(coef(glm(lnorm.formula, data = posdat,
                                                   family = gaussian, maxit = 1000,
                                                   weights = posweights)
                                              )
                                         )
                                     )
            # fit Gamma GLM with new starting values ('lnorm.coefs')
            pos.fit <- glm(formula1, weights = posweights, family = Gamma(link='log'),
                           data = posdat, maxit = 1000, start = lnorm.coefs)
            pos.coefs <- as.numeric(coef(pos.fit))
        }
        if(lnorm.init == FALSE)
        {
            pos.fit <- glm(formula1, weights = posweights, family = fam,
                           data = posdat, maxit = 1000)
            pos.coefs <- as.numeric(coef(pos.fit))
        }

    }

    if(dist == 'inverse.gaussian')
    {
        # Inverse Gaussian GLMs are unstable with certain data sets, so I
        # use the fitted regression coefficients from either a gamma or
        # lognormal model as starting values in the I.G. fit.
        # The default is 'lnorm.init'=FALSE, which uses coefs from the gamma model;
        # set 'lnorm.init=TRUE' to use anti-logged coef's from the lognormal model.

        # define the formula for the lognormal model
        lnorm.formula <- as.formula(paste(paste("log(", formula1[[2]], ")", "~",
                                                sep = ""),
                                          paste(names(data.set)[-1], sep = "",
                                                collapse = "+")
                                         )
                                   )
        # take the antilog of the coef's for the lognormal model (these are close
        # enough for starting values)
        lnorm.coefs <- as.numeric(exp(coef(glm(lnorm.formula, data = posdat,
                                               family = gaussian, maxit = 1000,
                                               weights = posweights)
                                          )
                                     )
                                 )
        gamma.glm <- glm(formula1, weights = posweights, family = Gamma(link='log'),
                         data = posdat, maxit = 1000, start=lnorm.coefs)
        y.obs <- gamma.glm$model[[1]]
        if(lnorm.init==FALSE)
        {
            print("Initializing Inv. Gaussian GLM with coefficients from gamma GLM.")
            invgau.par <- c(ig.scale, coef(gamma.glm))
        }
        if(lnorm.init==TRUE)
        {
            print("Initializing Inv. Gaussian GLM with coefficients from gaussian GLM for log y.")
            invgau.par <- c(ig.scale, lnorm.coefs)
        }
        X <- model.matrix(gamma.glm)

        # define negative log-likelihood for inverse gaussian distribution
        get.invgau.nll <- function(invgau.par, y.obs)
        {
            y.obs <- gamma.glm$model[[1]]
            mu <- as.numeric(exp(X %*% invgau.par[2:length(invgau.par)]))
            invgau.nll <- -sum(
                                log(
                                    sqrt(
                                         invgau.par[1]/(2*pi*y.obs^3)
                                        )*
                                    exp(
                                        -(invgau.par[1]/(2*y.obs))*((y.obs-mu)/mu)^2
                                       )
                                   )
                               )
            return(invgau.nll)
        }

        invgau.fit <- optim(invgau.par, get.invgau.nll,
                            method = "L-BFGS-B",
                            lower = c(0.000001, rep(-Inf, length(invgau.par)-1)),
                            upper = rep(Inf, length(invgau.par)),
                            control = list(maxit = 100000,
                                           factr = 1e7,
                                           trace = 1
                                          )
                           )

        if(invgau.fit$convergence == 1) print("Maximum number of iterations reached.")
        if(invgau.fit$convergence != 0) print("Check convergence of inverse gaussian fit.")
        names(invgau.fit)[1] <- "parameters"
        names(invgau.fit[[1]]) <- c("scale", names(coef(gamma.glm)))
        names(invgau.fit)[2] <- "negative.log.likelihood"
        AIC.invgau <- 2*invgau.fit[[2]]+2*length(invgau.fit[[1]])

        pos.fit <- glm(formula1, weights = posweights, family = inverse.gaussian(link='log'),
                       data = posdat, maxit = 1000,
                       start = invgau.fit[[1]][2:length(invgau.fit[[1]])])
        pos.coefs <- as.numeric(coef(pos.fit))
    }

    # get back-transformed year effects (with bias correction for lognormal)
    pred1 <- get.effects(pos.fit, 2)

    # Binomial GLM, logit link
    # recode the response variable as a binary variable
    bindat <- data.set
    bindat[, 1] <- as.numeric(data.set[, 1] > 0)

    # fit the binomial GLM using the recoded data set
    bin.fit <- glm(formula2, family = "binomial", data = bindat, maxit = 1000)
    bin.coefs <- as.numeric(coef(bin.fit))

    # get back-transformed year effects (LS means)
    pred2 <- get.effects(bin.fit, 2)

    # This next part makes the year effects from each GLM match up correctly.
    # First, identify years that have at least one positive observation
    pred1.names <- names(pred1)

    # exclude probabilities for years that don't have any positive observations
    # (can't say that no positive observations means no fish)
    pred2 <- pred2[pred1.names]

    ### final index of abundance ###
    index <- pred1 * pred2

### SECTION 4 ###
#----------------
    # initialize objects for jackknife routine
    jackknife <- NA
    out.j <- rep(NA, length(index))
    out.j1 <- rep(NA, length(index))
    out.j2 <- rep(NA, length(index))
    # enable the next line for detailed output of jackknife iterations
    # obs.effect <- NA

    # jackknife routine
    if (J==TRUE)
    {
        jack <- nrow(data.set)
        # enable the next 2 lines for detailed output of jackknife iterations
        # obs.effect <- matrix(rep(NA, jack * 2), ncol = 2)
        # dimnames(obs.effect) <- list(c(1:jack), c("Observation", "SSQ"))
        for (j in 1:jack)
        {
            print(paste("Starting jacknife #", j, "out of", jack))
            jdat <- data.set[-j, ]
            jposdat <- jdat[jdat[, 1] > 0, ]
            jposdat.names <- rownames(jposdat)
            jweights <- posweights[jposdat.names]
            # start each jackknife iteration with fitted coef's from full model.
            # If iteration j removes a positive value, add some noise via 'jitter()'
            # to ensure that variability is not underestimated
            if (data.set[j,1] > 0)
            {
                jpos.fit <- glm(formula1, weights = jweights, family = fam,
                                data = jposdat, maxit = 1000,
                                start = jitter(pos.coefs, factor=jack.noise)
                               )
            }
            if (data.set[j,1] == 0)
            {
                jpos.fit <- pos.fit
            }
            jpred1 <- get.effects(jpos.fit, 2)
            out.j1 <- rbind(out.j1, jpred1)

            jbindat <- jdat
            jbindat[, 1] <- as.numeric(jdat[, 1] > 0)
            jbin.fit <- glm(formula2, family = "binomial",
                            data = jbindat, maxit = 1000,
                            start = jitter(bin.coefs, factor=jack.noise)
                           )
            jpred2 <- get.effects(jbin.fit, 2)
            if(any(names(jpred1) != names(jpred2)))
            {
                stop("Jackknife routine was unstable. Try increasing the value of 'minpos'.")
            }
            out.j2 <- rbind(out.j2, jpred2)
            out.j <- rbind(out.j, jpred1 * jpred2)
            # enable for detailed output of jackknife iterations
            # obs.effect[j, ] <- c(j, sum((index - jpred1 * jpred2)^2))
        }
     out.j <- out.j[-1, ]
     out.j1 <- out.j1[-1, ]
     out.j2 <- out.j2[-1, ]
     jack.mean <- apply(out.j, 2, mean)
     jack.se <- apply(out.j, 2, FUN = function(x) {
                      sqrt(((jack - 1)/jack) * sum((x - mean(x))^2))
                      })
     jack.cv <- jack.se/index
     jackknife <- cbind(jack.mean, jack.se, jack.cv)
   }

    if(dist == 'lognormal' || dist == 'gamma')
    {
        results <- list(positive.glm = pos.fit, binomial.glm = bin.fit,
                        positive.index = pred1, binomial.index = pred2)
                        # enable the next two lines for detailed output of jackknife iterations
                        # jposindex = out.j1, jbinindex = out.j2, jack.index = out.j,
                        # jack.obs.effect = obs.effect)
    }

    if(dist == 'inverse.gaussian')
    {
        results <- list(invgau.ML.fit = invgau.fit, positive.glm = pos.fit,
                        binomial.glm = bin.fit, positive.index = pred1,
                        binomial.index = pred2)
                        # enable the next two lines for detailed output of
                        #     jackknife iterations
                        # jposindex = out.j1, jbinindex = out.j2, jack.index = out.j,
                        # jack.obs.effect = obs.effect)
    }

### SECTION 5 ###
#----------------
# create data frame with filtered index and jackknife results
    index.df <- as.data.frame(cbind(index, jackknife))

# extract effects for additional explanatory variables, if present
# Create 'list' objects that will hold effects for both GLMs
  if (ncol(data.set)>2)
  {
      pos.eff.list <- as.list(rep(NA, ncol(data.set)-2))
      bin.eff.list <- as.list(rep(NA, ncol(data.set)-2))
      pos.eff.names <- as.list(rep(NA, ncol(data.set)-2))
      index.eff.list <- as.list(rep(NA, ncol(data.set)-2))
      for (i in 1:(ncol(data.set)-2))
      {
          pos.eff.list[[i]] <- get.effects(pos.fit, (i+2))
          bin.eff.list[[i]] <- get.effects(bin.fit, (i+2))
          pos.eff.names[[i]] <- names(pos.eff.list[[i]])
          bin.eff.list[[i]] <- bin.eff.list[[i]][pos.eff.names[[i]]]

          if(class(data.set[[i+2]])=="factor")
          {
              index.eff.list[[i]] <- cbind(pos.eff.list[[i]] * bin.eff.list[[i]])
          }

          if(class(data.set[[i+2]])=="numeric")
          {
              index.eff.list[[i]] <- rbind(pos.eff.list[[i]], bin.eff.list[[i]])
              rownames(index.eff.list[[i]]) <- c(pos.fit$family$family,bin.fit$family$family)
          }
      }

      # assign correct variable names to each part of list object
      for(i in 1:length(index.eff.list))
      {
          attributes(index.eff.list)$names[i] <- names(data.set[i+2])
      }
  }

  # create summary output
  if (ncol(data.set)>2)
  {
    glmdelta.summary <- list(error.distribution = fam.out,
                             binomial.formula = bin.form,
                             positive.formula = pos.form,
                             deltaGLM.index = index.df,
                             effects = index.eff.list,
                             data.filter = minpos.val,
                             levels.deleted.by.filter = deleted.levels)
  }
  else
  {
    glmdelta.summary <- list(error.distribution = fam.out,
                             binomial.GLM.formula = bin.form,
                             positive.GLM.formula = pos.form,
                             deltaGLM.index = index.df,
                             data.filter = minpos.val,
                             levels.deleted.by.filter = deleted.levels)
  }

  # since dispersion is fixed at 1 for binomial GLM,
  # use the 'canned' AIC() function in R
  AIC.binomial <- AIC(bin.fit)

  # since glm() in R uses moment estimators for the dispersion
  # parameter in gaussian, gamma, and inverse gaussian GLMs,
  # I needed to get the MLE of the dispersion parameter
  # For the lognormal model, I take regression coefs from the SS fit, and
  # calculate sigma.mle as sigma.unbiased*[(N-K)/N]^0.5

  coefs <- as.numeric(coef(pos.fit))
  X <- model.matrix(pos.fit)

  if (pos.fit$family$family == "gaussian")
  {
      y.obs <- exp(pos.fit$model[[1]])
      N <- length(y.obs)
      # number of regression coefficients, including the intercept term
      K <- length(coefs)
      sigma.mle <- sqrt(summary(pos.fit)$dispersion*((N-K)/N))

      lnorm.nll <- -sum(dlnorm(y.obs,
                               fitted(pos.fit),
                               sdlog=sigma.mle,
                               log=TRUE
                              )
                       )
      # use K+1 parameters for AIC, to account for dispersion parameter
      AIC.lognormal <- 2*lnorm.nll + 2*(K+1)
      AIC.results <- rbind(AIC.binomial, AIC.lognormal, sigma.mle)
  }

  if (pos.fit$family$family == "Gamma")
  {
      require(MASS)
      y.obs <- pos.fit$model[[1]]
      shape.mle <- gamma.shape(pos.fit)[[1]]
      gamma.par <- c(shape.mle, coefs)
      fitted <- as.numeric(exp(X %*% gamma.par[2:length(gamma.par)]))
      gamma.nll <- -sum(gamma.par[1]*(-y.obs/fitted-log(fitted))+
                        gamma.par[1]*log(y.obs)+
                        gamma.par[1]*log(gamma.par[1])-
                        log(y.obs)-lgamma(gamma.par[1])
                       )

      AIC.gamma <- 2*gamma.nll + 2*length(gamma.par)
      AIC.results <- rbind(AIC.binomial, AIC.gamma, shape.mle)
  }

  if (pos.fit$family$family == "inverse.gaussian")
  {
      AIC.inv.gauss <- AIC.invgau
      scale.mle <- as.numeric(invgau.fit[[1]][1])
      AIC.results <- rbind(AIC.binomial, AIC.inv.gauss, scale.mle)
  }

  if (ncol(data.set)>2)
  {
    glmdelta.summary <- list(error.distribution = fam.out,
                             binomial.formula = bin.form,
                             positive.formula = pos.form,
                             deltaGLM.index = index.df,
                             effects = index.eff.list,
                             data.filter = minpos.val,
                             levels.deleted.by.filter = deleted.levels,
                             aic = AIC.results)
  }
  else
  {
    glmdelta.summary <- list(error.distribution = fam.out,
                             binomial.GLM.formula = bin.form,
                             positive.GLM.formula = pos.form,
                             deltaGLM.index = index.df,
                             data.filter = minpos.val,
                             levels.deleted.by.filter = deleted.levels,
                             aic = AIC.results)
  }

  if (write==TRUE)
  {
      options("warn"=-1)
      write(fam.out, file="deltaGLM_output.txt")
      write(bin.form, file="deltaGLM_output.txt", append=T)
      write(pos.form, file="deltaGLM_output.txt", append=T)
      write(c("\n"), file="deltaGLM_output.txt", append=T)
      write.table(index.df, file="deltaGLM_output.txt",
                  quote=F, sep="\t", append=T)
      if (ncol(data.set)>2)
      {
         for (i in 1:length(index.eff.list))
         {
            write(c("\n"), file="deltaGLM_output.txt", append=T)
            write.table(index.eff.list[[i]], file="deltaGLM_output.txt",
                        col.names=names(index.eff.list)[i],
                        quote=F, sep="\t", append=T)
         }
      }

      write(c("\n"), file="deltaGLM_output.txt", append=T)
      write.table(as.data.frame(AIC.results), quote=F, sep="\t",
                  file="deltaGLM_output.txt", append=T)
      options("warn"=0)
      dput(posdat, file="datpos.filtered.rdat")
      dput(bindat, file="datbin.filtered.rdat")
  }

  return(glmdelta.summary)
}
