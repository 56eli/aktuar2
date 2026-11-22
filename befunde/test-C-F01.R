# C-F01: roll_out_single_claim() korrigiert ein ungueltiges 'type' nicht.
# R/special_claims.R:29-32 setzt im Fehlerfall die Variable 'art' statt 'type'.
# Die Warnung behauptet "will be set to 'lineaer'" (sic), die Funktion liefert
# danach aber einen Nullvektor, weil keine der drei if-Bedingungen greift.
# Folge: ein Sonderschaden mit falsch geschriebenem Rollout_type erhaelt einen
# Best Estimate von 0 -- ohne Fehlermeldung.

library(testthat)
library(sicr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "C-F01.R"))

test_that("C-F01: ungueltiger 'type' liefert still einen Nullvektor statt linear", {
   result <- suppressWarnings(roll_out_single_claim(reserve = 1000, years = 5, type = "quadratic"))

   # fehlerhaftes Verhalten von sicr 1.1.1: alles 0, die Warnung verspricht "linear"
   expect_length(result, 250)
   expect_equal(sum(result), 0)
   expect_warning(roll_out_single_claim(1000, 5, "quadratic"), "linear")
})

test_that("C-F01: Korrektur setzt 'type' wie dokumentiert auf linear", {
   result_v <- suppressWarnings(roll_out_single_claim_v(reserve = 1000, years = 5, type = "quadratic"))

   # richtiges Verhalten: identisch zu type = "linear"
   expect_equal(result_v, roll_out_single_claim(reserve = 1000, years = 5, type = "linear"))
   expect_equal(sum(result_v), 1000)
})
