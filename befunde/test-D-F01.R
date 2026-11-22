library(testthat)
library(sicr)

# Konstruierte Sterbetafel: ab Alter 50 tritt der Tod im laufenden Jahr sicher ein.
make_mortality_f01 <- function() {
   data.frame(Gender = rep(c("m", "f"), each = 122),
              Age = rep(0:121, 2),
              Probability = rep(ifelse(0:121 >= 50, 1, 0), 2))
}

make_annuity_f01 <- function() {
   data.frame(Claim_id = "C1",
              Annuity_id = "A1",
              Origin_year = 2023L,
              Calendar_year = 2023L,
              Entering_year = 2023L,
              Annuity_start = 2023L,
              Annuity_end = 0L,
              Birth_year = 1973L,   # Alter 50 im Calendar_year
              Gender = "m",
              Annual_payment = 1000,
              Dynamic = 0)
}

test_that("D-F01: Sterbewahrscheinlichkeiten bekannter Renten sind um ein Jahr verschoben", {
   mortality <- make_mortality_f01()
   age_shift <- data.frame(Gender = c("m", "f"),
                           Birth_year = 1973L,
                           Age_shift = 0L)
   annuity <- make_annuity_f01()

   payments <- generate_annuity_payments(annuities = annuity,
                                         last_orig_year = 2023)
   probs <- generate_annuity_probabilities(annuities = annuity,
                                           mortality = mortality,
                                           age_shift = age_shift)

   # Spalte 2 ist die Sterbewahrscheinlichkeit bis zum Beginn des naechsten
   # Jahres (Calendar_year + 1). Genau diese braucht die erste Zahlung.
   expect_equal(probs[1, 2], 1)
   # Die erste Zahlung faellt in 2024. Da der Empfaenger 2023 sicher stirbt,
   # muesste sie 0 sein. sicr 1.1.1 zahlt sie mit Ueberlebenswahrscheinlichkeit 1.
   expect_equal(roll_out_annuity(payments, probs, stop.at = "end_of_probs")[1, 1], 1000)
   set.seed(42)
   expect_equal(roll_out_annuity(payments, probs, stop.at = "random_death_year")[1, 1], 1000)
})

test_that("D-F01: Korrektur bewertet die erste zukuenftige Zahlung mit S(1)", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-F01.R"))

   mortality <- make_mortality_f01()
   age_shift <- data.frame(Gender = c("m", "f"),
                           Birth_year = 1973L,
                           Age_shift = 0L)
   annuity <- make_annuity_f01()

   payments <- generate_annuity_payments(annuities = annuity,
                                         last_orig_year = 2023)
   probs_original <- generate_annuity_probabilities(annuities = annuity,
                                                    mortality = mortality,
                                                    age_shift = age_shift)
   probs_v <- generate_annuity_probabilities_v(annuities = annuity,
                                               mortality = mortality,
                                               age_shift = age_shift)

   expect_equal(probs_v[1, 1], 1)
   expect_equal(roll_out_annuity(payments, probs_v, stop.at = "end_of_probs")[1, 1], 0)
   set.seed(42)
   expect_equal(roll_out_annuity(payments, probs_v, stop.at = "random_death_year")[1, 1], 0)

   # Fuer zukuenftige Renten aus dem Pool bleibt die Ausrichtung unveraendert.
   expect_equal(generate_annuity_probabilities_v(annuities = annuity,
                                                 mortality = mortality,
                                                 age_shift = age_shift,
                                                 future_annuities = TRUE),
                probs_original)
})
