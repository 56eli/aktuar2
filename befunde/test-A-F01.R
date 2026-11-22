library(testthat)
library(sicr)

# ---------------------------------------------------------------------------
# A-F01: Bei den Nachlaufpools werden die Ausreisser-Grenzen erst NACH der
# Hochskalierung auf das Niveau des ersten Nachlaufjahres angewandt
# (R/generate_pools.R:130-139). Die Doku von generate_pools() definiert die
# Grenzen aber auf dem Niveau von index_year (Rd: "at the niveau of index_year").
# ---------------------------------------------------------------------------

# Mini-Datensatz: zwei Nachlaufbeobachtungen im Abwicklungsjahr 50 (T=50),
# start_of_tail = 17 (M = 16). tail_factor(50, 17, 50) = 1/34, d.h. die
# Zahlungen werden fuer den Nachlaufpool mit Faktor 34 hochskaliert.
extended_claims_data <- data.frame(
   Ind_cl_payment_cal   = c(1000, -1000),
   Exit_reserve_class   = c(0L, 0L),
   New_annuity_1        = 0, New_annuity_2 = 0, New_annuity_3 = 0,
   New_annuity_4        = 0, New_annuity_5 = 0,
   Dev_year_since_large = c(50L, 50L),
   Entry_reserve_class  = c(0L, 0L),
   Calendar_year        = c(2020L, 2020L),
   Ind_entry_cl_reserve = c(0, 0)
)
attr(extended_claims_data, "threshold") <- 400000
attr(extended_claims_data, "index_year") <- 2020

args_pools <- list(extended_claims_data = extended_claims_data,
                   reserve_classes = c(1),
                   years_for_pools = 2020L,
                   start_of_tail = 17,
                   end_of_tail = 50,
                   pool_of_annuities = NULL)

test_that("A-F01: Nachlauf-Grenzen wirken auf dem falschen (hochskalierten) Niveau", {
   # ohne Grenzen: korrekte Hochskalierung 1000 / (1/34) = 34000
   pools_free <- do.call(generate_pools,
                         c(args_pools, list(lower_outlier_limit = -Inf,
                                            upper_outlier_limit = Inf)))
   expect_equal(pools_free[[2]][[1]]$Ind_cl_payment_cal, c(34000, -34000))

   # mit Grenzen: die Grenzen sind auf index_year-Niveau definiert, muessten also
   # ebenfalls 34000 bzw. -17000 ergeben (1000 bzw. -500 hochskaliert).
   pools_limited <- do.call(generate_pools,
                            c(args_pools, list(lower_outlier_limit = -500,
                                               upper_outlier_limit = 1000)))

   # Fehlerbeleg: aktuell werden die bereits hochskalierten Werte gekappt.
   expect_equal(pools_limited[[2]][[1]]$Ind_cl_payment_cal, c(1000, -500))
})

test_that("A-F01: generate_pools_v() kappt vor der Hochskalierung", {
   root <- Sys.getenv("AKTUAR_ROOT", "../..")
   source(file.path(root, "verbesserungen", "A-F01.R"))

   pools_limited_v <- do.call(generate_pools_v,
                              c(args_pools, list(lower_outlier_limit = -500,
                                                 upper_outlier_limit = 1000)))
   expect_equal(pools_limited_v[[2]][[1]]$Ind_cl_payment_cal, c(34000, -17000))
})
