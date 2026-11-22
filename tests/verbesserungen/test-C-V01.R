# Gleichheitstest zu C-V01 (generate_ibnr_pools, kuerzer/vektorisiert)

library(testthat)
library(sicr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "C-V01.R"))

test_that("C-V01: vektorisierte Pools sind identisch zum Original", {
   large_claims_list <- data.frame(Claim_id = paste0("C", 1:6),
                                   Origin_year = c(2018, 2019, 2019, 2020, 2021, 2019),
                                   Dev_year_of_growing_large = c(1, 2, 3, 2, 1, 4),
                                   Large_since = c(2018, 2020, 2021, 2021, 2021, 2022))

   original <- generate_ibnr_pools(large_claims_list, 2018, 2022, 2020:2022)
   verbessert <- generate_ibnr_pools_v(large_claims_list, 2018, 2022, 2020:2022)

   expect_equal(verbessert, original)
   expect_equal(length(verbessert), 4)
   expect_equal(verbessert[[1]], c(2L, 4L))
   expect_equal(verbessert[[2]], 3L)
   expect_equal(verbessert[[3]], 6L)
   expect_equal(verbessert[[4]], integer(0))

   # Randfall: nur ein Anfalljahr
   expect_equal(generate_ibnr_pools_v(large_claims_list, 2020, 2020, 2020:2022),
                generate_ibnr_pools(large_claims_list, 2020, 2020, 2020:2022))
})
