plot_fixture <- local({
  cache <- new.env(parent = emptyenv())
  function(kind = "plain", missing = "DE", custom = FALSE) {
    key <- paste(kind, missing, custom)
    if (exists(key, cache, inherits = FALSE)) return(cache[[key]])
    set.seed(918)
    n <- 350; w <- rnorm(n, 3, 2); a <- rnorm(n); b <- rnorm(n)
    d1 <- 2 + .8*w + rnorm(n)
    d2 <- 1 + .4*w + .3*d1 + rnorm(n)
    y <- .5 + .6*w + .5*d1 + .7*d2 + .2*d1*w + .3*a + rnorm(n)
    y1 <- rnorm(n)
    d <- data.frame(m11=a-d1/2, m12=a+d1/2, m21=b-d2/2, m22=b+d2/2,
                    y1=y1, y2=y+y1, W=w)
    if (kind == "categorical") d$W <- factor(ifelse(w < 2, "A - low", ifelse(w < 4, "B middle", "C high")),
                                            levels=c("B middle", "A - low", "C high"))
    if (missing != "DE") d$m11[seq(1, n, 25)] <- NA
    args <- list(data=d, M_C1=c("m11","m21"), M_C2=c("m12","m22"),
      Y_C1="y1", Y_C2="y2", form=if (custom) "UD" else "P", Na=missing,
      ci_method=if (missing == "DE") "both" else "mc", R=120, bootstrap=120,
      seed=522, iseed=522, alpha=.1, standardized=TRUE, verbose=FALSE, mi_args=list(m=3))
    if (custom) args$paths <- c("M2 -> M1", "M1 -> Y")
    if (kind != "plain") {
      args$W <- "W"; args$W_type <- kind; args$MP <- c("b1","d1")
    }
    # Small bootstrap fixtures deliberately omit bootstrap p-values (<1000).
    cache[[key]] <- suppressWarnings(do.call(wsMed, args))
    cache[[key]]
  }
})

test_that("forest plots retain fitted points and the selected engine's limits", {
  x <- plot_fixture()
  for (std in c(FALSE, TRUE)) for (engine in c("mc", "boot")) {
    p <- plot_effects(x, paths=c("total_indirect","cp","indirect_effect_1"),
                      standardized=std, engine=engine)
    expect_s3_class(p, "ggplot")
    expect_equal(p$data$Path, c("total_indirect","cp","indirect_1"))
    expect_equal(attr(p,"wsmed_plot"), list(engine=engine,standardized=std,level=.9))
    expect_match(p$labels$subtitle,"90%")
    expect_no_warning(ggplot2::ggplot_build(p))
    if (engine == "mc" && !std) {
      draws <- x$mc$result$thetahatstar[, p$data$Path, drop=FALSE]
      expect_equal(p$data$Estimate, unname(x$mc$result$thetahat$est[p$data$Path]))
      ci <- apply(draws, 2, quantile, probs=c(.05,.95), names=FALSE)
      expect_equal(p$data$CI.LL, unname(ci[1,]))
      expect_equal(p$data$CI.UL, unname(ci[2,]))
    }
    if (engine == "boot") {
      tab <- if (std) x$mc$std_boot else x$param_boot
      ids <- ifelse(tab$op == ":=", tab$lhs, tab$label)
      expect_equal(p$data$CI.LL, tab$boot.ci.lower[match(p$data$Path,ids)])
      expect_equal(p$data$CI.UL, tab$boot.ci.upper[match(p$data$Path,ids)])
    }
  }
  # Make normal-theory intervals unmistakable: they must never be selected.
  x$param_boot$ci.lower <- -999; x$param_boot$ci.upper <- 999
  expect_false(any(plot_effects(x, engine="boot")$data$CI.LL == -999))
})

test_that("categorical and continuous level plots reuse conditional tables", {
  for (kind in c("categorical","continuous")) {
    x <- plot_fixture(kind)
    for (std in c(FALSE,TRUE)) for (engine in c("mc","boot")) {
      mod <- if (std) x$moderation_std[[engine]] else x$moderation[[engine]]
      tab <- if (kind == "categorical") mod$conditional_IE else mod$beta_coef
      p <- plot_conditional_effects(x,standardized=std,engine=engine)
      expect_equal(p$data$Estimate,tab$Estimate)
      expect_equal(p$data$CI.LL,tab[[grep("CI.Lo$",names(tab),value=TRUE)]])
      expect_equal(p$data$CI.UL,tab[[grep("CI.Up$",names(tab),value=TRUE)]])
      expect_no_warning(ggplot2::ggplot_build(p))
      expect_equal(attr(p,"wsmed_plot")$engine,engine)
      for (type in c("paths","overall"))
        expect_no_warning(ggplot2::ggplot_build(plot_conditional_effects(x,type=type,standardized=std,engine=engine)))
    }
    if (kind == "categorical") {
      p <- plot_conditional_effects(x,paths="indirect_effect_1", levels=c("C high","B middle"),
        labels=c(indirect_1="Via mediator one"))
      expect_equal(as.character(p$data$Group),c("C high","B middle"))
      expect_equal(levels(p$data$LevelLabel),c("C high","B middle"))
      expect_equal(as.character(p$data$PlotLabel),rep("Via mediator one",2))
    } else {
      p <- plot_conditional_effects(x,paths="indirect_1",levels=c("+1 SD","-1 SD"))
      expect_equal(p$data$W_value,subset(x$moderation$mc$beta_coef,Path=="indirect_effect_1")$W_value[c(3,1)])
      expect_true(all(grepl("W =",p$scales$scales[[1]]$labels)))
    }
  }
})

test_that("moderated contrast plots preserve direction and joint-draw intervals", {
  for (kind in c("categorical","continuous")) {
    x <- plot_fixture(kind)
    for (std in c(FALSE,TRUE)) for(engine in c("mc","boot")) {
      mod <- if(std) x$moderation_std[[engine]] else x$moderation[[engine]]
      p <- plot_contrasts(x,standardized=std,engine=engine)
      expect_equal(p$data$Contrast,mod$IE_contrasts$Contrast)
      expect_equal(p$data$Estimate,mod$IE_contrasts$Estimate)
      expect_equal(p$data$CI.LL,mod$IE_contrasts[[grep("CI.Lo$",names(mod$IE_contrasts),value=TRUE)]])
      expect_equal(p$data$CI.UL,mod$IE_contrasts[[grep("CI.Up$",names(mod$IE_contrasts),value=TRUE)]])
      expect_no_warning(ggplot2::ggplot_build(p))
      expect_no_warning(ggplot2::ggplot_build(plot_contrasts(x,type="paths",standardized=std,engine=engine)))
      if (kind == "categorical") expect_no_warning(ggplot2::ggplot_build(plot_contrasts(x,type="overall",standardized=std,engine=engine)))
      selected <- plot_contrasts(x,paths="indirect_1",contrasts=mod$IE_contrasts$Contrast[1],standardized=std,engine=engine)
      expect_equal(nrow(selected$data),1L)
    }
  }
})

test_that("unmoderated standardized contrasts transform joint draws before quantiles", {
  x <- plot_fixture()
  for (engine in c("mc","boot")) {
    for (std in c(FALSE,TRUE)) {
      p <- plot_contrasts(x,standardized=std,engine=engine)
      fit <- if(engine=="mc") x$mc$result$args$lav else x$fit_u
      raw <- if(engine=="mc") x$mc$result$thetahatstar else x$mc$theta_boot
      delta <- raw[,"indirect_2"]-raw[,"indirect_1"]
      point <- if(engine=="mc") x$mc$result$thetahat$est else ThetaHatWrapper(fit)$est
      expected_point <- unname(point["indirect_2"]-point["indirect_1"])
      if (std) {
        # Independently rebuild model-implied SDs from primitive draw parameters.
        pt <- lavaan::parameterTable(fit)
        free <- match(seq_len(fit@Model@nx.free),pt$free)
        yi <- match("Ydiff",rownames(lavaan::fitted(fit)$cov))
        sy <- vapply(seq_len(nrow(raw)),function(i) {
          model <- lavaan::lav_model_set_parameters(fit@Model,x=raw[i,free])
          sqrt(lavaan::lav_model_implied(model)$cov[[1]][yi,yi])
        },numeric(1))
        delta <- delta/sy
        expected_point <- expected_point/sqrt(lavaan::fitted(fit)$cov["Ydiff","Ydiff"])
      }
      expect_equal(p$data$Contrast,"indirect_2 - indirect_1")
      expect_equal(p$data$Estimate,expected_point,tolerance=1e-7)
      expect_equal(p$data$CI.LL,unname(quantile(delta,.05)),tolerance=1e-7)
      expect_equal(p$data$CI.UL,unname(quantile(delta,.95)),tolerance=1e-7)
    }
  }
})

test_that("curve labels use raw W bounds and the requested confidence level", {
  x <- plot_fixture("continuous")
  # Irregular grid spacing makes an index percentage visibly inappropriate.
  grid <- data.frame(Path="test",W_raw=c(-8,-3,0,2,7,40),Estimate=1,
    CI.LL=c(.1,.2,-1,-2,-3,.2),CI.UL=c(2,2,2,-.1,-.2,2))
  x$moderation$mc$theta_curve <- grid
  p <- plot_moderation_curve(x,"test")
  regions <- attr(p,"wsmed_regions")
  expect_equal(regions$xmin,c(-8,2,40))
  expect_equal(regions$xmax,c(-3,7,40))
  expect_false(any(grepl("%",regions$label)))
  expect_match(p$labels$subtitle,"90%")
  expect_false(any(grepl("p <",p$scales$scales[[1]]$labels)))
  expect_no_warning(ggplot2::ggplot_build(p))
  for (bounds in list(c(-1,1),c(1,2))) {
    x$moderation$mc$theta_curve$CI.LL <- bounds[1]
    x$moderation$mc$theta_curve$CI.UL <- bounds[2]
    p <- plot_moderation_curve(x,"test")
    expect_equal(nrow(attr(p,"wsmed_regions")),if(bounds[1]<0) 0L else 1L)
    expect_no_warning(ggplot2::ggplot_build(p))
  }
  x$moderation$mc$theta_curve$CI.LL[3] <- NA
  expect_warning(p <- plot_moderation_curve(x,"test"),"Missing curve intervals")
  expect_equal(nrow(attr(p,"wsmed_regions")),2L)
  x$moderation$mc$theta_curve <- grid[6,,drop=FALSE]
  expect_no_warning(ggplot2::ggplot_build(plot_moderation_curve(x,"test")))
})

test_that("plots support single engines, missing-data fits and custom path names", {
  for (na in c("FIML","MI")) {
    x <- plot_fixture("continuous",missing=na)
    for (std in c(FALSE,TRUE)) {
      expect_no_warning(ggplot2::ggplot_build(plot_effects(x,standardized=std)))
      expect_no_warning(ggplot2::ggplot_build(plot_conditional_effects(x,standardized=std)))
      expect_no_warning(ggplot2::ggplot_build(plot_contrasts(x,standardized=std)))
    }
  }
  x <- plot_fixture("continuous",custom=TRUE)
  expect_true("indirect_2_1" %in% plot_effects(x)$data$Path)
  expect_no_warning(ggplot2::ggplot_build(plot_conditional_effects(x,paths="indirect_2_1",standardized=TRUE)))
  x$ci_method <- "bootstrap"; x$moderation <- x$moderation$boot; x$moderation_std <- x$moderation_std$boot
  expect_equal(attr(plot_effects(x),"wsmed_plot")$engine,"boot")
  expect_equal(attr(plot_conditional_effects(x),"wsmed_plot")$engine,"boot")
  expect_equal(attr(plot_contrasts(x),"wsmed_plot")$engine,"boot")
  expect_equal(attr(plot_moderation_curve(x,"total_indirect"),"wsmed_plot")$engine,"boot")
})

test_that("invalid requests fail clearly without silently switching scale", {
  x <- plot_fixture(); w <- plot_fixture("continuous")
  expect_error(plot_effects(list()),"wsMed object")
  expect_error(plot_effects(x,paths="no_such_effect"),"Unknown Path")
  expect_error(plot_effects(x,paths=c("cp","cp")),"distinct")
  expect_error(plot_effects(x,engine="wrong"),"arg")
  expect_error(plot_effects(x,labels=c(cp="same",total_effect="same")),"distinguish")
  expect_error(plot_conditional_effects(x),"requires a moderator")
  expect_error(plot_conditional_effects(w,levels="no"),"Unknown Level")
  expect_error(plot_contrasts(x,paths="indirect_1"),"At least two")
  expect_error(plot_contrasts(w,type="overall"),"unavailable")
  expect_error(plot_moderation_curve(plot_fixture("categorical"),"total_indirect"),"continuous")
  w$moderation_std <- NULL
  expect_error(plot_conditional_effects(w,standardized=TRUE),"Standardized conditional results")
  x$mc$std_mc <- NULL
  expect_error(plot_effects(x,standardized=TRUE),"Standardized parameter results")
  x$alpha <- c(.05,.1)
  expect_error(plot_effects(x),"single alpha")
})
