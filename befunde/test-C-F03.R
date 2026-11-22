# C-F03: get_expected_ibnr_numbers() setzt stillschweigend eine aufsteigend nach
# Origin_year sortierte 'exposure'-Tabelle voraus (R/ibnr.R:104-118: rev(exposure$Exposure),
# Zeilenumdrehung, rownames aus exposure$Origin_year). Bei anderer Reihenfolge werden die
# erwarteten IBNR-Anzahlen den falschen Anfalljahren zugeordnet: die aeltesten Jahrgaenge
# erhalten die IBNR-Anzahlen der juengsten und umgekehrt. Das verschiebt die
# Zahlungszeitpunkte der erwarteten Spaetgrossschaeden massiv.

library(testthat)
library(sicr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "C-F03.R"))

add_mod <- data.frame(Dev_year = 1:4,
                      Ibnr_numbers = c(10L, 5L, 2L, 1L),
                      Sum_of_exposures = c(400L, 400L, 400L, 400L),
                      Factor = c(0.025, 0.0125, 0.005, 0.0025))

exposure_sorted <- data.frame(Origin_year = 2020:2023,
                              Exposure = c(1000, 1200, 1500, 1900))
exposure_shuffled <- exposure_sorted[4:1, ]

test_that("C-F03: unsortierte exposure wird falsch zugeordnet", {
   sorted <- get_expected_ibnr_numbers(add_mod, exposure_sorted)
   shuffled <- get_expected_ibnr_numbers(add_mod, exposure_shuffled)

   # richtig: das juengste Anfalljahr 2023 traegt die drei zukuenftigen Abwicklungsjahre
   expect_equal(unname(sorted["2023", ]),
                c(1900 * 0.0125, 1900 * 0.005, 1900 * 0.0025))

   # fehlerhaft: bei umgekehrter exposure steht beim juengsten Jahr 2023 alles auf 0 ...
   expect_equal(unname(shuffled["2023", ]), c(0, 0, 0))
   # ... die IBNR-Anzahlen landen also bei anderen Anfalljahren (Summe je Jahr verschoben)
   expect_false(isTRUE(all.equal(rowSums(shuffled)[as.character(2020:2023)],
                                 rowSums(sorted)[as.character(2020:2023)])))
})

test_that("C-F03: Korrektur ist unabhaengig von der Zeilenreihenfolge der exposure", {
   expect_equal(get_expected_ibnr_numbers_v(add_mod, exposure_shuffled),
                get_expected_ibnr_numbers(add_mod, exposure_sorted))
   expect_equal(get_expected_ibnr_numbers_v(add_mod, exposure_shuffled),
                get_expected_ibnr_numbers_v(add_mod, exposure_sorted))
})
