library(sicr)
library(ggplot2)
library(dplyr)
library(tidyr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "F-F03.R"))

make_multiyear_input <- function() {
   sim <- array(0, dim = c(1, 250, 2),
                dimnames = list("A", as.character(2023:2272), c("r1", "r2")))
   sim[1, 1:2, ] <- 100000
   attr(sim, "last_orig_year") <- 2022
   attr(sim, "large_claims_list") <- data.frame(
      Claim_id = "A",
      Origin_year = 2000,
      Exit_reserve_class = 1,
      Dev_year_since_large = 3)
   new <- data.frame(Claim_id = "A", Calendar_year = 2022, Cl_payment_cal = 0)
   list(sim = sim, new = new)
}

test_that("F-F03: Mehrjahres-Backtesting erfindet ohne Folgejahr ein zweites Jahr", {
   x <- make_multiyear_input()

   # reserving_year = 2022, max(Calendar_year) = 2022 => n_years = 0.
   # Die Schleife 1:0 laeuft trotzdem zweimal, und Year wird zu c(2023, 2022).
   g <- backtesting_multiyears(sim_result_series_old = x$sim,
                               extended_claims_data_new = x$new,
                               reserve_classes = 1,
                               dev_years = 3)
   expect_equal(nrow(g$data), 2)
   expect_equal(sort(g$data$Year), c(2022, 2023))
})

test_that("F-F03: Korrektur bricht bei fehlendem Folgejahr verstaendlich ab", {
   x <- make_multiyear_input()
   expect_error(backtesting_multiyears_v(sim_result_series_old = x$sim,
                                         extended_claims_data_new = x$new,
                                         reserve_classes = 1,
                                         dev_years = 3),
                "at least one calendar year")
})
