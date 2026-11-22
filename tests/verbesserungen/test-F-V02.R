library(sicr)
library(ggplot2)
library(dplyr)
library(tidyr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "F-V02.R"))

test_that("F-V02: plot_reserve_vs_be_v liefert dieselben zwei Grafiken", {
   sim_result <- array(0, dim = c(3, 2, 2),
                       dimnames = list(c("A", "B", "C"),
                                       c("2023", "2024"),
                                       c("Claim_payments",
                                         "Future_annuities_payments")))
   sim_result[1, , 1] <- c(1e6, 2e5)
   sim_result[2, , 1] <- c(2e6, 1e5)
   sim_result[3, , 1] <- c(1.5e6, 1.5e5)
   sim_result[, , 2] <- 0

   large_claims_list <- data.frame(
      Claim_id = c("A", "B", "C"),
      Origin_year = c(2000, 2001, 2002),
      Exit_reserve_class = c(1, 2, 1),
      Dev_year_since_large = c(3, 4, 5),
      Cl_reserve = c(1.2e6, 1.8e6, 1.7e6))

   original <- plot_reserve_vs_be(large_claims_list, sim_result)
   verbessert <- plot_reserve_vs_be_v(large_claims_list, sim_result)

   expect_equal(names(original), names(verbessert))
   for (nm in names(original)) {
      original_data <- as.list(ggplot2::ggplot_build(original[[nm]])$data)
      verbessert_data <- as.list(ggplot2::ggplot_build(verbessert[[nm]])$data)
      expect_equal(original_data, verbessert_data)
   }
   expect_equal(original$plot_rc$labels, verbessert$plot_rc$labels)
   expect_equal(original$plot_dy$labels, verbessert$plot_dy$labels)
})
