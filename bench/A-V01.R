library(sicr)
library(bench)

# ---------------------------------------------------------------------------
# Benchmark A-V01: pools2dataframe() vs. pools2dataframe_v()
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "A-V01.R"))

set.seed(1)
grid <- expand.grid(Dev_year_since_large = 2:50,
                    Entry_reserve_class = 0:5,
                    i = 1:30)
n <- NROW(grid)

extended_claims_data <- data.frame(
   Ind_cl_payment_cal   = runif(n, 1, 100000),
   Exit_reserve_class   = grid$Entry_reserve_class,
   New_annuity_1        = 0, New_annuity_2 = 0, New_annuity_3 = 0,
   New_annuity_4        = 0, New_annuity_5 = 0,
   Dev_year_since_large = grid$Dev_year_since_large,
   Entry_reserve_class  = grid$Entry_reserve_class,
   Calendar_year        = sample(2014:2023, n, replace = TRUE),
   Ind_entry_cl_reserve = runif(n, 0, 100000))
attr(extended_claims_data, "threshold") <- 400000
attr(extended_claims_data, "index_year") <- 2020

pools <- generate_pools(extended_claims_data = extended_claims_data,
                        reserve_classes = c(1, 10, 100, 1000, 10000),
                        years_for_pools = 2014:2023,
                        start_of_tail = 17,
                        end_of_tail = 50,
                        lower_outlier_limit = -Inf,
                        upper_outlier_limit = Inf,
                        pool_of_annuities = NULL)

bench::mark(original = pools2dataframe(pools),
            verbessert = pools2dataframe_v(pools),
            check = FALSE,
            iterations = 20)
