# C-F04: generate_xl_indices_per_claim() verankert die Indexklausel ein Jahr zu frueh.
# R/reinsurance.R:76 bildet cumprod((1 + Index_re)[Base_year : n]) und legt den Vektor
# ab dem Basisjahr in die Matrix (Zeile 78/85). Im Basisjahr ist der Faktor damit
# 1 + Index_re[Base_year] statt 1. Laut Doku (R/reinsurance.R:139-158) gilt
# f_i = 1, solange I_i/I_B < 1 + alpha, und I_B/I_B = 1. Implementiert ist also
# I_i/I_(B-1): die Prioritaet wird um ein volles Indexjahr zu stark indexiert, die
# Klausel greift ein Jahr zu frueh, der RV-Anteil faellt zu klein aus.
#
# Geprueft wird die korrigierte Indexmatrix durch die unveraenderte XL-Engine
# xl_cashflow(), damit nur die Indexierung veraendert wird.

library(testthat)
library(sicr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "C-F04.R"))

reinsurance <- data.frame(Origin_year = c(2014, 2015, 2016),
                          Priority = c(0, 1e5, 0),
                          Limit = c(0, 1e6, 0),
                          Base_year = c(0, 2015, 0),     # nur 2015 hat eine Klausel
                          Margin_type = c("none", "FIC", "none"),
                          Margin = c(0, 0, 0),
                          Quota_share = c(0, 0, 0))

claims_list <- data.frame(Claim_id = "C1", Origin_year = 2015)
future_payments <- matrix(0, nrow = 1, ncol = 250)

# Indexreihe 2014 bis 2016 + 250 Zukunftskalenderjahre mit einem Inflationsschub
# von 20% im Jahr 'shock_year' (Index_re = vertraglich vereinbarte Indexentwicklung)
make_indices <- function(shock_year) {
   indices <- data.frame(Calendar_year = 2014:2266,
                         Index_gross = 0,
                         Index_re = 0,
                         Transition_factor = 1)
   indices$Index_re[indices$Calendar_year == shock_year] <- 0.2
   indices
}

# Zahlung von 200.000 im Basisjahr 2015 bzw. ein Jahr danach
history_2015 <- matrix(0, nrow = 1, ncol = 3, dimnames = list("C1", c("2014", "2015", "2016")))
history_2015[1, "2015"] <- 2e5
history_2016 <- matrix(0, nrow = 1, ncol = 3, dimnames = list("C1", c("2014", "2015", "2016")))
history_2016[1, "2016"] <- 2e5

xl_cashflow_mit_indices <- function(indices, history) {
   sum(xl_cashflow(future_payments = future_payments,
                   claims_list = claims_list,
                   history = history,
                   reinsurance = reinsurance,
                   indices = indices,
                   output = "total"))
}

xl_cashflow_v_mit_indices <- function(indices, history) {
   sum(xl_cashflow(future_payments = future_payments,
                   claims_list = claims_list,
                   history = history,
                   reinsurance = reinsurance,
                   xl_indices_per_claim = generate_xl_indices_per_claim_v(claims_list = claims_list,
                                                                          reinsurance = reinsurance,
                                                                          indices = indices,
                                                                          first_orig_year = 2014,
                                                                          last_orig_year = 2016),
                   output = "total"))
}

test_that("C-F04: Indexklausel greift schon im Basisjahr", {
   indices <- make_indices(2015)   # Inflation genau im Basisjahr

   # Laut Doku ist der Faktor im Basisjahr I_2015/I_2015 = 1, d.h. keine Indexierung:
   # gedeckter Anteil = 200.000 - 100.000 = 100.000.
   # sicr 1.1.1 nutzt 1.2 -> Prioritaet 120.000 -> nur 80.000 gedeckt.
   expect_equal(xl_cashflow_mit_indices(indices, history_2015), 8e4)
   expect_equal(xl_cashflow_v_mit_indices(indices, history_2015), 1e5)
})

test_that("C-F04: Korrektur indexiert weiterhin ab dem Jahr nach dem Basisjahr", {
   indices <- make_indices(2016)   # Inflation erst nach dem Basisjahr

   # Faktor im Jahr 2016 = I_2016/I_2015 = 1.2 -> Prioritaet 120.000 -> 80.000 gedeckt.
   # Original und Korrektur muessen hier uebereinstimmen.
   expect_equal(xl_cashflow_mit_indices(indices, history_2016), 8e4)
   expect_equal(xl_cashflow_v_mit_indices(indices, history_2016), 8e4)
})
