library(testthat)
library(sicr)

# ---------------------------------------------------------------------------
# Korrektheitsnachweis A-K02: Nachlaufskalierung
# Paper 2.4.4, S. 15:  Z_{M+j} = Z_{M+1} * (T - M - j + 1) / (T - M).
# Beim Aufbau der Nachlaufpools wird eine historische Zahlung Z_k aus
# Abwicklungsjahr k auf Z_{M+1} = Z_k * (T - M) / (T - k + 1) hochskaliert,
# beim Sampling wird sie mit dem Faktor fuer das Zieljahr herunterskaliert.
# Geprueft wird der komplette Pfad fuer M = 2, T = 5, k = 5 und Z_5 = 100, also
# Z_3 = 300 (erstes Nachlaufjahr), Z_4 = 200, Z_5 = 100 und 0 nach T.
# ---------------------------------------------------------------------------

extended_claims_data <- data.frame(
   Ind_cl_payment_cal   = 100,
   Exit_reserve_class   = 0L,
   New_annuity_1        = 0, New_annuity_2 = 0, New_annuity_3 = 0,
   New_annuity_4        = 0, New_annuity_5 = 0,
   Dev_year_since_large = 5L,
   Entry_reserve_class  = 0L,
   Calendar_year        = 2020L,
   Ind_entry_cl_reserve = 0
)
attr(extended_claims_data, "threshold") <- 1
attr(extended_claims_data, "index_year") <- 2020

pools <- generate_pools(extended_claims_data = extended_claims_data,
                        reserve_classes = c(1),
                        years_for_pools = 2020L,
                        start_of_tail = 3,   # M = 2
                        end_of_tail = 5,     # T = 5
                        lower_outlier_limit = -Inf,
                        upper_outlier_limit = Inf,
                        pool_of_annuities = NULL)

# Behauptung steht im Abwicklungsjahr 2, d.h. die erste simulierte Zahlung ist
# das erste Nachlaufjahr M + 1 = 3.
large_claims_list <- data.frame(Claim_id = "C1",
                                Origin_year = 2019L,
                                Exit_reserve_class = 0L,
                                Dev_year_since_large = 2L,
                                Dev_year_of_growing_large = 1L,
                                Large_since = 2019L,
                                Cl_reserve = 0,
                                Ind_cl_reserve = 0)
attr(large_claims_list, "index_year") <- 2020
attr(large_claims_list, "reserve_classes") <- c(1)

history <- matrix(0, nrow = 1, ncol = 1, dimnames = list(NULL, "2020"))

# Index mit Wachstum 0, damit die Zahlungen direkt mit der Paperformel
# vergleichbar sind (Transition_factor = 1).
indices <- data.frame(Calendar_year = as.integer(2015:2270),
                      Index_gross = 0,
                      Index_re = 0)
indices$Transition_factor <- 1
attr(indices, "index_year") <- 2020L

test_that("A-K02: Nachlaufpfad folgt der Paperformel", {
   # 100 / tail_factor(5, 3, 5) = 100 / (1/3) = 300
   expect_equal(pools[[2]][[1]]$Ind_cl_payment_cal, 300)

   result <- sicr(n = 1,
                  large_claims_list = large_claims_list,
                  first_orig_year = 2020,
                  last_orig_year = 2020,
                  pools = pools,
                  indices = indices,
                  history = history,
                  progress = FALSE,
                  summary = FALSE,
                  seed = 1)

   expect_equal(unname(result[1, 1:5, "Claim_payments"]),
                c(300, 200, 100, 0, 0))
})
