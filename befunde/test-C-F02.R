# C-F02: xl_cashflow() setzt 'output' bei ungueltigem Wert nicht auf "future".
# R/reinsurance.R:311 steht 'output == "future"' (Vergleich) statt 'output <- "future"';
# der abschliessende else-Zweig (Zeile 323-325) liefert dann die volle Matrix
# (Historie + 250 Zukunftsspalten) statt der 250 Zukunftsspalten.
# Die Warnung meldet dagegen "set to 'future'".

library(testthat)
library(sicr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "C-F02.R"))

# Mini-Beispiel: ein Schaden, 2 historische Kalenderjahre, 250 Zukunftsspalten.
# Die indices muessen die Kalenderjahre first_orig_year bis last_orig_year + 250 enthalten.
indices <- data.frame(Calendar_year = 2014:2265,
                      Index_gross = 0,
                      Index_re = 0,
                      Transition_factor = 1)

reinsurance <- data.frame(Origin_year = c(2014, 2015),
                          Priority = c(0, 1e5),
                          Limit = c(0, 1e6),
                          Base_year = c(0, 0),
                          Margin_type = c("none", "none"),
                          Margin = c(0, 0),
                          Quota_share = c(0, 0))

history <- matrix(0, nrow = 1, ncol = 2, dimnames = list("C1", c("2014", "2015")))
history[1, "2015"] <- 2e5
future_payments <- matrix(0, nrow = 1, ncol = 250)
claims_list <- data.frame(Claim_id = "C1", Origin_year = 2015)

argumente <- list(future_payments = future_payments,
                  claims_list = claims_list,
                  history = history,
                  reinsurance = reinsurance,
                  indices = indices)

test_that("C-F02: ungueltiger 'output' liefert die volle Matrix statt 'future'", {
   result_bad <- expect_warning(do.call(xl_cashflow, c(argumente, list(output = "futur"))),
                                "not valid")

   expect_equal(NCOL(result_bad), NCOL(history) + 250)  # fehlerhaft: total statt future
   expect_equal(NCOL(suppressWarnings(do.call(xl_cashflow_v, c(argumente, list(output = "futur"))))), 250)
})

test_that("C-F02: Korrektur liefert fuer alle gueltigen 'output' dasselbe wie das Original", {
   for (out in c("future", "history", "total")) {
      expect_equal(do.call(xl_cashflow_v, c(argumente, list(output = out))),
                   do.call(xl_cashflow, c(argumente, list(output = out))))
   }
   expect_equal(suppressWarnings(do.call(xl_cashflow_v, c(argumente, list(output = "futur")))),
                do.call(xl_cashflow, c(argumente, list(output = "future"))))
})
