library(testthat)
library(sicr)

make_small_claims_inputs_f03 <- function() {
   dimnames_3 <- list(as.character(2020:2022), as.character(2020:2022))
   all_claims_paid <- matrix(c(100, 0, 0,
                               110, 120, 0,
                               130, 140, 150),
                             nrow = 3, ncol = 3,
                             dimnames = dimnames_3)
   zero_triangle <- matrix(0, nrow = 3, ncol = 3, dimnames = dimnames_3)

   large_results <- list(
      large_claims_payments = zero_triangle,
      large_claims_reserved = zero_triangle,
      large_known_annuities_payments = zero_triangle,
      large_annuities_reserved = zero_triangle)
   special_results <- list(
      special_claims_payments = zero_triangle,
      special_claims_reserved = zero_triangle,
      special_annuities_payments = zero_triangle,
      special_annuities_reserved = zero_triangle)

   indices <- data.frame(Calendar_year = 2015:2030,
                         Transition_factor = 1)
   attr(indices, "index_year") <- 2022L

   list(first_orig_year = 2020L,
        last_orig_year = 2022L,
        indices = indices,
        all_claims_paid = all_claims_paid,
        all_claims_reserved = zero_triangle,
        large_claims_list = data.frame(Claim_id = character(0),
                                       Large_since = integer(0)),
        large_claims_results = large_results,
        special_claims = data.frame(Claim_id = character(0)),
        special_claims_results = special_results,
        # absichtlich absteigend sortiert: 2022, 2021, 2020
        reinsurance = data.frame(Origin_year = c(2022L, 2021L, 2020L),
                                 Quota_share = c(0.3, 0.2, 0.1)))
}

test_that("D-F03: Quota-Share wird positionsabhaengig statt nach Anfalljahr zugeordnet", {
   inputs <- make_small_claims_inputs_f03()
   result <- do.call(compute_small_claims, inputs)

   gross <- result$small_claims_payments +
      result$small_known_annuities_payments +
      result$small_future_annuities_payments

   # Falsches, aber tatsaechliches Verhalten: Die Quote folgt der Zeilenreihenfolge
   # des RV-Datensatzes (0.3, 0.2, 0.1), nicht dem Anfalljahr
   # (richtig waere 2020 -> 0.1, 2021 -> 0.2, 2022 -> 0.3).
   expect_equal(result$small_ceded_quota_payments,
                gross * c(0.3, 0.2, 0.1),
                tolerance = 1e-12)
   expect_false(isTRUE(all.equal(result$small_ceded_quota_payments,
                                 gross * c(0.1, 0.2, 0.3))))
})

test_that("D-F03: Korrektur ordnet die Quote dem richtigen Anfalljahr zu", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-F03.R"))

   inputs <- make_small_claims_inputs_f03()
   result <- do.call(compute_small_claims_v, inputs)

   gross <- result$small_claims_payments +
      result$small_known_annuities_payments +
      result$small_future_annuities_payments

   expect_equal(result$small_ceded_quota_payments,
                gross * c(0.1, 0.2, 0.3),
                tolerance = 1e-12)
})
