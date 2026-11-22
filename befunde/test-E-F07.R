library(sicr)
library(testthat)

test_that("E-F07: reinsurance_ok prueft die Spalte Limit nicht", {
   # alle Spalten aus structure_list (R/data_checks.R:551-558), aber ohne Limit -
   # Limit wird von xl_cashflow() zwingend benoetigt (R/reinsurance.R:300)
   reinsurance_bad <- data.frame(Origin_year = 1989:2023,
                                 Priority = 1e6,
                                 Base_year = 0L,
                                 Margin_type = "none",
                                 Margin = 0,
                                 Quota_share = 0,
                                 stringsAsFactors = FALSE)

   # fehlerhaft: die Pruefung ist erfolgreich, obwohl Limit fehlt. In xl_cashflow()
   # wird daraus NULL * adj_factor und damit ein leerer Limitvektor.
   expect_true(reinsurance_ok(reinsurance_bad, indices_xmpl, 1989, 2023))
})

test_that("E-F07: Korrektur verlangt die Spalte Limit", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-F07.R"),
          local = TRUE)

   reinsurance_bad <- data.frame(Origin_year = 1989:2023,
                                 Priority = 1e6,
                                 Base_year = 0L,
                                 Margin_type = "none",
                                 Margin = 0,
                                 Quota_share = 0,
                                 stringsAsFactors = FALSE)

   expect_false(reinsurance_ok_v(reinsurance_bad, indices_xmpl, 1989, 2023))
   # gueltige Beispieldaten bleiben gueltig
   expect_true(reinsurance_ok_v(reinsurance_xmpl, indices_xmpl, 1989, 2023))
})
