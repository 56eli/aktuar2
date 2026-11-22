library(sicr)

test_that("B-F04 cum2inc liefert fuer einen leeren Vektor NA statt numeric(0)", {
   # diff(numeric(0)) ist leer, aber cum_triangle[1] ist NA; c(NA, numeric(0)) ist NA.
   expect_equal(cum2inc(numeric(0)), NA_real_)
})

test_that("B-F04 Korrektur cum2inc_v behandelt leere Eingaben und bleibt sonst gleich", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."),
                    "verbesserungen", "B-F04.R"))

   expect_equal(cum2inc_v(numeric(0)), numeric(0))

   empty_matrix <- matrix(0, nrow = 0, ncol = 3)
   expect_equal(cum2inc_v(empty_matrix), empty_matrix)

   cum_triangle <- matrix(c(1000, 800, 1200, 1200, 900, 1200, 1300, 900, 1200), 3)
   expect_equal(cum2inc_v(cum_triangle), cum2inc(cum_triangle))
   expect_equal(cum2inc_v(c(1000, 1200, 1300)), cum2inc(c(1000, 1200, 1300)))
})
