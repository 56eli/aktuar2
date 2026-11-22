library(testthat)
library(sicr)

# ---------------------------------------------------------------------------
# A-V01: pools2dataframe() verbessert (kein rbind() in verschachtelten Schleifen).
# Der Test prueft die Ergebnisgleichheit auf einer konstruierten Pools-Struktur.
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "A-V01.R"))

make_pool_data <- function(payment, exit_class = 0) {
   n <- length(payment)
   data.frame(Ind_cl_payment_cal = as.numeric(payment),
              Exit_reserve_class = rep(as.numeric(exit_class), length.out = n),
              New_annuity_1 = rep(0, n), New_annuity_2 = rep(0, n),
              New_annuity_3 = rep(0, n), New_annuity_4 = rep(0, n),
              New_annuity_5 = rep(0, n),
              Ind_entry_cl_reserve = rep(0, n))
}

# 3 Reserveklassen (0,1,2), Pretail-Abwicklungsjahre 2 und 3, danach Nachlauf.
pools <- list(
   list(list(make_pool_data(c(10, 20), 0), make_pool_data(30, 0)),
        list(make_pool_data(40, 1), make_pool_data(50, 1)),
        list(make_pool_data(60, 2), make_pool_data(70, 2))),
   list(make_pool_data(c(100, 200, 300), 0),
        make_pool_data(400, 1),
        make_pool_data(c(500, 600), 2)),
   NULL)
attr(pools, "reserve_classes") <- c(1, 10)
attr(pools, "start_of_tail") <- 4
attr(pools, "end_of_tail") <- 10

strip_types <- function(df) {
   df[] <- lapply(df, as.numeric)
   df <- df[do.call(order, unname(as.list(df))), ]
   rownames(df) <- NULL
   df
}

test_that("A-V01: pools2dataframe_v() liefert dasselbe Ergebnis", {
   original <- pools2dataframe(pools)
   verbessert <- pools2dataframe_v(pools)
   expect_equal(strip_types(verbessert), strip_types(original))
})
