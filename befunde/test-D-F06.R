library(testthat)
library(sicr)

make_inputs_f06 <- function() {
   small_claims_reserved <- matrix(1000, nrow = 1, ncol = 1,
                                   dimnames = list("2023", "2023"))
   indices <- data.frame(Calendar_year = 2020:2030,
                         Transition_factor = 1)
   attr(indices, "index_year") <- 2023L
   parameters <- list(factors_additive_method = 0.5,
                      mean_small_claims_annuity = c(100, rep(0, 129)))
   list(small_claims_annuities_parameters_list = parameters,
        small_claims_reserved = small_claims_reserved,
        indices = indices)
}

test_that("D-F06: generate_small_claims_future_annuities bricht bei einem Anfalljahr ab", {
   inputs <- make_inputs_f06()

   # 2:dev_years_count ist 2:1; die 1x1-Matrix hat keine Spalte 2.
   expect_error(do.call(generate_small_claims_future_annuities, inputs), "subscript out of bounds")
})

test_that("D-F06: Korrektur bricht mit verstaendlicher Meldung ab", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-F06.R"))

   inputs <- make_inputs_f06()
   expect_error(do.call(generate_small_claims_future_annuities_v, inputs),
                "mindestens zwei Anfall- und Abwicklungsjahre")
})
