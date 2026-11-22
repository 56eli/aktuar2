library(sicr)
library(ggplot2)
library(dplyr)
library(tidyr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "F-F02.R"))

make_single_backtesting_input <- function() {
   sim <- array(0, dim = c(3, 1, 2),
                dimnames = list(c("D", "E", "F"), "2023", c("r1", "r2")))
   sim[1, 1, ] <- 100000
   sim[2, 1, ] <- 200000
   sim[3, 1, ] <- 300000
   attr(sim, "last_orig_year") <- 2022
   attr(sim, "large_claims_list") <- data.frame(
      Claim_id = c("D", "E", "F"),
      Origin_year = c(2000, 2001, 2002),
      Exit_reserve_class = c(1, 1, 1),
      Dev_year_since_large = c(1, 2, 3))
   new <- data.frame(
      Claim_id = c("D", "E", "F"),
      Calendar_year = 2023,
      Origin_year = c(2000, 2001, 2002),
      Entry_reserve_class = c(1, 1, 1),
      Dev_year_since_large = c(2, 3, 4),
      Cl_payment_cal = c(100000, 200000, 300000))
   list(sim = sim, new = new)
}

test_that("F-F02: Legende im Einzelschaden-Backtesting ist um zwei Baender verschoben", {
   x <- make_single_backtesting_input()
   g <- backtesting_1y_single_per_dev_year(sim_result_series_old = x$sim,
                                           extended_claims_data_new = x$new,
                                           reserve_class = 1,
                                           dev_years = 2:4)

   # Q75 ist das breite 25%-75%-Band, Q99 das aeussere 90%-99%-Band.
   # Die Funktion haengt Q75 an das 1%-99%-Band und Q99 an das 25%-75%-Band.
   labels <- g$scales$get_scales("fill")$labels
   expect_equal(unname(labels[c("Q75", "Q90", "Q99")]),
                c("1% - 99% Quantil",
                  "10% - 90% Quantil",
                  "25% - 75% Quantil"))
})

test_that("F-F02: Korrektur beschriftet die Quantilsbaender richtig", {
   x <- make_single_backtesting_input()
   g <- backtesting_1y_single_per_dev_year_v(sim_result_series_old = x$sim,
                                             extended_claims_data_new = x$new,
                                             reserve_class = 1,
                                             dev_years = 2:4)
   labels <- g$scales$get_scales("fill")$labels
   expect_equal(unname(labels[c("Q75", "Q90", "Q99")]),
                c("25% - 75% Quantil",
                  "10% - 90% Quantil",
                  "1% - 99% Quantil"))
})
