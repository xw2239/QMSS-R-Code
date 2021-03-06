# ---------------------------------------------------------
# Title: Ordinal logit
# R version:  3.0.0 (2013-04-03) -- "Masked Marvel"
# R Studio version:  0.97.336
# OS: Mac OS X 10.8.5
# Author: Eurry Kim <ek2758@columbia.edu>
# Maintainer: Eurry Kim <ek2758@columbia.edu>
# Description: G4014 Lecture 3
# ---------------------------------------------------------

library(MASS)
library(memisc)
library(VGAM)

load("gssCS.RData")

# ---------------------------------------------------------
# Predict support for more government spending on childcare
# ---------------------------------------------------------

# Reverse natchld variable
gss.cs$childcare <- factor(gss.cs$natchld, levels=c("too much","about right","too little"), ordered = T)

table(gss.cs$childcare)

# Generate log of income variable
gss.cs$lnrealinc <- log(gss.cs$realinc)

# Make dummy marital status variable
gss.cs$married <- ifelse(gss.cs$marital=="married",1,0)

# -------------
# Ordinal logit
# -------------
# Ordinal logit
child.polr <- polr(childcare ~ childs + age + married + lnrealinc + as.numeric(polviews), 
                   data = gss.cs, Hess=T)
summary(child.polr)

# Odds ratios
exp(coef(child.polr))

# We can do the same logit with another function that allows explicit proportional odds assumption
child.vglm <- vglm(childcare ~ childs + age + married + lnrealinc + as.numeric(polviews), 
                   data = gss.cs, family = propodds)
summary(child.vglm)

# Or you can relax the proportional odds assumption
child2.vglm <- vglm(childcare ~ childs + age + married + lnrealinc + as.numeric(polviews), 
                   data = gss.cs, family = cumulative(reverse=T))
summary(child2.vglm)

# Test the proportional odds assumption
pchisq(deviance(child.vglm) - deviance(child2.vglm),
       df = df.residual(child.vglm) - df.residual(child2.vglm), lower.tail = F)
# Yes, reject. Proportional odds assumption is violated. 

# --------------------------------------------------------------
# Logit to predict log-odds of being in higher vs lower category
# --------------------------------------------------------------
# Collapse childcare categories
summary(gss.cs$childcare)
gss.cs$childcare2or3 <- recode(gss.cs$childcare,
                               1 <- "too much",
                               0 <- c("about right","too little"))
table(gss.cs$childcare2or3)

child.glm <- glm(childcare2or3 ~ childs + age + married + lnrealinc + as.numeric(polviews),
                 data = gss.cs, family = binomial(link = logit))
summary(child.glm)

# --------------------------------------------------------------
# Logit to predict log-odds of being in lower vs higher category
# --------------------------------------------------------------
# Another dummy variable
gss.cs$childcare3 <- recode(gss.cs$childcare,
                            1 <- c("about right","too much"),
                            0 <- "too little")
table(gss.cs$childcare3)

child2.glm <- glm(childcare3 ~ childs + age + married + lnrealinc + as.numeric(polviews),
                 data = gss.cs, family = binomial(link = logit))
summary(child2.glm)

# ----------------------------------
# OLS assumes equidistant categories
# ----------------------------------
child.lm <- lm(as.numeric(childcare) ~ childs + age + married + lnrealinc + as.numeric(polviews),
               data = gss.cs)
summary(child.lm)

# -----------------------------------
# OLS with the new childcare variable
# -----------------------------------
# Change spacing between category variables
gss.cs$nchildcare <- recode(as.numeric(gss.cs$childcare),
                            1 <- 1,
                            45 <- 2,
                            46 <- 3)

child2.lm <- lm(nchildcare ~ childs + age + married + lnrealinc + as.numeric(polviews),
                data = gss.cs)
summary(child2.lm)

# ---------------------------------------
# Ordinal logit of new childcare variable
# ---------------------------------------
child2.polr <- polr(as.factor(nchildcare) ~ childs + age + married + lnrealinc + as.numeric(polviews), 
                   data = gss.cs, Hess=T)
summary(child2.polr)

# ------------------------------------
# Test assumption of proportional odds
# ------------------------------------
# Lifted from http://www.ats.ucla.edu/stat/r/dae/ologit.htm

# Function to test appropriateness of using logistic distribution
sf <- function(y) {
    c('Y>=1' = qlogis(mean(y >= 1, na.rm=T)), 'Y>=2' = qlogis(mean(y >= 2, na.rm=T)), 'Y>=3' = qlogis(mean(y >= 3, na.rm=T)))
}

# Iteratively test proportional odds of DV cutpoints on IV prediction
(s <- with(gss.cs, summary(as.numeric(childcare) ~ childs + age + married + lnrealinc + as.numeric(polviews), fun = sf)))

# Normalize 1st set of coefficients
s[, 4] <- s[, 4] - s[, 3]
s[, 3] <- s[, 3] - s[, 3]

# Plot the coefficients to visualize whether they are relatively similar across cutpoints
plot(s, which = 1:3, pch = 1:3, xlab = "logit", main = " ", xlim = range(s[, 3:4], finite=T))

pchisq(deviance(fit.po)-deviance(fit.npo),
       df=df.residual(fit.po)-df.residual(fit.npo),lower.tail=FALSE)

# Save the workspace
save.image("gssCS.RData")