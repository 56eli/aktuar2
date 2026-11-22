library(testthat)
library(sicr)

# D-F01: Für bekannte Renten ist die Sterbetafel um ein Lebensjahr zu jung angesetzt.
#
# generate_annuity_payments() legt bei bekannten Renten Spalte 1 auf das Jahr Calendar_year + 1
# (cut_first = Calendar_year - Entering_year + 1, R/annuity_functions.R:57). Die vorschüssige Zahlung
# zu Beginn von Cy+1 wird richtig mit Überlebenswahrscheinlichkeit 1 bewertet, denn die Rente ist
# zum Stichtag aktiv. Für die Zahlung zu Beginn von Cy+2 muss der Rentner das Kalenderjahr Cy+1
# überleben, in dem er das Alter (Cy+1) - Birth_year erreicht; maßgeblich ist also q(x+1) mit
# x = Cy - Birth_year. generate_annuity_probabilities() rechnet aber mit
# age = Calendar_year - Birth_year (Z. 172) und kumuliert ab q(x) (Z. 161).
# Für künftige Renten aus dem Pool (future_annuities = TRUE, Spalte 1 = Eintrittsjahr) ist dieselbe
# Ausrichtung richtig; die beiden Zweige sind also untereinander inkonsistent.

make_mortality_f01 <- function() {
   # q(50) = 1, alle anderen Alter 0: wer im Jahr seines 50. Geburtstags lebt, stirbt in diesem Jahr.
   data.frame(Gender = rep(c("m", "f"), each = 122),
              Age = rep(0:121, 2),
              Probability = rep(ifelse(0:121 == 50, 1, 0), 2))
}

make_annuity_f01 <- function() {
   data.frame(Claim_id = "C1", Annuity_id = "A1",
              Origin_year = 2023L, Calendar_year = 2023L, Entering_year = 2023L,
              Annuity_start = 2023L, Annuity_end = 0L,
              Birth_year = 1973L,   # x = 50 im Jahr 2023, hat 2023 also überlebt
              Gender = "m", Annual_payment = 1000, Dynamic = 0)
}

age_shift_f01 <- data.frame(Gender = c("m", "f"), Birth_year = 1973L, Age_shift = 0L)

test_that("D-F01: sicr bewertet die Zahlung 2025 mit q(50) statt q(51)", {
   annuity <- make_annuity_f01()
   payments <- generate_annuity_payments(annuities = annuity, last_orig_year = 2023)
   probs <- generate_annuity_probabilities(annuities = annuity, mortality = make_mortality_f01(),
                                           age_shift = age_shift_f01)
   rolled <- roll_out_annuity(payments, probs, stop.at = "end_of_probs")
   expect_equal(rolled[1, 1], 1000)   # Zahlung 01.01.2024: richtig
   # Zahlung 01.01.2025: der Rentner hat 2023 (Alter 50) überlebt; 2024 erreicht er 51 mit q(51) = 0.
   # Richtig wäre 1000, sicr 1.1.1 liefert 0.
   expect_equal(rolled[1, 2], 0)
})

test_that("D-F01: Korrektur rechnet für bekannte Renten mit dem Alter im Folgejahr", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-F01.R"))
   annuity <- make_annuity_f01()
   payments <- generate_annuity_payments(annuities = annuity, last_orig_year = 2023)
   probs_v <- generate_annuity_probabilities_v(annuities = annuity, mortality = make_mortality_f01(),
                                               age_shift = age_shift_f01)
   rolled <- roll_out_annuity(payments, probs_v, stop.at = "end_of_probs")
   expect_equal(rolled[1, 1:3], c(1000, 1000, 1000))
   # Künftige Renten aus dem Pool behalten die Ausrichtung von sicr.
   expect_equal(generate_annuity_probabilities_v(annuities = annuity, mortality = make_mortality_f01(),
                                                 age_shift = age_shift_f01, future_annuities = TRUE),
                generate_annuity_probabilities(annuities = annuity, mortality = make_mortality_f01(),
                                               age_shift = age_shift_f01))
})
