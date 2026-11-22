library(sicr)
library(ggplot2)
library(dplyr)
library(tidyr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "F-F01.R"))

# Kleines, deterministisches Beispiel: die alte Simulation sagt fuer 2023
# nominal 1.000.000 voraus. Die neuen Daten enthalten die Zahlung nominal
# (Cl_payment_cal) und auf das Indexjahr 2022 deflationiert
# (Ind_cl_payment_cal = 1.000.000 / 1.03).
make_backtesting_input <- function() {
   sim <- array(0, dim = c(2, 1, 2),
                dimnames = list(c("A", "B"), "2023", c("r1", "r2")))
   sim[1, 1, ] <- 0
   sim[2, 1, ] <- 1e6
   attr(sim, "last_orig_year") <- 2022
   attr(sim, "large_claims_list") <- data.frame(
      Claim_id = c("A", "B"),
      Origin_year = c(2000, 2001),
      Exit_reserve_class = c(0, 1),
      Dev_year_since_large = c(3, 4))
   new <- data.frame(
      Claim_id = c("A", "B"),
      Calendar_year = 2023,
      Cl_payment_cal = c(0, 1e6),
      Ind_cl_payment_cal = c(0, 1e6 / 1.03))
   list(sim = sim, new = new)
}

test_that("F-F01: 1y-Backtesting vergleicht nominale Erwartung mit indexiertem Ist", {
   x <- make_backtesting_input()

   # Erwartungswert der Simulation ist nominal (Zahlungsjahr 2023),
   # der Ist-Wert wird dagegen mit Ind_cl_payment_cal auf 2022 deflationiert.
   g <- backtesting_1y_per_reserve_class(sim_result_series_old = x$sim,
                                         extended_claims_data_new = x$new)
   d <- g$data
   expected <- d$Value[d$Type == "Expected" &
                          as.character(d$Reserve_class) == "1"]
   actual <- d$Value[d$Type == "Actual" &
                        as.character(d$Reserve_class) == "1"]
   expect_equal(expected, 1e6)
   expect_equal(actual, 1e6 / 1.03, tolerance = 1e-8)

   g2 <- backtesting_1y_per_origin_year(sim_result_series_old = x$sim,
                                        extended_claims_data_new = x$new)
   d2 <- g2$data
   expected2 <- d2$Value[d2$Type == "Expected" &
                            as.character(d2$Origin_year) == "2001"]
   actual2 <- d2$Value[d2$Type == "Actual" &
                          as.character(d2$Origin_year) == "2001"]
   expect_equal(expected2, 1e6)
   expect_equal(actual2, 1e6 / 1.03, tolerance = 1e-8)
})

test_that("F-F01: Korrektur vergleicht Erwartung und Ist auf nominaler Basis", {
   x <- make_backtesting_input()

   g <- backtesting_1y_per_reserve_class_v(sim_result_series_old = x$sim,
                                           extended_claims_data_new = x$new)
   d <- g$data
   expect_equal(d$Value[d$Type == "Expected" &
                           as.character(d$Reserve_class) == "1"], 1e6)
   expect_equal(d$Value[d$Type == "Actual" &
                           as.character(d$Reserve_class) == "1"], 1e6)

   g2 <- backtesting_1y_per_origin_year_v(sim_result_series_old = x$sim,
                                          extended_claims_data_new = x$new)
   d2 <- g2$data
   expect_equal(d2$Value[d2$Type == "Expected" &
                            as.character(d2$Origin_year) == "2001"], 1e6)
   expect_equal(d2$Value[d2$Type == "Actual" &
                            as.character(d2$Origin_year) == "2001"], 1e6)
})
