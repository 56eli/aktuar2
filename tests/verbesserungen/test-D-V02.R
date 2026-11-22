library(testthat)
library(sicr)

test_that("D-V02: rollout_best_estimate_v liefert dasselbe wie das Original", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-V02.R"))

   best_estimate <- c(100, 400, 1000)
   pattern <- c(1.7, 1.3, 1.05, 1, 1)
   dev_year <- 3:1

   expect_equal(rollout_best_estimate_v(best_estimate, pattern, dev_year),
                sicr:::rollout_best_estimate(best_estimate, pattern, dev_year))

   # dev_year zu gross: Best Estimate wird in das erste Folgejahr gelegt
   expect_equal(rollout_best_estimate_v(c(10, 20), c(1.2, 1.1), c(1, 2)),
                sicr:::rollout_best_estimate(c(10, 20), c(1.2, 1.1), c(1, 2)))

   # Division 0/0 bzw. endlicher Best Estimate bei Settlement Rate 1
   expect_equal(rollout_best_estimate_v(c(0, 100), c(1, 1), c(1, 2)),
                sicr:::rollout_best_estimate(c(0, 100), c(1, 1), c(1, 2)))

   # Vektorlaenge 1
   expect_equal(rollout_best_estimate_v(1000, c(1.7, 1.3, 1.1), 1),
                sicr:::rollout_best_estimate(1000, c(1.7, 1.3, 1.1), 1))
})
