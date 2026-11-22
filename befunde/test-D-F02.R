library(testthat)
library(sicr)

# Kleines, konstruiertes Basisschaden-Beispiel: drei Anfalljahre, keine
# Gross-/Sonder- und keine Rentenbestaende. Damit laesst sich der
# Rueckversicherungszweig von compute_small_claims() isoliert pruefen.
make_small_claims_inputs_f02 <- function() {
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
        special_claims_results = special_results)
}

test_that("D-F02: compute_small_claims liefert ohne RV-Programm keine Nullmatrix", {
   inputs <- make_small_claims_inputs_f02()
   result <- do.call(compute_small_claims, inputs)

   # Dokumentiert ist eine (3 x 253)-Nullmatrix; tatsaechlich wird die Summe mit
   # NULL multipliziert, weil `if (!is.null("reinsurance"))` immer wahr ist.
   # Je nach R-Version entsteht ein leerer Vektor oder eine NA-Matrix, aber
   # nicht die dokumentierte Nullmatrix.
   expect_false(isTRUE(all.equal(as.numeric(result$small_ceded_quota_payments),
                                 rep(0, 3 * 253))))
})

test_that("D-F02: Korrektur liefert die dokumentierte Nullmatrix", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-F02.R"))

   inputs <- make_small_claims_inputs_f02()
   result <- do.call(compute_small_claims_v, inputs)

   expect_equal(dim(result$small_ceded_quota_payments), c(3L, 253L))
   expect_equal(sum(result$small_ceded_quota_payments), 0)
   # Die uebrigen Ergebnisse bleiben unveraendert.
   result_original <- do.call(compute_small_claims, inputs)
   expect_equal(result$small_claims_payments, result_original$small_claims_payments)
   expect_equal(result$small_future_annuities_payments,
                result_original$small_future_annuities_payments)
})
