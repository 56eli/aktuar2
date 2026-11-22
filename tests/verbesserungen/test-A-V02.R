library(testthat)
library(sicr)

# ---------------------------------------------------------------------------
# A-V02: get_matrix_info() verbessert (kein ifelse(), nur die benoetigten
# Indizes werden berechnet). Der Test prueft die Ergebnisgleichheit fuer alle
# Abwicklungsjahre/Reserveklassen, auch fuer Nachlaufjahre groesser T.
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "A-V02.R"))

# 6 Reserveklassen, 15 Pretail-Abwicklungsjahre (2..16), dann 6 Nachlaufpools
start_of_tail <- 17
number_of_reserve_classes <- 6
lengths_vector <- c(rep(3, 90), c(5, 4, 6, 2, 7, 3))

test_that("A-V02: get_matrix_info_v() ist fuer Skalare identisch", {
   for (reserve_class in 0:5) {
      for (dev_year in 2:50) {
         for (output in c("sample_size", "start", "range")) {
            expect_equal(
               get_matrix_info_v(dev_year, reserve_class, start_of_tail,
                                 number_of_reserve_classes, lengths_vector, output),
               sicr:::get_matrix_info(dev_year, reserve_class, start_of_tail,
                                      number_of_reserve_classes, lengths_vector, output)
            )
         }
      }
   }
})

test_that("A-V02: get_matrix_info_v() ist fuer Vektoren identisch", {
   dev_year <- c(2, 5, 16, 17, 30, 50)
   reserve_class <- c(0, 1, 2, 3, 4, 5)

   for (output in c("sample_size", "start", "range")) {
      expect_equal(
         get_matrix_info_v(dev_year, reserve_class, start_of_tail,
                           number_of_reserve_classes, lengths_vector, output),
         sicr:::get_matrix_info(dev_year, reserve_class, start_of_tail,
                                number_of_reserve_classes, lengths_vector, output)
      )
   }
})
