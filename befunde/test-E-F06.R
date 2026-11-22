library(sicr)
library(testthat)

test_that("E-F06: mortality_ok prueft die Wahrscheinlichkeiten wegen Tippfehler nicht", {
   mortality_bad <- data.frame(Gender = c("f", "f", "m", "m"),
                               Age = c(0L, 1L, 0L, 1L),
                               Probability = c(-0.5, 1, 0, 1),
                               stringsAsFactors = FALSE)

   # fehlerhaft: df$Probabilty (Zeile 685) ist NULL, weil "Probabilty" kein Praefix der
   # Spalte "Probability" ist. Der Wertebereich wird nie geprueft; die negative
   # Wahrscheinlichkeit -0.5 wird akzeptiert, weil das Maximum je Geschlecht 1 ist.
   expect_true(mortality_ok(mortality_bad))
})

test_that("E-F06: Korrektur erkennt unzulaessige Wahrscheinlichkeiten", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-F06.R"),
          local = TRUE)

   mortality_bad <- data.frame(Gender = c("f", "f", "m", "m"),
                               Age = c(0L, 1L, 0L, 1L),
                               Probability = c(-0.5, 1, 0, 1),
                               stringsAsFactors = FALSE)

   expect_false(mortality_ok_v(mortality_bad))

   # eine unauffaellige Tabelle bleibt gueltig
   mortality_good <- data.frame(Gender = c("f", "f", "m", "m"),
                                Age = c(0L, 1L, 0L, 1L),
                                Probability = c(0.5, 1, 0.4, 1),
                                stringsAsFactors = FALSE)
   expect_true(mortality_ok(mortality_good))
   expect_true(mortality_ok_v(mortality_good))
})
