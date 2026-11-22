library(sicr)

test_that("B-F01 expand_historic_indices ordnet Index_gross nach Zeilenposition statt nach Kalenderjahr zu", {
   historic <- data.frame(Calendar_year = c(2021, 2020, 2022),
                          Index_gross = c(0.02, 0.05, 0.03))
   expect_true(historic_indices_ok(historic, 2020, 2022))

   expanded <- expand_historic_indices(historic,
                                       first_orig_year = 2020,
                                       last_orig_year = 2022)

   # Richtig waeren 0.05 fuer 2020 und 0.02 fuer 2021. sicr 1.1.1 uebernimmt
   # die Zeilenreihenfolge aber unveraendert in die aufsteigende Jahresfolge.
   expect_equal(expanded$Index_gross[expanded$Calendar_year == 2020], 0.02)
   expect_equal(expanded$Index_gross[expanded$Calendar_year == 2021], 0.05)
})

test_that("B-F01 expand_historic_indices stuerzt bei Luecken vor first_orig_year ab", {
   historic <- data.frame(Calendar_year = c(2018, 2020, 2021, 2022),
                          Index_gross = c(0.01, 0.02, 0.03, 0.04))
   expect_true(historic_indices_ok(historic, 2020, 2022))

   # Die Jahresfolge wird aus min:max gebildet, die Indexwerte stammen aber nur
   # aus den vorhandenen Zeilen. Das fuehrt zu einem kryptischen data.frame-Fehler.
   expect_error(expand_historic_indices(historic,
                                        first_orig_year = 2020,
                                        last_orig_year = 2022),
                "differing number of rows")
})

test_that("B-F01 Korrektur expand_historic_indices_v sortiert und prueft Luecken", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."),
                    "verbesserungen", "B-F01.R"))

   historic <- data.frame(Calendar_year = c(2021, 2020, 2022),
                          Index_gross = c(0.02, 0.05, 0.03))
   expanded_v <- expand_historic_indices_v(historic,
                                           first_orig_year = 2020,
                                           last_orig_year = 2022)
   expect_equal(expanded_v$Index_gross[expanded_v$Calendar_year == 2020], 0.05)
   expect_equal(expanded_v$Index_gross[expanded_v$Calendar_year == 2021], 0.02)

   historic_sorted <- historic[order(historic$Calendar_year), ]
   expect_equal(expand_historic_indices_v(historic_sorted, 2020, 2022),
                expand_historic_indices(historic_sorted, 2020, 2022))

   historic_gap <- data.frame(Calendar_year = c(2018, 2020, 2021, 2022),
                              Index_gross = c(0.01, 0.02, 0.03, 0.04))
   expect_error(expand_historic_indices_v(historic_gap, 2020, 2022), "without gaps")
})
