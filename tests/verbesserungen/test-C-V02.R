# Gleichheitstest zu C-V02 (ibnr_transform2dataframe, base-R statt dplyr/tidyr)

library(testthat)
library(sicr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "C-V02.R"))

test_that("C-V02: base-R-Variante liefert dieselbe Tabelle wie das Original", {
   # Beispielmatrix aus der Doku von ibnr_transform2dataframe()
   expected_rounded_ibnr_numbers <- matrix(c(0, 0, 0, 2,
                                             0, 0, 1, 1,
                                             0, 0, 0, 0,
                                             0, 0, 0, 1), 4,
                                           dimnames = list(2020:2023, 2:5))

   original <- ibnr_transform2dataframe(expected_rounded_ibnr_numbers)
   verbessert <- ibnr_transform2dataframe_v(expected_rounded_ibnr_numbers)

   expect_equal(NROW(verbessert), NROW(original))
   expect_equal(names(verbessert), names(original))
   expect_equal(verbessert$Origin_year, original$Origin_year)
   expect_equal(verbessert$Dev_year_of_growing_large, original$Dev_year_of_growing_large)
   expect_equal(verbessert$Dev_year_since_large, original$Dev_year_since_large)

   # Inhalt (aus dem Doku-Beispiel): 2023 zweimal im Abwicklungsjahr 2 sowie je einmal
   # in 3 und 5, 2022 einmal in 3
   expect_equal(NROW(verbessert), 5)
   expect_equal(as.integer(verbessert$Origin_year), c(2023L, 2023L, 2023L, 2023L, 2022L))
   expect_equal(as.integer(verbessert$Dev_year_of_growing_large), c(2L, 2L, 3L, 5L, 3L))
})

test_that("C-V02: leere Matrix bleibt leer", {
   leer <- matrix(0, nrow = 3, ncol = 2, dimnames = list(2021:2023, 2:3))
   expect_equal(NROW(ibnr_transform2dataframe_v(leer)), 0)
})
