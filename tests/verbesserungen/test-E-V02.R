library(sicr)
library(testthat)

test_that("E-V02: exposure_ok_v liefert dieselben Ergebnisse wie exposure_ok", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-V02.R"),
          local = TRUE)

   # gueltige Beispieldaten
   expect_equal(exposure_ok(exposure_xmpl, 1989, 2023),
                exposure_ok_v(exposure_xmpl, 1989, 2023))
   expect_true(exposure_ok_v(exposure_xmpl, 1989, 2023))

   # doppeltes Anfalljahr
   duplicated_years <- rbind(exposure_xmpl, exposure_xmpl[1, ])
   expect_equal(exposure_ok(duplicated_years, 1989, 2023),
                exposure_ok_v(duplicated_years, 1989, 2023))
   expect_false(exposure_ok_v(duplicated_years, 1989, 2023))

   # fehlendes Anfalljahr
   missing_year <- exposure_xmpl[exposure_xmpl$Origin_year != 1995, ]
   expect_equal(exposure_ok(missing_year, 1989, 2023),
                exposure_ok_v(missing_year, 1989, 2023))
   expect_false(exposure_ok_v(missing_year, 1989, 2023))

   # falscher Spaltentyp
   wrong_type <- exposure_xmpl
   wrong_type$Exposure <- as.character(wrong_type$Exposure)
   expect_equal(exposure_ok(wrong_type, 1989, 2023),
                exposure_ok_v(wrong_type, 1989, 2023))
   expect_false(exposure_ok_v(wrong_type, 1989, 2023))

   # NULL ist erlaubt
   expect_equal(exposure_ok(NULL, 1989, 2023), exposure_ok_v(NULL, 1989, 2023))
   expect_true(exposure_ok_v(NULL, 1989, 2023))
})
