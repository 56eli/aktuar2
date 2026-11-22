library(testthat)
library(sicr)

# Konstruiertes Beispiel mit zwei Anfalljahren und drei kleinen Renten.
# Die Rente A3 wird fuer Anfalljahr 2020 erst im Abwicklungsjahr 2 anerkannt;
# nur dadurch gibt es einen Faktor > 0 fuer ein zukuenftiges Abwicklungsjahr.
make_inputs_f07 <- function() {
   pool_of_annuities <- data.frame(
      Claim_id = c("C1", "C2", "C1"),
      Annuity_id = c("A1", "A2", "A3"),
      Origin_year = c(2020L, 2021L, 2020L),
      Calendar_year = c(2020L, 2021L, 2021L),
      Entering_year = c(2020L, 2021L, 2021L),
      Annuity_start = c(2020L, 2021L, 2021L),
      Annuity_end = c(2022L, 2023L, 2023L),
      Birth_year = c(1970L, 1971L, 1970L),
      Gender = c("m", "f", "m"),
      Annual_payment = c(1000, 1000, 2000),
      Dynamic = c(0, 0, 0))

   large_claims_list <- data.frame(Claim_id = character(0),
                                   Large_since = integer(0))
   special_claims <- data.frame(Claim_id = character(0))

   small_claims_reserved <- matrix(0, nrow = 2, ncol = 2,
                                   dimnames = list(c("2020", "2021"),
                                                   c("2020", "2021")))
   small_claims_reserved[1, 1] <- 10000
   small_claims_reserved[2, 2] <- 10000

   # Sterblichkeit 0 in allen Altern: die mittlere Rente ist dann der
   # undiskontierte Zahlungsstrom und skaliert exakt mit dem Indexniveau.
   mortality <- data.frame(Gender = rep(c("m", "f"), each = 122),
                           Age = rep(0:121, 2),
                           Probability = 0)
   age_shift <- data.frame(Gender = c("m", "m", "f", "f"),
                           Birth_year = c(1970L, 1971L, 1970L, 1971L),
                           Age_shift = 0L)

   list(pool_of_annuities = pool_of_annuities,
        large_claims_list = large_claims_list,
        special_claims = special_claims,
        small_claims_reserved = small_claims_reserved,
        mortality = mortality,
        age_shift = age_shift)
}

make_indices_f07 <- function(index_year) {
   indices <- data.frame(Calendar_year = 2015:2030,
                         Transition_factor = 1.02^(2015:2030 - 2015))
   attr(indices, "index_year") <- as.integer(index_year)
   indices
}

make_parameters_f07 <- function(inputs, indices) {
   generate_small_claims_annuities_parameters(
      pool_of_annuities = inputs$pool_of_annuities,
      large_claims_list = inputs$large_claims_list,
      special_claims = inputs$special_claims,
      indices = indices,
      small_claims_reserved = inputs$small_claims_reserved,
      age_shift = inputs$age_shift,
      mortality = inputs$mortality)
}

test_that("D-F07: zukuenftige Basis-Renten haengen vom willkuerlichen Indexjahr ab", {
   inputs <- make_inputs_f07()
   indices_2020 <- make_indices_f07(2020)
   indices_2021 <- make_indices_f07(2021)

   parameters_2020 <- make_parameters_f07(inputs, indices_2020)
   parameters_2021 <- make_parameters_f07(inputs, indices_2021)

   result_2020 <- generate_small_claims_future_annuities(
      parameters_2020, inputs$small_claims_reserved, indices_2020)
   result_2021 <- generate_small_claims_future_annuities(
      parameters_2021, inputs$small_claims_reserved, indices_2021)

   expect_true(sum(abs(result_2020)) > 0)
   # Falsches Verhalten: Bei gleichem Zahlungsstrom und gleicher Indexreihe
   # unterscheiden sich die Ergebnisse nur wegen des gewaehlten Indexjahres,
   # und zwar um den Faktor 1/1.02. Richtig waere Gleichheit.
   expect_equal(result_2021, result_2020 / 1.02, tolerance = 1e-8)
})

test_that("D-F07: Korrektur ist unabhaengig vom Indexjahr", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-F07.R"))

   inputs <- make_inputs_f07()
   indices_2020 <- make_indices_f07(2020)
   indices_2021 <- make_indices_f07(2021)

   parameters_2020 <- make_parameters_f07(inputs, indices_2020)
   parameters_2021 <- make_parameters_f07(inputs, indices_2021)

   result_2020 <- generate_small_claims_future_annuities_v(
      parameters_2020, inputs$small_claims_reserved, indices_2020)
   result_2021 <- generate_small_claims_future_annuities_v(
      parameters_2021, inputs$small_claims_reserved, indices_2021)

   expect_true(sum(abs(result_2020)) > 0)
   expect_equal(result_2021, result_2020, tolerance = 1e-8)
})
