library(sicr)
library(testthat)

## Mini-Eingabe, siehe befunde/test-E-F01.R: zwei bekannte Grossschaeden (2020, 2021).

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
   # Zeilen absichtlich nicht nach Origin_year sortiert: 2021 zuerst, dann 2020
   data.frame(Origin_year = c(2021L, 2020L),
              Priority = c(0, 0),
              Limit = c(1e9, 1e9),
              Base_year = c(0L, 0L),
              Margin_type = c("none", "none"),
              Margin = c(0, 0),
              Quota_share = c(0.5, 0.1),
              stringsAsFactors = FALSE)
}

mini_sim_result <- function() {
   result <- array(0, dim = c(2L, 250L, 7L))
   attr(result, "ibnr_list") <- data.frame(Origin_year = integer(0),
                                           Dev_year_of_growing_large = integer(0))
   result
}

run_aggregate <- function(fun) {
   sim_result <- mini_sim_result()
   sim_result[1, 1, 3] <- 100 # Anfalljahr 2020: 100 Zahlung in 2022
   sim_result[2, 1, 3] <- 200 # Anfalljahr 2021: 200 Zahlung in 2022

   fun(sim_result = sim_result,
       large_claims_list = mini_claims_list(),
       large_extended_claims_data = mini_claims_data(),
       history = mini_history(),
       reinsurance = mini_reinsurance(),
       indices = mini_indices(),
       first_orig_year = 2020,
       last_orig_year = 2021)
}

test_that("E-F02: Quote wird ueber die Zeilenposition statt ueber das Anfalljahr zugeordnet", {
   result <- run_aggregate(aggregate_large_claims_results)

   # fehlerhaft: die erste Zeile von reinsurance (2021, Quote 0.5) wirkt auf das Anfalljahr
   # 2020 und die zweite Zeile (2020, Quote 0.1) auf 2021. Richtig sind 10 bzw. 100.
   expect_equal(unname(result$large_ceded_quota_payments["2020", "2022"]), 50)
   expect_equal(unname(result$large_ceded_quota_payments["2021", "2022"]), 20)
})

test_that("E-F02: Korrektur ordnet die Quote dem Anfalljahr zu", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-F02.R"),
          local = TRUE)

   result <- run_aggregate(aggregate_large_claims_results_v)

   expect_equal(unname(result$large_ceded_quota_payments["2020", "2022"]), 10)
   expect_equal(unname(result$large_ceded_quota_payments["2021", "2022"]), 100)
})
