library(sicr)
library(testthat)

## Mini-Eingabe: keine bekannten Grossschaeden, nur ein IBNR-Spaetgrossschaden
## (Anfalljahr 2021). Historische Daten sind mit 0 belegt (Dev_year_since_large = 0).

zero_claims_data <- function() {
   data.frame(Claim_id = "S1",
              Origin_year = 2020L,
              Calendar_year = 2020L,
              Dev_year_since_large = 0L,  # Kleinschaden -> generate_triangle() setzt auf 0
              Cl_payment_cal = 999,
              Cl_reserve = 999,
              An_payment_cal = 999,
              An_reserve = 999,
              stringsAsFactors = FALSE)
}

empty_claims_list <- function() {
   data.frame(Claim_id = character(0),
              Origin_year = integer(0),
              stringsAsFactors = FALSE)
}

mini_indices <- function() {
   indices <- data.frame(Calendar_year = 2020:2271,
                         Index_gross = 0,
                         Index_re = 0)
   attr(indices, "index_year") <- 2021
   indices
}

mini_sim_result <- function() {
   # eine Zeile fuer den IBNR-Schaden, Matrix 1 = Bruttozahlungen
   result <- array(0, dim = c(1L, 250L, 7L))
   result[1, 1, 1] <- 50
   attr(result, "ibnr_list") <- data.frame(Origin_year = 2021L,
                                           Dev_year_of_growing_large = 1L)
   result
}

test_that("E-F03: leere Liste bekannter Grossschaeden bricht mit unklarem Fehler ab", {
   expect_error(aggregate_large_claims_results(sim_result = mini_sim_result(),
                                               large_claims_list = empty_claims_list(),
                                               large_extended_claims_data = zero_claims_data(),
                                               history = NULL,
                                               reinsurance = NULL,
                                               indices = mini_indices(),
                                               first_orig_year = 2020,
                                               last_orig_year = 2021),
                "cashflow must have same number of rows")
})

test_that("E-F03: Korrektur liefert Nullmatrizen fuer die bekannten Schaeden", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-F03.R"),
          local = TRUE)

   result <- aggregate_large_claims_results_v(sim_result = mini_sim_result(),
                                              large_claims_list = empty_claims_list(),
                                              large_extended_claims_data = zero_claims_data(),
                                              history = NULL,
                                              reinsurance = NULL,
                                              indices = mini_indices(),
                                              first_orig_year = 2020,
                                              last_orig_year = 2021)

   expect_equal(dim(result$large_claims_payments), c(2L, 252L))
   expect_true(all(result$large_claims_payments == 0))
   expect_true(all(result$large_claims_reserved == 0))
   expect_equal(unname(result$large_ibnr_payments["2021", "2022"]), 50)
})
