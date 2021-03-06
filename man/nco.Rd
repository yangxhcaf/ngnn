% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nco.R, R/nco_predict.R
\name{nco}
\alias{nco}
\alias{summary.nco}
\alias{plot.nco}
\alias{summary.ncopredict}
\title{NCO, Nonparametric constrained ordination}
\usage{
nco(obj, method, thresh, ...)

\method{summary}{nco}(obj, ...)

\method{plot}{nco}(obj, type = "points", cexn = NULL, ...)

\method{summary}{ncopredict}(obj, ...)
}
\arguments{
\item{obj}{object of class 'npmr' from call to \code{\link{npmr}}}

\item{method}{distance measure for all ordinations}

\item{thresh}{numeric threshold for stepacross dissimilarities}

\item{...}{additional arguments passed to function}

\item{type}{either 'points' or 'text' for plotting}

\item{cexn}{expansion factor for points and text}
}
\value{
List of class 'nco' with elements:
\itemize{
  \item scr_i = environmentally constrained scores from NCO
  \item NCO_model = the NCO model itself
  \item R2_internal = squared correlation of Dhat and Dz
  \item R2_enviro = squared correlation of D and Dz
  \item R2_partial = squared correlation of Dz and each predictor
  \item Axis_tau = rank correlation of each axis and predictor
  }
}
\description{
Constrained ordination based on nonparametric regression and NMS.
}
\details{
Combines existing algorithms in multivariate workflow:

        NPMR + NMS = NCO

NCO (McCune and Root 2012; McCune and Root 2017) is nonmetric
multidimensional scaling ordination (NMS; Kruskal 1964) of sample
units based on environmentally constrained fitted values from a set
of nonparametric multiplicative regressions (NPMR; McCune 2006) for
each species. This implementation uses \code{\link[np]{npreg}} from
package `np` (NPMR stage) and \code{\link[vegan]{metaMDS}} from
package 'vegan' (NMS stage).

Variance explained \code{R2_enviro} measures the strength of the
relationship between the original community data and the ordination
as constrained to the *measured* predictors.  Like all constrained
ordinations, NCO does not account for variation in species
composition related to *unmeasured* predictors.
}
\examples{
# set up
set.seed(978)
require(vegan)
data(varespec, varechem)
spe <- varespec ; id  <- varechem
i   <- sample(1:nrow(spe), size=floor(0.75*nrow(spe))) # sample
spe <- spe[i, ]          # in-sample species
idi <- id[i, ]           # in-sample predictors
ido <- id[-i, ]          # out-of-sample predictors
nm  <- c('Al', 'K')      # select 1 or 2 gradients of interest

# NPMR basic usage
res_npmr <- npmr(spe, idi, ido, nm, nmulti=5)
summary(res_npmr)
plot(res_npmr, pick=1:9, nm=nm)

# NCO basic usage
res_nco <- nco(res_npmr, method='bray', thresh=0.90)
summary(res_nco)

# plot the NCO gradient space
plot(res_nco)
plot(res_nco, type='text')

}
\references{
Kruskal, J. B. 1964. Multidimensional scaling by optimizing
  goodness of fit to a nonmetric hypothesis. Psychometrika 29:
  1-27.

McCune, B. 2006. Non-parametric habitat models with automatic
  interactions. Journal of Vegetation Science 17(6):819-830.

McCune, B., and H. T. Root. 2012. Nonparametric constrained
  ordination. 97th ESA Annual Meeting. Ecological Society of
  America, Portland, OR.

McCune, B., and H. T. Root. 2017. Nonparametric constrained
  ordination to describe community and species relationships to
  environment. Unpublished ms.
}
\concept{nco functions}
