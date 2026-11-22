library(testthat)
library(sicr)

# ---------------------------------------------------------------------------
# A-F02: Fuer start_of_tail <= 2 liefert 2:(start_of_tail - 1) eine absteigende
# Folge. In generate_pools() (R/generate_pools.R:73) entstehen dann Pretail-Pools
# fuer Abwicklungsjahr 1 (bzw. 1 und 0), in pools2matrix() (R/sampling_preparation.R:85) laeuft die Schleife ebenfalls
# absteigend bzw. greift bei korrekt leerer Pretail-Liste auf lengths_vector[0] zu.
# Zusaetzlich wird eine Beobachtung im
# Abwicklungsjahr 2 doppelt (Pretail und Nachlauf) verwendet.
# ---------------------------------------------------------------------------

extended_claims_data <- data.frame(
   Ind_cl_payment_cal   = 10,
   Exit_reserve_class   = 0L,
   New_annuity_1        = 0, New_annuity_2 = 0, New_annuity_3 = 0,
   New_annuity_4        = 0, New_annuity_5 = 0,
   Dev_year_since_large = 2L,
   Entry_reserve_class  = 0L,
   Calendar_year        = 2020L,
   Ind_entry_cl_reserve = 0
)
attr(extended_claims_data, "threshold") <- 400000
attr(extended_claims_data, "index_year") <- 2020

args_pools <- list(extended_claims_data = extended_claims_data,
                   reserve_classes = c(1),
                   years_for_pools = 2020L,
                   start_of_tail = 2,
                   end_of_tail = 5,
                   lower_outlier_limit = -Inf,
                   upper_outlier_limit = Inf,
                   pool_of_annuities = NULL)

test_that("A-F02: start_of_tail = 2 erzeugt falsche Pretail-Pools", {
   pools <- do.call(generate_pools, args_pools)

   # korrekt waeren 0 Pretail-Pools (Pretail umfasst 2 ... start_of_tail - 1 = 2 ... 1)
   expect_length(pools[[1]][[1]], 2)          # Fehlerbeleg: Abwicklungsjahr 1 und 2
   expect_length(pools[[1]][[2]], 2)
   expect_equal(pools[[1]][[1]][[1]]$Ind_cl_payment_cal, 10) # Jahr 2
   expect_equal(pools[[1]][[1]][[2]]$Ind_cl_payment_cal, 0)  # Jahr 1 (Dummy)

   # dieselbe Beobachtung steckt zusaetzlich im Nachlaufpool
   expect_equal(pools[[2]][[1]]$Ind_cl_payment_cal, 10)

   # pools2matrix() leitet start_of_tail aus der (falschen) Pretail-Laenge ab
   # und erzeugt 6 statt 2 Pool-Eintraege.
   pools_as_matrix <- sicr:::pools2matrix(pools)
   expect_length(pools_as_matrix[[1]], 6)
})

test_that("A-F02: generate_pools_v() und pools2matrix_v() behandeln den Randfall", {
   root <- Sys.getenv("AKTUAR_ROOT", "../..")
   source(file.path(root, "verbesserungen", "A-F01.R"))
   source(file.path(root, "verbesserungen", "A-F02.R"))

   pools_v <- do.call(generate_pools_v, args_pools)
   expect_length(pools_v[[1]][[1]], 0)
   expect_length(pools_v[[1]][[2]], 0)
   expect_equal(NROW(pools_v[[2]][[1]]), 1)
   expect_equal(pools_v[[2]][[1]]$Ind_cl_payment_cal, 10)

   pools_as_matrix_v <- pools2matrix_v(pools_v)
   expect_length(pools_as_matrix_v[[1]], 2)          # nur die 2 Nachlaufpools
   expect_equal(NROW(pools_as_matrix_v[[2]]), 2)
   expect_equal(pools_as_matrix_v[[2]][1, 1], 10)    # Nachlauf Reserveklasse 0
   expect_equal(pools_as_matrix_v[[2]][2, 1], 0)     # Nachlauf Reserveklasse 1
})
