# C-F05: get_additive_ibnr_model() (R/ibnr.R:49) begrenzt auf NROW(orig_years) - 1
# Abwicklungsjahre. Das groesste beobachtbare Abwicklungsjahr (seit Anfall) ist
# NROW(orig_years): der aelteste Anfalljahrgang erreicht im letzten Kalenderjahr das
# Abwicklungsjahr N. Mit N-1 wird dieses Abwicklungsjahr samt der dort beobachteten
# Spaetgrossschaeden ignoriert (Paper 2.4.5, S. 16).
#
# Von cl1 widerlegt und entfernt: die Behauptung, Zeile 54 (integer()) schneide die
# Bestandsgroesse auf ganze Zahlen ab. R wandelt den Vektor bei der Zuweisung in double
# um; sicr 1.1.1 liefert 17.5 (Lauf vom 2026-11-22).

library(testthat)
library(sicr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "C-F05.R"))

test_that("C-F05: Spaetgrossschaden im letzten Abwicklungsjahr wird ignoriert", {
   exposure <- data.frame(Origin_year = 2019:2023, Exposure = 1)
   # Der einzige beobachtete Spaetgrossschaden wird im 5. Abwicklungsjahr gross
   large_claims_list <- data.frame(Claim_id = "C1",
                                   Origin_year = 2019,
                                   Large_since = 2023,
                                   Dev_year_of_growing_large = 5)

   model <- get_additive_ibnr_model(large_claims_list, 2019, 2023, exposure, 2019:2023)
   # fehlerhaft: nur 4 Abwicklungsjahre, der beobachtete Schaden zaehlt nirgends
   expect_equal(NROW(model), 4)
   expect_equal(as.numeric(sum(model$Ibnr_numbers)), 0)

   # fehlerhaft: deshalb wird kein einziger erwarteter Spaetgrossschaden prognostiziert
   expect_equal(NROW(prepare_ibnr(large_claims_list, 2019, 2023, exposure, 2019:2023)[[1]]), 0)

   # Korrektur: 5 Abwicklungsjahre, der Schaden wird gezaehlt und erzeugt erwartete
   # IBNR-Schaden fuer die Anfalljahre 2020 bis 2023 (Abwicklungsjahr 5 liegt dort
   # noch in der Zukunft)
   model_v <- get_additive_ibnr_model_v(large_claims_list, 2019, 2023, exposure, 2019:2023)
   expect_equal(NROW(model_v), 5)
   expect_equal(as.numeric(model_v$Ibnr_numbers[5]), 1)

   erwartet_v <- round_expected_ibnr_numbers(get_expected_ibnr_numbers(model_v, exposure))
   df_v <- ibnr_transform2dataframe(erwartet_v)
   expect_equal(NROW(df_v), 4)
   expect_true(all(df_v$Dev_year_of_growing_large == 5))
   expect_equal(as.integer(df_v$Origin_year), 2023:2020)
})
