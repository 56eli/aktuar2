library(sicr)

test_that("B-F02 add_transition_factor bricht bei fehlendem index_year unklar ab", {
   expanded <- data.frame(Calendar_year = 2015:2017,
                          Index_gross = rep(0.02, 3),
                          Index_re = rep(0, 3))

   # index_year ist nicht in Calendar_year enthalten. Statt einer klaren Meldung
   # entsteht ein numeric(0)-Nenner und damit ein Fehler bei der Spaltenzuweisung.
   expect_error(add_transition_factor(expanded, index_year = 2020), "replacement has 0 rows")
})

test_that("B-F02 Korrektur add_transition_factor_v validiert index_year", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."),
                    "verbesserungen", "B-F02.R"))

   expanded <- data.frame(Calendar_year = 2015:2017,
                          Index_gross = rep(0.02, 3),
                          Index_re = rep(0, 3))

   expect_error(add_transition_factor_v(expanded, index_year = 2020),
                "contained in expanded_indices")
   expect_error(add_transition_factor_v(expanded, index_year = c(2015, 2016)),
                "single")
   expect_equal(add_transition_factor_v(expanded, index_year = 2016),
                add_transition_factor(expanded, index_year = 2016))
})
