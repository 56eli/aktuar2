library(testthat)
library(sicr)

# ---------------------------------------------------------------------------
# A-F03: sicr() indiziert die 250 zukuenftigen Kalenderjahre mit
#   tail(indices$Transition_factor, 250)[year]        (R/sicr.R:451)
# und unterstellt damit, dass max(indices$Calendar_year) == last_orig_year ist.
# indices_ok() verlangt aber nur, dass last_orig_year + 250 enthalten ist
# (R/data_checks.R:507-509). Liefert indices zusaetzliche, wirtschaftlich
# identische Jahre, so verschiebt sich die gesamte Indexierung der
# Zukunftsjahre - obwohl alle fuer die Simulation noetigen Jahre unveraendert
# sind. Der Test zeigt genau diese Invarianzverletzung.
# ---------------------------------------------------------------------------

make_pool_data <- function(payment, exit_class = 0) {
   n <- length(payment)
   data.frame(Ind_cl_payment_cal = as.numeric(payment),
              Exit_reserve_class = rep(as.numeric(exit_class), length.out = n),
              New_annuity_1 = rep(0, n), New_annuity_2 = rep(0, n),
              New_annuity_3 = rep(0, n), New_annuity_4 = rep(0, n),
              New_annuity_5 = rep(0, n),
              Ind_entry_cl_reserve = rep(0, n))
}

make_mini_pools <- function(pretail_p0, reserve_classes = 1,
                            start_of_tail = 3, end_of_tail = 5,
                            index_year = 2020) {
   nrc <- length(reserve_classes) + 1
   pretail <- lapply(seq_len(nrc), function(rc) {
      list(if (rc == 1) pretail_p0 else make_pool_data(0, exit_class = rc - 1))
   })
   tail_pools <- lapply(seq_len(nrc), function(rc) {
      make_pool_data(0, exit_class = rc - 1)
   })
   pools <- list(pretail, tail_pools, NULL)
   attr(pools, "reserve_classes") <- reserve_classes
   attr(pools, "years_for_pools") <- index_year
   attr(pools, "start_of_tail") <- start_of_tail
   attr(pools, "end_of_tail") <- end_of_tail
   attr(pools, "lower_outlier_limit") <- -Inf
   attr(pools, "upper_outlier_limit") <- Inf
   attr(pools, "threshold") <- 1
   attr(pools, "index_year") <- index_year
   pools
}

# last = 2020, konstantes Wachstum 1 %; extra = 1 haengt ein weiteres (fuer die
# Simulation nicht benoetigtes) Kalenderjahr 2271 an. Die Transition_factors
# der Jahre 2015 ... 2270 sind in beiden indices identisch.
make_indices <- function(last = 2020, growth = 0.01, extra = 0) {
   years <- (last - 5):(last + 250 + extra)
   indices <- data.frame(Calendar_year = as.integer(years),
                         Index_gross = rep(growth, length(years)),
                         Index_re = rep(0, length(years)))
   cumulative <- cumprod(1 + indices$Index_gross)
   indices$Transition_factor <- cumulative / cumulative[indices$Calendar_year == last]
   attr(indices, "index_year") <- as.integer(last)
   indices
}

pools <- make_mini_pools(pretail_p0 = make_pool_data(1000, 0))

large_claims_list <- data.frame(Claim_id = "C1",
                                Origin_year = 2020L,
                                Exit_reserve_class = 0L,
                                Dev_year_since_large = 1L,
                                Dev_year_of_growing_large = 1L,
                                Large_since = 2020L,
                                Cl_reserve = 0,
                                Ind_cl_reserve = 0)
attr(large_claims_list, "index_year") <- 2020
attr(large_claims_list, "reserve_classes") <- c(1)

history <- matrix(0, nrow = 1, ncol = 1, dimnames = list(NULL, "2020"))

run_sicr <- function(indices) {
   sicr(n = 1,
        large_claims_list = large_claims_list,
        first_orig_year = 2020,
        last_orig_year = 2020,
        pools = pools,
        indices = indices,
        history = history,
        progress = FALSE,
        summary = FALSE,
        seed = 1)
}

indices_std <- make_indices(extra = 0)   # max = 2270 = last_orig_year + 250
indices_extra <- make_indices(extra = 1) # max = 2271, Jahre 2021-2270 identisch

test_that("A-F03: Zukunftsindex haengt von max(indices$Calendar_year) ab", {
   result_std <- run_sicr(indices_std)
   result_extra <- run_sicr(indices_extra)

   # Das erste Zukunftsjahr ist 2021, Transition_factor = 1.01.
   expect_equal(unname(result_std[1, 1, "Claim_payments"]), 1000 * 1.01)

   # Fehlerbeleg: mit dem zusaetzlichen Jahr wird TF(2022) = 1.01^2 verwendet.
   expect_equal(unname(result_extra[1, 1, "Claim_payments"]), 1000 * 1.01^2)

   # Eigentlich muessen beide Ergebnisse identisch sein.
   expect_false(isTRUE(all.equal(result_std[1, 1, "Claim_payments"],
                                 result_extra[1, 1, "Claim_payments"])))
})

test_that("A-F03: future_index_factors_v() waehlt die Jahre ab last_orig_year", {
   root <- Sys.getenv("AKTUAR_ROOT", "../..")
   source(file.path(root, "verbesserungen", "A-F03.R"))

   factors_std <- future_index_factors_v(indices_std, 2020)
   factors_extra <- future_index_factors_v(indices_extra, 2020)

   expect_length(factors_std, 250)
   expect_equal(factors_std[1], 1.01)
   # Die Korrektur ist invariant gegenueber dem zusaetzlichen Jahr.
   expect_equal(factors_std, factors_extra)

   # Korrigierte Indexierung des ersten Zukunftsjahres
   expect_equal(1000 * factors_extra[1], 1000 * 1.01)
})
