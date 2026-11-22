library(sicr)
library(testthat)

## Mini-Zahlungsmatrix: drei Anfalljahre (2019-2021), drei historische Kalenderjahre
## und 250 prognostizierte Jahre.

make_payments <- function() {
   payments <- matrix(0, nrow = 3, ncol = 3 + 250)
   rownames(payments) <- 2019:2021
   colnames(payments) <- 2019:2271
   payments[, 1] <- 1000
   payments[, 4] <- 500
   payments
}

test_that("E-F08: add_sicr_worksheet setzt die globale Option openxlsx2.string_nums und laesst sie stehen", {
   old <- getOption("openxlsx2.string_nums")
   options(openxlsx2.string_nums = FALSE)

   wb <- add_sicr_worksheet(workbook = openxlsx2::wb_workbook(),
                            sheetname = "test",
                            payments = make_payments())

   # fehlerhaft: options("openxlsx2.string_nums" = TRUE) in Zeile 95 wird nicht
   # zurueckgesetzt, die Option bleibt fuer die restliche Session gesetzt.
   expect_true(isTRUE(getOption("openxlsx2.string_nums")))

   if (is.null(old)) options(openxlsx2.string_nums = NULL) else options(openxlsx2.string_nums = old)
})

test_that("E-F08: Korrektur stellt den alten Optionswert wieder her", {
   source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "E-F08.R"),
          local = TRUE)

   old <- getOption("openxlsx2.string_nums")
   options(openxlsx2.string_nums = FALSE)

   wb <- add_sicr_worksheet_v(workbook = openxlsx2::wb_workbook(),
                              sheetname = "test",
                              payments = make_payments())

   expect_false(getOption("openxlsx2.string_nums"))

   if (is.null(old)) options(openxlsx2.string_nums = NULL) else options(openxlsx2.string_nums = old)
})
