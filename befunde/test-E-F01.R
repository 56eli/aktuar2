library(sicr)
library(testthat)

## Mini-Eingabe fuer aggregate_large_claims_results(): zwei bekannte Grossschaeden
## (Anfalljahre 2020 und 2021), zwei historische Kalenderjahre. Bewusst konstruiert,
## damit der Test klein und schnell bleibt.

mini_claims_list <- function() {
   data.frame(Claim_id = c("C1", "C2"),
              Origin_year = c(2020L, 2021L),
              stringsAsFactors = FALSE)
}

mini_claims_data <- function() {
   data.frame(Claim_id = c("C1", "C2"),
              Origin_year = c(2020L, 2021L),
              Calendar_year = c(2020L, 2021L),
              Dev_year_since_large = c(1L, 1L),
              Cl_payment_cal = c(10, 20),
              Cl_reserve = c(100, 200),
              An_payment_cal = c(0, 0),
              An_reserve = c(0, 0),
              stringsAsFactors = FALSE)
}

mini_history <- function() {
   matrix(c(10, 0, 0, 20), nrow = 2,
          dimnames = list(c("C1", "C2"), c("2020", "2021")))
}

mini_indices <- function() {
   indices <- data.frame(Calendar_year = 2020:2271,
                         Index_gross = 0,
                         Index_re = 0)
   attr(indices, "index_year") <- 2021
   indices
}

mini_reinsurance <- function() {
   # Zeilen absichtlich nicht nach Origin_year sortiert
   data.frame(Origin_year = c(2021L, 2020L),
              Priority = c(0, 0),
              Limit = c(1e9, 1e9),
              Base_year = c(0L, 0L),
              Margin_type = c("none", "none"),
              Margin = c(0, 0),
              Quota_share = c(0.5, 0.1),
              stringsAsFactors = FALSE)
}

mini_sim_result <- function(n_ibnr = 0L) {
   result <- array(0, dim = c(2L + n_ibnr, 250L, 7L),
                   dimnames = list(c("C1", "C2", rep("IBNR", n_ibnr))[seq_len(2L + n_ibnr)],
                                   as.character(2022:2271),
                                   c("Gross_sum", "Reinsurance_sum", "Claim_payments",
                                     "Active_annuities_payments", "Future_annuities_payments",
                                     "Reinsurance_xl", "Reinsurance_quota_share")))
   attr(result, "ibnr_list") <- data.frame(Origin_year = rep(2021L, n_ibnr),
                                           Dev_year_of_growing_large = rep(1L, n_ibnr))
   result
}

test_that("E-F01: XL-Anteil der IBNR-Spaetgrossschaeden fehlt in large_ceded_xl_payments", {
   sim_result <- mini_sim_result(n_ibnr = 1L)
   sim_result[1, 1, 3] <- 100 # bekannter Schaden 2020: 100 Zahlung in 2022
   sim_result[2, 1, 3] <- 200 # bekannter Schaden 2021: 200 Zahlung in 2022
   sim_result[3, 1, 1] <- 200 # IBNR-Schaden (Anfalljahr 2021): 200 Bruttozahlung in 2022
   sim_result[3, 1, 6] <- 200 # IBNR-Schaden: 200 davon entfallen auf den XL-Rueckversicherer

   result <- aggregate_large_claims_results(sim_result = sim_result,
                                            large_claims_list = mini_claims_list(),
                                            large_extended_claims_data = mini_claims_data(),
                                            history = mini_history(),
                                            reinsurance = mini_reinsurance(),
                                            indices = mini_indices(),
                                            first_orig_year = 2020,
                                            last_orig_year = 2021)

   # fehlerhaft: Zeile 2021 der XL-Zahlungen enthaelt nur den XL-Anteil der bekannten
   # Schaeden (hier 0). Richtig waeren 200 aus sim_result[3, 1, 6], denn der Quotenanteil
   # der IBNR-Zeile wird in Zeile 193 sehr wohl beruecksichtigt. Netto = Brutto - gedeckt
   # ist damit zu hoch (Paper S. 55).
   expect_equal(unname(result$large_ceded_xl_payments["2021", "2022"]), 0)
   # die Brutto-IBNR-Zahlung ist vorhanden, nur der XL-Anteil fehlt
   expect_equal(unname(result$large_ibnr_payments["2021", "2022"]), 200)
})

test_that("E-F01: Korrektur nimmt den XL-Anteil der IBNR-Zeilen mit auf", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-F01.R"),
          local = TRUE)

   sim_result <- mini_sim_result(n_ibnr = 1L)
   sim_result[1, 1, 3] <- 100
   sim_result[2, 1, 3] <- 200
   sim_result[3, 1, 1] <- 200
   sim_result[3, 1, 6] <- 200

   result <- aggregate_large_claims_results_v(sim_result = sim_result,
                                              large_claims_list = mini_claims_list(),
                                              large_extended_claims_data = mini_claims_data(),
                                              history = mini_history(),
                                              reinsurance = mini_reinsurance(),
                                              indices = mini_indices(),
                                              first_orig_year = 2020,
                                              last_orig_year = 2021)

   expect_equal(unname(result$large_ceded_xl_payments["2021", "2022"]), 200)
   # unveraendert: bekannte Schaeden ohne XL-Anteil
   expect_equal(unname(result$large_ceded_xl_payments["2020", "2022"]), 0)
})
