library(sicr)
library(testthat)

test_that("E-V01: indices_ok_v liefert dieselben Ergebnisse wie indices_ok", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-V01.R"),
          local = TRUE)

   # Beispieldaten des Pakets
   expect_equal(indices_ok(indices_xmpl, 1989, 2023),
                indices_ok_v(indices_xmpl, 1989, 2023))
   expect_true(indices_ok_v(indices_xmpl, 1989, 2023))

   # konstruierte Indizes in richtiger Reihenfolge
   indices <- data.frame(Calendar_year = 1989:2273,
                         Index_gross = 0.02,
                         Index_re = 0.01)
   attr(indices, "index_year") <- 2022
   expect_equal(indices_ok(indices, 1989, 2023),
                indices_ok_v(indices, 1989, 2023))
   expect_true(indices_ok_v(indices, 1989, 2023))

   # vertauschte Zeilen: die Sortierpruefung muss in beiden Varianten anschlagen
   indices_unsorted <- indices[c(2, 1, 3:nrow(indices)), ]
   expect_equal(indices_ok(indices_unsorted, 1989, 2023),
                indices_ok_v(indices_unsorted, 1989, 2023))
   expect_false(indices_ok_v(indices_unsorted, 1989, 2023))
})
