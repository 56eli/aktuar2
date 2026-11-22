library(sicr)
library(testthat)

test_that("E-F05: indices_ok gibt fuer NULL den Character-Wert \"FALSE\" zurueck", {
   # fehlerhaft: return("FALSE") in Zeile 494 liefert einen Character-Wert statt des
   # dokumentierten logischen FALSE. In sicr() (R/sicr.R:331) wirkt nur zufaellig richtig,
   # dass !"FALSE" zu TRUE evaluiert; jede Pruefung des Rueckgabewerts (isFALSE, expect_false)
   # schlaegt fehl.
   expect_identical(indices_ok(NULL, 1989, 2023), "FALSE")
})

test_that("E-F05: Korrektur gibt logisches FALSE zurueck", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-F05.R"),
          local = TRUE)

   expect_identical(indices_ok_v(NULL, 1989, 2023), FALSE)
   expect_type(indices_ok_v(NULL, 1989, 2023), "logical")
})
