#' @title NGNN, Nonlinear Gradient Nearest Neighbors
#'
#' @description Predict community composition based on individualistic
#'      but possibly coordinated species responses
#'
#' @param spe species dataframe, rows = sample units and columns =
#'     species
#'
#' @param idi in-sample predictor dataframe, rows must match 'spe'
#'
#' @param ido out-of-sample predictor dataframe, where rows = new
#'     sample units
#'
#' @param nm  string vector specifying predictors to include (max 2)
#'
#' @param nmulti number of random starts in nonparametric regression
#'
#' @param pa logical, convert to presence/absence?
#'
#' @param pr logical, use 'beals' for probs of joint occurrence?
#'
#' @param method distance measure for all ordinations
#'
#' @param thresh numeric threshold for stepacross dissimilarities
#'
#' @param neighb number of adjacent distances considered in NCOpredict
#'
#' @param maxits number of NCOpredict iterations
#'
#' @param k the maximum number of nearest neighbors to find in NCO
#'     gradient space
#'
#' @param type either 'points' or 'text' for plotting
#'
#' @param cexn expansion factor for points and text
#'
#' @param ocol color value or vector for out-of-sample points
#'
#' @param obj object of class 'ngnn' from call to \code{ngnn}
#'
#' @param pick variable to query
#'
#' @param zlim vector of length 2, giving vertical limits for plots
#'
#' @param ... additional arguments passed to function
#'
#' @return
#' List of class 'ngnn' with elements:
#' \itemize{
#'   \item spe = original species matrix
#'   \item id_i = in-sample predictors used in NPMR
#'   \item nm = which predictors were used
#'   \item nm_len = their length
#'   \item iYhat = in-sample fitted values from NPMR
#'   \item oYhat = out-of-sample fitted values from NPMR
#'   \item np_stat = fit, tolerances and results of signif tests
#'   \item np_mods = list of NPMR regression models for every species
#'   \item np_bw = list of NPMR  bandwidths for every species,
#'   \item scr_i = environmentally constrained site scores from NCO
#'   \item NCO_model = the NCO ordination model
#'   \item R2_internal = squared correlation of Dhat and Dz from NCO
#'   \item R2_enviro = squared correlation of D and Dz from NCO
#'   \item R2_partial = squared correlation of Dz and each predictor
#'   from NCO
#'   \item Axis_tau = rank correlation of each axis and predictor from
#'   NCO
#'   \item nmsp = a list of 5 items describing predicted NCO scores
#'       (see \code{\link{nco_predict}})
#'   \item flagax1,flagax2 = flags which nco_predict values were off
#'   axes
#'   \item nn = identifies the gradient nearest neighbor for predicted
#'   vals
#'   \item spp_imputed = inferred out-of-sample species compositions
#'   }
#'
#' @details
#' When given a set of sample units where species abundances and
#' corresponding predictor values are both known, how does one infer
#' which species should appear in 'new' sample units where only the
#' predictors are known?  NGNN (nonlinear gradient nearest neighbors)
#' approaches the problem of species imputation in the following way:
#'
#' Regress species individualistically on predictors -> \cr Feed
#' fitted values to NMS ordination -> \cr Find nearest neighbors in
#' ordination space, and assign species. \cr
#'
#' A more detailed description: \cr
#' First, define an \emph{in-sample} set of sample units where species
#' abundances and corresponding predictor values are both known, as
#' well as an \emph{out-of-sample} set where only predictor values are
#' known.  Second, use \code{\link{npmr}} to perform NPMR regression
#' (McCune 2006) of both in-sample and out-of-sample sample units; use
#' \code{\link{nco}} to feed NPMR fitted values to NMS ordination
#' (Kruskal 1964); this is nonparametric constrained ordination (NCO;
#' McCune and Root 2012; McCune and Root 2017).  A follow-up step with
#' \code{\link{nco_predict}} allows calculating predicted NCO scores
#' for the \emph{out-of-sample} set even though species compositions
#' are not strictly known.  Finally, use \code{gnn} to identify
#' the \emph{in-sample} Euclidean nearest neighbor of each
#' \emph{out-of-sample} point in the NCO ordination space, and assign
#' the (possibly averaged) species composition of that neighbor to the
#' point in question.  This retains realistic communities of
#' co-occurring species, since they've already been observed in at
#' least one other sample unit.  The entire process is summarized in
#' the wrapper function \code{\link{ngnn}}.
#'
#' Function \code{\link{ngnn}} finds the \emph{k} nearest nighbors in
#' the original ordination space; higher values of \emph{k} probably
#' work better with many original points, and with points more evenly
#' distributed in ordination space.
#'
#' @examples
#' # set up
#' set.seed(978)
#' require(vegan)
#' data(varespec, varechem)
#' spe <- varespec ; id  <- varechem
#' i   <- sample(1:nrow(spe), size=floor(0.75*nrow(spe))) # sample
#' spe <- spe[i, ]          # in-sample species
#' idi <- id[i, ]           # in-sample predictors
#' ido <- id[-i, ]          # out-of-sample predictors
#' nm  <- c('Al', 'K')      # select 1 or 2 gradients of interest
#'
#' # basic usage
#' res <- ngnn(spe, idi, ido, nm, nmulti=5, method='bray',
#'             thresh=0.90, neighb=5, maxits=999, k=1)
#' summary(res)
#' str(res, 1)
#'
#' # plot the species response curves
#' ngnn_plot_spp(res, pick=1:9, nm=nm)
#'
#' # plot the NCO gradient space
#' ngnn_plot_nco(res)
#'
#' # predicted (imputed) species composition for out-of-sample sites
#' ngnn_get_spp(res)
#'
#' # how close were predicted species composition to 'true' values?
#' spe_append <- rbind(spe, res$spp_imputed)   # append to existing
#' heatmap(t(as.matrix(spe_append)), Rowv=NA, Colv=NA)
#'
#' # check composition of 'hold-out' data
#' heatmap(t(as.matrix(varespec[-i,])), Rowv=NA, Colv=NA)
#' # ... vs new species from NGNN
#' heatmap(t(as.matrix(res$spp_imputed)), Rowv=NA, Colv=NA)
#'
#' # Prediction error: Root Mean Square Error
#' `rmse` <- function(y, ypred, ...){
#'      sqrt(mean((y-ypred)^2, ...))
#' }
#' rmse(varespec[-i,], res$spp_imputed)
#'
#'
#' ## can do entire process manually, avoiding the wrapper function:
#' # NPMR
#' res_npmr <- npmr(spe, idi, ido, nm, nmulti=5)
#' # NCO (NMS)
#' res_nco  <- nco(res_npmr, method='bray', thresh=0.90)
#' # NCOpredict (NMSpredict)
#' res_nmsp <- nco_predict(res_nco, method='bray', neighb=5,
#'                         maxits=999)
#' # GNN
#' res_gnn  <- gnn(obj=res_nmsp, k=1)
#' summary(res_gnn)
#'
#'
#' @references
#' Kruskal, J. B. 1964. Multidimensional scaling by optimizing
#'   goodness of fit to a nonmetric hypothesis. Psychometrika 29:
#'   1-27.
#'
#' McCune, B. 2006. Non-parametric habitat models with automatic
#'   interactions. Journal of Vegetation Science 17(6):819-830.
#'
#' McCune, B., and H. T. Root. 2012. Nonparametric constrained
#'   ordination. 97th ESA Annual Meeting. Ecological Society of
#'   America, Portland, OR.
#'
#' McCune, B., and H. T. Root. 2017. Nonparametric constrained
#'   ordination to describe community and species relationships to
#'   environment. Unpublished ms.
#'
#' Ohmann, J.L., and M.J. Gregory. 2002. Predictive mapping of forest
#'   composition and structure with direct gradient analysis and
#'   nearest-neighbor imputation in coastal Oregon, U.S.A. Canadian
#'   Journal of Forest Research 32:725-741.
#'
#' @family ngnn functions
#' @seealso \code{\link{npmr}} for NPMR, \code{\link{nco}} for NCO,
#'     \code{\link{nco_predict}} for predictive NCO, and
#'     \code{gnn} for the core function of NGNN.
#'
#' @export
#' @rdname ngnn
### final wrapper function
`ngnn` <- function(spe, idi, ido, nm, nmulti=5, pa=FALSE, pr=FALSE,
                   method='bray', thresh=0.90,
                   neighb=5, maxits=999, k=1, ...){
     res_npmr <- npmr(spe, idi, ido, nm, nmulti, pa, pr, ...)
     # NCO (NMS)
     res_nco  <- nco(obj=res_npmr, method, thresh, ...)
     # NCOpredict (NMSpredict)
     res_nmsp <- nco_predict(obj=res_nco, method, neighb, maxits, ...)
     # GNN
     res_gnn  <- gnn(obj=res_nmsp, k, ...)
     class(res_gnn) <- 'ngnn'
     res_gnn
}
#' @export
#' @rdname ngnn
### GNN core function
`gnn` <- function(obj, k, ...){
     stopifnot(class(obj)=='ncopredict')
     cat('Finding nearest neighbor(s) in NCO space...\n\n')
     nn <- FNN::get.knnx(data=obj$scr_i, query=obj$nmsp$scr_o,
                         k=k, algo='kd_tree')$nn.index
     rowseq <- 1:nrow(nn)
     tmp    <- obj$spe[rowseq, ]
     tmp[]  <- NA
     for (r in rowseq){ # for every new plot
          # avg neighbor abundances:
          tmp[r,] <- colMeans(obj$spe[nn[r,],])
     }
     # TODO: could use weighted mean abundance, weighted by distance
     cat('Assigning spp composition to out-of-sample SUs...\n\n')
     row.names(tmp) <- row.names(obj$nmsp$scr_o)
     out <- c(obj, list(nn = nn, spp_imputed = tmp))
     class(out) <- 'ngnn'
     out
}
#' @export
#' @rdname ngnn
# summary for NGNN
`summary.ngnn` <- function(obj, ...){
     stopifnot(class(obj)=='ngnn')
     out <- list(np_stat      = obj$np_stat,
                 R2_internal  = obj$R2_internal,
                 R2_enviro    = obj$R2_enviro,
                 R2_partial   = obj$R2_partial,
                 Axis_tau     = obj$Axis_tau,
                 flagax1      = obj$flagax1,
                 flagax2      = obj$flagax2)
     isnum <- sapply(out, is.numeric)
     out[isnum] <- lapply(out[isnum], round, digits=3)
     out
}
#' @export
#' @rdname ngnn
# plot both old and new scores
`ngnn_plot_nco` <- function(obj, type='points', ocol=2, cexn=NULL,
                            ...){
     stopifnot(class(obj)=='ngnn')
     type <- match.arg(type, c('points', 'text', 'none'))
     ylim <- c(min(obj$scr_i[,2],obj$nmsp$scr_o[,2])*1.1,
               max(obj$scr_i[,2],obj$nmsp$scr_o[,2])*1.1)
     xlim <- c(min(obj$scr_i[,1],obj$nmsp$scr_o[,1])*1.1,
               max(obj$scr_i[,1],obj$nmsp$scr_o[,1])*1.1)
     if(!is.null(cexn)){
          cexn <- normalize(obj$id_i[cexn])
     } else { cexn <- 0.7 }
     vegan::ordiplot(obj$scr_i, type=type, display='sites',
                     xlim=xlim, ylim=ylim, cex=cexn, las=1)
     if(type=='points'){
          graphics::points(obj$nmsp$scr_o, col=ocol, pch=16, cex=0.7)
     }
     if(type=='text'){
          graphics::text(obj$nmsp$scr_o,
                         labels=row.names(obj$nmsp$scr_o),
                         col=ocol, cex=0.7)
     }
}
#' @export
#' @rdname ngnn
# extractor function for species composition in predicted target sites
`ngnn_get_spp` <- function(obj, ...){
     obj$spp_imputed
}
#' @export
#' @rdname ngnn
# inspect species response curves from NPMR
`ngnn_plot_spp` <- function(obj, pick=NULL, zlim, nm, ...){
     stopifnot(class(obj)=='ngnn')
     spe <- obj$spe
     obj <- obj$np_mods
     ev <- 30
     wasmissing <- missing(zlim)
     if(is.null(pick)) pick <- c(1:ncol(spe))
     if(is.character(pick)) pick <- which(names(spe) %in% pick)
     `fn5` <- function (nn=length(pick)) {
          if (nn <= 3)  c(1, nn)
          else if (nn <= 6)  c(2, (nn + 1)%/%2)
          else if (nn <= 12) c(3, (nn + 2)%/%3)
          else c(ceiling( nn / (nr <- ceiling(sqrt(nn)))), nr)
     }
     x1 <- seq(min(obj[[1]]$eval[[1]]),max(obj[[1]]$eval[[1]]),len=ev)
     x2 <- seq(min(obj[[1]]$eval[[2]]),max(obj[[1]]$eval[[2]]),len=ev)
     dd <- expand.grid(x1, x2)
     names(dd) <- nm
     graphics::par(mfrow=c(fn5()[1], fn5()[2]),
                   oma=c(0,0,0,0), mar=c(0,0,.9,0))
     cat('Plotting species response curves, just a moment...\n')
     for (i in pick){
          f <- matrix(stats::predict(obj[[i]], newdata=dd), ev, ev)
          if(wasmissing) {
               if(identical(min(f), max(f))) mn <- 0 else mn <- min(f)
               zlim <- c(mn*0.9, max(f)*1.1)
          }
          graphics::persp(x1, x2, f, col='lightblue',
                          main=names(obj)[[i]],
                          xlab=nm[[1]], ylab=nm[[2]], zlab='',
                          theta=125, phi=35, d=1.5, ltheta = -30,
                          lphi = 55, shade=0.9, ticktype='d',
                          expand=0.7, zlim=zlim)

     }
}