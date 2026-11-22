library(sicr)
library(testthat)

test_that("E-F04: indices_ok prueft die Spaltenstruktur nicht (Index_re darf fehlen)", {
   indices_bad <- data.frame(Calendar_year = 1989:2273,
                             Index_gross = 0.02)
   attr(indices_bad, "index_year") <- 2022

   # fehlerhaft: die in Zeile 479-485 definierte Struktur wird nie geprueft, deshalb
   # gilt ein indices-Dataframe ohne Spalte Index_re als gueltig. In sicr() (R/sicr.R:331)
   # kommt ein solcher Datensatz durch die Pruefung und xl_cashflow()/apply_index()
   # scheitern erst spaeter bzw. liefern falsche Werte.
   expect_true(indices_ok(indices_bad, 1989, 2023))
})

test_that("E-F04: Korrektur erkennt die fehlende Spalte", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-F04.R"),
          local = TRUE)

   indices_bad <- data.frame(Calendar_year = 1989:2273,
                             Index_gross = 0.02)
   attr(indices_bad, "index_year") <- 2022

   expect_false(indices_ok_v(indices_bad, 1989, 2023))
   # gueltige Beispieldaten bleiben gueltig
   expect_true(indices_ok_v(indices_xmpl, 1989, 2023))
})
