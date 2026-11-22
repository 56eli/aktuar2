library(sicr)
library(ggplot2)
library(dplyr)
library(tidyr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "F-V01.R"))

make_pools <- function(K, start_of_tail = 6, end_of_tail = 10) {
   pretail <- list()
   for (rc in 0:K) {
      pretail[[rc + 1]] <- list()
      for (dy in 1:(start_of_tail - 2)) {
         n <- if (rc == 0) 5 else 1
         pretail[[rc + 1]][[dy]] <- data.frame(
            Ind_cl_payment_cal = rep(1, n),
            Exit_reserve_class = rep(rc, n),
            New_annuity_1 = 0, New_annuity_2 = 0, New_annuity_3 = 0,
            New_annuity_4 = 0, New_annuity_5 = 0,
            Ind_entry_cl_reserve = rep(1, n))
      }
   }
   tail_pools <- lapply(0:K, function(rc) {
      data.frame(Ind_cl_payment_cal = 1, Exit_reserve_class = rc,
                 New_annuity_1 = 0, New_annuity_2 = 0, New_annuity_3 = 0,
                 New_annuity_4 = 0, New_annuity_5 = 0,
                 Ind_entry_cl_reserve = 1)
   })
   pools <- list(pretail, tail_pools, data.frame())
   attr(pools, "reserve_classes") <- c(1, seq(200001, by = 200000, length.out = K - 1))
   attr(pools, "start_of_tail") <- start_of_tail
   attr(pools, "end_of_tail") <- end_of_tail
   pools
}

test_that("F-V01: plot_pools_overview_v liefert dieselben vier Grafiken", {
   pools <- make_pools(5)
   large_claims_list <- data.frame(
      Claim_id = paste0("C", 1:12),
      Origin_year = 2000,
      Exit_reserve_class = rep(0:5, 2),
      Dev_year_since_large = 2,
      Cl_reserve = c(rep(0, 2), rep(300000, 10)),
      Ind_cl_reserve = c(rep(0, 2), rep(300000, 10)))

   original <- plot_pools_overview(pools, large_claims_list)
   verbessert <- plot_pools_overview_v(pools, large_claims_list)

   expect_equal(names(original), names(verbessert))
   for (nm in names(original)) {
      original_data <- as.list(ggplot2::ggplot_build(original[[nm]])$data)
      verbessert_data <- as.list(ggplot2::ggplot_build(verbessert[[nm]])$data)
      expect_equal(original_data, verbessert_data)
   }
})
