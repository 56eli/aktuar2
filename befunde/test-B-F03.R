library(sicr)

test_that("B-F03 inc2cum stuerzt bei einer leeren Matrix durch 1:0 ab", {
   empty_triangle <- matrix(0, nrow = 0, ncol = 3)

   # for (i in 1:NROW(...)) laeuft bei NROW = 0 als 1:0 und greift auf Zeile 1 zu.
   expect_error(inc2cum(empty_triangle), "subscript out of bounds")
})

test_that("B-F03 Korrektur inc2cum_v behandelt leere und normale Matrizen", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."),
                    "verbesserungen", "B-F03.R"))

   empty_triangle <- matrix(0, nrow = 0, ncol = 3)
   expect_equal(inc2cum_v(empty_triangle), empty_triangle)

   normal_triangle <- matrix(c(1000, 800, 1200, 200, 100, 0, 100, 0, 0), 3)
   expect_equal(inc2cum_v(normal_triangle), inc2cum(normal_triangle))
})
