library(testthat)
library(sicr)

# ---------------------------------------------------------------------------
# Korrektheitsnachweis A-K01:
# Der Erwartungswert eines Ziehungsschritts aus einem Pool P(i,rk) muss das
# arithmetische Mittel der Pool-Zahlungen sein (Paper 1.3, S. 7-8; 2.4.3, S. 14:
# "wird zufaellig eine der n Zeilen des Pools ausgewaehlt"). Zusaetzlich wird
# geprueft, dass nur die echten Pool-Zeilen und nicht die Null-Auffuellzeilen der
# sample_matrix gezogen werden.
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

make_mini_pools <- function(pretail_p0, tail_p0 = NULL,
                            reserve_classes = 1,
                            start_of_tail = 3, end_of_tail = 5,
                            index_year = 2020) {
   nrc <- length(reserve_classes) + 1
   n_pretail <- max(0, start_of_tail - 2)

   pretail <- lapply(seq_len(nrc), function(rc) {
      lapply(seq_len(n_pretail), function(i) {
         if (rc == 1 && i == 1 && !is.null(pretail_p0)) return(pretail_p0)
         make_pool_data(0, exit_class = rc - 1)
      })
   })

   tail_pools <- lapply(seq_len(nrc), function(rc) {
      if (rc == 1 && !is.null(tail_p0)) return(tail_p0)
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

make_indices <- function(last = 2020, growth = 0) {
   years <- (last - 5):(last + 250)
   indices <- data.frame(Calendar_year = as.integer(years),
                         Index_gross = rep(growth, length(years)),
                         Index_re = rep(0, length(years)))
   cumulative <- cumprod(1 + indices$Index_gross)
   indices$Transition_factor <- cumulative / cumulative[indices$Calendar_year == last]
   attr(indices, "index_year") <- as.integer(last)
   indices
}

# Pool P(2,0) mit Zahlungen 10, 20, 60 (Mittel 30); der Nachlaufpool der
# Reserveklasse 0 hat 5 Zeilen, damit die sample_matrix fuer P(2,0) zwei
# Null-Auffuellzeilen enthaelt.
pools <- make_mini_pools(pretail_p0 = make_pool_data(c(10, 20, 60), 0),
                         tail_p0 = make_pool_data(rep(0, 5), 0))

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

test_that("A-K01: Erwartungswert eines Ziehungsschritts ist das Poolmittel", {
   result <- sicr(n = 2000,
                  large_claims_list = large_claims_list,
                  first_orig_year = 2020,
                  last_orig_year = 2020,
                  pools = pools,
                  indices = make_indices(last = 2020, growth = 0),
                  history = history,
                  progress = FALSE,
                  summary = FALSE,
                  seed = 42)

   # Output enthaelt bereits den Mittelwert ueber die 2000 Realisationen.
   mean_payment <- unname(result[1, 1, "Claim_payments"])

   # Standardfehler: sd(c(10,20,60)) = 21.60, n = 2000 -> SE = 0.483.
   # Toleranz 2.5 entspricht ca. 5.2 Standardfehlern.
   expect_lt(abs(mean_payment - 30), 2.5)

   # Nach dem ersten Schritt wird aus dem Nachlaufpool (nur Nullen) gezogen.
   expect_equal(unname(result[1, 2, "Claim_payments"]), 0)
})
