context("div_minimizer")

test_that("divmin() works", {
  skip_on_cran()
  for (tstsetup in names(fits)) {
    args_fit_i <- args_fit[[tstsetup]]
    pkg_crr <- args_fit_i$pkg_nm
    mod_crr <- args_fit_i$mod_nm
    fam_crr <- args_fit_i$fam_nm

    if (fam_crr == "gauss") {
      mu_crr <- posterior_linpred(fits[[tstsetup]])
      # Crude approximations for the predictive variances:
      var_crr <- mean(as.matrix(fits[[tstsetup]])[, "sigma"]^2) +
        (colMeans(mu_crr^2) - colMeans(mu_crr)^2)
    } else {
      var_crr <- rep(NA, nobsv)
    }
    args_fit_i$projpred_var <- matrix(var_crr)
    args_fit_i$projpred_regul <- regul_default

    if (pkg_crr == "brms" && grepl("\\.with_wobs", tstsetup)) {
      args_fit_i$formula <- rm_addresp(args_fit_i$formula)
      args_fit_i$weights <- eval(args_fit_i$data)$wobs_col
    }

    if (fam_crr == "binom") {
      # Use the proportion of successes as (1-column) response and the number of
      # trials as `weights`:
      ybinprop_nm <- paste("ybinprop", mod_crr, sep = "_")
      args_fit_i$data <- within(dat, {
        assign(ybinprop_nm,
               get(paste("y", mod_crr, fam_crr, sep = "_")) / wobs_col)
      })
      args_fit_i$formula <- update(
        args_fit_i$formula,
        as.formula(paste(ybinprop_nm, "~ ."))
      )
      args_fit_i$weights <- wobs_tst
    } else if (fam_crr == "brnll") {
      if (pkg_crr == "brms") {
        args_fit_i$family <- f_binom
      }
    }

    if ("random" %in% names(args_fit_i)) {
      args_fit_i$formula <- update(
        args_fit_i$formula,
        as.formula(paste(". ~ . +", tail(as.character(args_fit_i$random), 1)))
      )
    }

    divmin_res <- do.call(
      divmin,
      args_fit_i[intersect(c("formula", "data", "family", "weights",
                             "projpred_var", "projpred_regul"),
                           names(args_fit_i))]
    )

    if (fam_crr == "binom" || grepl("\\.with_wobs", tstsetup)) {
      wobs_expected_crr <- wobs_tst
    } else {
      wobs_expected_crr <- NULL
    }
    submodl_tester(divmin_res,
                   nprjdraws_expected = 1L,
                   sub_formul = list(args_fit_i$formula),
                   sub_data = eval(args_fit_i$data),
                   sub_fam = eval(args_fit_i$family)$family,
                   wobs_expected = wobs_expected_crr,
                   with_offs = grepl("\\.with_offs", tstsetup),
                   info_str = tstsetup)
  }
})
