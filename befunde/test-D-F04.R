library(testthat)
library(sicr)

test_that("D-F04: generate_pattern bricht bei einem einzigen Abwicklungsjahr ab", {
   triangle <- matrix(1000, nrow = 1, ncol = 1)

   # 1:(ndim0 - 1) ist 1:0 = c(1, 0); cl_factor(., 0) wirft einen Fehler.
   # Richtig waere ein leerer Pattern-Vektor (es gibt keinen Entwicklungsfaktor).
   expect_error(suppressWarnings(generate_pattern(triangle)), "dev_year must be integer greater 0")
})

test_that("D-F04: Korrektur liefert fuer ein Jahr einen leeren Pattern-Vektor", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "D-F04.R"))

   triangle_one_year <- matrix(1000, nrow = 1, ncol = 1)
   expect_equal(generate_pattern_v(triangle_one_year), numeric(0))

   # Im Normalfall bleibt das Ergebnis identisch.
   triangle <- matrix(c(1000, 800, 1200, 1200, 900, 1200, 1300, 900, 1200), 3)
   expect_equal(generate_pattern_v(triangle), generate_pattern(triangle))
   expect_equal(generate_pattern_v(triangle,
                                   volume = 1,
                                   external_pattern = c(1.2, 1.1, 1.05, 1.01),
                                   int2ext_transition = 3),
                generate_pattern(triangle,
                                 volume = 1,
                                 external_pattern = c(1.2, 1.1, 1.05, 1.01),
                                 int2ext_transition = 3))
})
