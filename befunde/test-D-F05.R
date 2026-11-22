library(testthat)
library(sicr)

test_that("D-F05: fill_up_triangle bricht bei einem einzigen Abwicklungsjahr ab", {
   triangle <- matrix(1000, nrow = 1, ncol = 1)

   # Die Pretail-Schleife laeuft ueber 1:0; fuer aj = 0 wird Zeile 2 adressiert.
   expect_error(fill_up_triangle(triangle, pattern = c(1.1)), "subscript out of bounds")
})

test_that("D-F05: Korrektur fuellt auch ein einspaltiges Dreieck", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-F05.R"))

   triangle_one_year <- matrix(1000, nrow = 1, ncol = 1)
   result <- fill_up_triangle_v(triangle_one_year, pattern = c(1.1))
   expect_equal(dim(result), c(1L, 2L))
   expect_equal(as.numeric(result), c(1000, 1100))

   # Im Normalfall bleibt das Ergebnis identisch.
   triangle <- matrix(c(1000, 800, 1200, 1200, 900, 1200, 1300, 900, 1200), 3)
   pattern <- c(1.2, 1.1, 1.05, 1.01)
   expect_equal(fill_up_triangle_v(triangle, pattern),
                fill_up_triangle(triangle, pattern))
   expect_equal(fill_up_triangle_v(triangle),
                fill_up_triangle(triangle))
})
