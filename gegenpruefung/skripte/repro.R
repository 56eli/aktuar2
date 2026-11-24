# Reproduktionen der Übergabebefunde gegen unverändertes sicr, nur library(sicr) und Base R.
# Jeder Block druckt den beobachteten (falschen) Wert. Aufruf: Rscript gegenpruefung/skripte/repro.R
suppressPackageStartupMessages(library(sicr))
kopf <- function(id) cat("\n##", id, "\n")

kopf("A-F01")
{
  d <- data.frame(Ind_cl_payment_cal = c(1000, -1000), Exit_reserve_class = 0L,
                  New_annuity_1 = 0, New_annuity_2 = 0, New_annuity_3 = 0, New_annuity_4 = 0,
                  New_annuity_5 = 0, Dev_year_since_large = 50L, Entry_reserve_class = 0L,
                  Calendar_year = 2020L, Ind_entry_cl_reserve = 0)
  attr(d, "threshold") <- 400000; attr(d, "index_year") <- 2020
  p <- generate_pools(d, c(1), 2020L, 17, 50, -500, 1000, NULL)
  cat("Nachlaufpool mit Grenzen -500/1000:", p[[2]][[1]]$Ind_cl_payment_cal, "\n")
}

kopf("A-F02")
{
  d <- data.frame(Ind_cl_payment_cal = 10, Exit_reserve_class = 0L,
                  New_annuity_1 = 0, New_annuity_2 = 0, New_annuity_3 = 0, New_annuity_4 = 0,
                  New_annuity_5 = 0, Dev_year_since_large = 2L, Entry_reserve_class = 0L,
                  Calendar_year = 2020L, Ind_entry_cl_reserve = 0)
  attr(d, "threshold") <- 400000; attr(d, "index_year") <- 2020
  p <- generate_pools(d, c(1), 2020L, 2, 5, -Inf, Inf, NULL)
  cat("Pretail-Pools bei start_of_tail=2:", length(p[[1]][[1]]), "Jahre;",
      "Beobachtung im Nachlaufpool doppelt:", sum(p[[2]][[1]]$Ind_cl_payment_cal == 10), "\n")
}

kopf("A-F03")
{
  # zusätzliches Indexjahr verschiebt alle künftigen Zahlungen
  mk <- function(extra) {
    jahre <- 2015:(2020 + 250 + extra)
    i <- data.frame(Calendar_year = as.integer(jahre), Index_gross = 0.01, Index_re = 0)
    k <- cumprod(1 + i$Index_gross)
    i$Transition_factor <- k / k[i$Calendar_year == 2020]
    attr(i, "index_year") <- 2020L
    i
  }
  d <- data.frame(Ind_cl_payment_cal = 1000, Exit_reserve_class = 0L,
                  New_annuity_1 = 0, New_annuity_2 = 0, New_annuity_3 = 0, New_annuity_4 = 0,
                  New_annuity_5 = 0, Dev_year_since_large = 3L, Entry_reserve_class = 0L,
                  Calendar_year = 2020L, Ind_entry_cl_reserve = 0)
  attr(d, "threshold") <- 1; attr(d, "index_year") <- 2020
  pools <- list(list(list(d)), list(d), NULL)
  attr(pools, "reserve_classes") <- 1; attr(pools, "years_for_pools") <- 2020
  attr(pools, "start_of_tail") <- 3; attr(pools, "end_of_tail") <- 5
  attr(pools, "lower_outlier_limit") <- -Inf; attr(pools, "upper_outlier_limit") <- Inf
  attr(pools, "threshold") <- 1; attr(pools, "index_year") <- 2020
  lcl <- data.frame(Claim_id = "C1", Origin_year = 2020L, Exit_reserve_class = 0L,
                    Dev_year_since_large = 1L, Dev_year_of_growing_large = 1L,
                    Large_since = 2020L, Cl_reserve = 0, Ind_cl_reserve = 0)
  attr(lcl, "index_year") <- 2020; attr(lcl, "reserve_classes") <- 1
  h <- matrix(0, 1, 1, dimnames = list(NULL, "2020"))
  lauf <- function(ind) sicr(n = 1, large_claims_list = lcl, first_orig_year = 2020,
                             last_orig_year = 2020, pools = pools, indices = ind, history = h,
                             progress = FALSE, summary = FALSE, seed = 1)
  r0 <- suppressWarnings(lauf(mk(0))); r1 <- suppressWarnings(lauf(mk(1)))
  cat("Zahlung mit/ohne zusätzliches Indexjahr:", r0[1, 1, 1], r1[1, 1, 1], "\n")
}

kopf("B-F01")
{
  h <- data.frame(Calendar_year = c(2021, 2020, 2022), Index_gross = c(0.02, 0.05, 0.03))
  e <- expand_historic_indices(h, 2020, 2022, 0.03, 0.02)
  cat("Index_gross für 2020/2021:", e$Index_gross[e$Calendar_year %in% c(2020, 2021)], "\n")
}

kopf("B-F02")
{
  e <- data.frame(Calendar_year = 2015:2017, Index_gross = 0.02, Index_re = 0)
  cat("add_transition_factor ohne passendes Indexjahr:",
      tryCatch({add_transition_factor(e, 2020); "kein Fehler"},
               error = function(err) conditionMessage(err)), "\n")
}

kopf("B-F03")
{
  cat("inc2cum(0x3):", tryCatch({inc2cum(matrix(0, 0, 3)); "kein Fehler"},
                               error = function(e) conditionMessage(e)), "\n")
}

kopf("B-F04")
{
  cat("cum2inc(numeric(0)):", cum2inc(numeric(0)), "| Länge", length(cum2inc(numeric(0))), "\n")
}

kopf("C-F01")
{
  r <- suppressWarnings(roll_out_single_claim(reserve = 1000, years = 5, type = "quadratic"))
  cat("Summe bei ungültigem type:", sum(r), "(linear wäre 1000)\n")
}

kopf("C-F02")
{
  idx <- data.frame(Calendar_year = 2014:2265, Index_gross = 0, Index_re = 0, Transition_factor = 1)
  re <- data.frame(Origin_year = c(2014L, 2015L), Priority = c(0, 1e5), Limit = c(0, 1e6),
                   Base_year = c(0L, 0L), Margin_type = c("none", "none"), Margin = c(0, 0),
                   Quota_share = c(0, 0))
  h <- matrix(0, 1, 2, dimnames = list("C1", c("2014", "2015"))); h[1, 2] <- 2e5
  x <- suppressWarnings(xl_cashflow(matrix(0, 1, 250),
                                    data.frame(Claim_id = "C1", Origin_year = 2015L),
                                    h, re, idx, output = "futur"))
  cat("Spalten bei output='futur':", ncol(x), "(erwartet 250)\n")
}

kopf("C-F03")
{
  m <- data.frame(Dev_year = 1:4, Ibnr_numbers = c(10L, 5L, 2L, 1L),
                  Sum_of_exposures = rep(400L, 4), Factor = c(0.025, 0.0125, 0.005, 0.0025))
  s <- data.frame(Origin_year = 2020:2023, Exposure = c(1000, 1200, 1500, 1900))
  u <- s[4:1, ]
  cat("Zeile 2023 sortiert:", get_expected_ibnr_numbers(m, s)["2023", ], "| unsortiert:",
      get_expected_ibnr_numbers(m, u)["2023", ], "\n")
}

kopf("C-F04")
{
  re <- data.frame(Origin_year = 2014:2016, Priority = c(0, 1e5, 0), Limit = c(0, 1e6, 0),
                   Base_year = c(0L, 2015L, 0L), Margin_type = c("none", "FIC", "none"),
                   Margin = c(0, 0, 0), Quota_share = c(0, 0, 0))
  mk_idx <- function(shock) {
    i <- data.frame(Calendar_year = 2014:2266, Index_gross = 0, Index_re = 0, Transition_factor = 1)
    i$Index_re[i$Calendar_year == shock] <- 0.2
    i
  }
  h <- matrix(0, 1, 3, dimnames = list("C1", c("2014", "2015", "2016"))); h[1, 2] <- 2e5
  cl <- data.frame(Claim_id = "C1", Origin_year = 2015L)
  f <- matrix(0, 1, 250)
  s <- function(ind) sum(xl_cashflow(f, cl, h, re, ind, output = "total"))
  cat("XL-Summe ohne Schub/2014/2015/2016:",
      round(s(mk_idx(2014))), round(s(mk_idx(2015))), round(s(mk_idx(2016))), "\n")
}

kopf("C-F05")
{
  ex <- data.frame(Origin_year = 2019:2023, Exposure = 1)
  lcl <- data.frame(Claim_id = "C1", Origin_year = 2019, Large_since = 2023,
                    Dev_year_of_growing_large = 5)
  m <- get_additive_ibnr_model(lcl, 2019, 2023, ex, 2019:2023)
  cat("Abwicklungsjahre im Modell:", nrow(m), "| beobachtete Spätschäden gezählt:",
      sum(m$Ibnr_numbers), "(richtig: 5 und 1)\n")
}

kopf("D-F01")
{
  mort <- data.frame(Gender = rep(c("m", "f"), each = 122), Age = rep(0:121, 2),
                     Probability = rep(ifelse(0:121 == 50, 1, 0), 2))
  an <- data.frame(Claim_id = "C1", Annuity_id = "A1", Origin_year = 2023L, Calendar_year = 2023L,
                   Entering_year = 2023L, Annuity_start = 2023L, Annuity_end = 0L,
                   Birth_year = 1973L, Gender = "m", Annual_payment = 1000, Dynamic = 0)
  sh <- data.frame(Gender = c("m", "f"), Birth_year = 1973L, Age_shift = 0L)
  pay <- generate_annuity_payments(an, 2023)
  probs <- generate_annuity_probabilities(an, mort, sh)
  cat("Zahlungen 2024/2025:", roll_out_annuity(pay, probs, stop.at = "end_of_probs")[1, 1:2],
      "(richtig 1000/1000)\n")
}

kopf("D-F02")
{
  dimn <- list(as.character(2020:2022), as.character(2020:2022))
  paid <- matrix(c(100, 0, 0, 110, 120, 0, 130, 140, 150), 3, dimnames = dimn)
  z <- matrix(0, 3, 3, dimnames = dimn)
  res <- list(large_claims_payments = z, large_claims_reserved = z,
              large_known_annuities_payments = z, large_annuities_reserved = z)
  sp <- list(special_claims_payments = z, special_claims_reserved = z,
             special_annuities_payments = z, special_annuities_reserved = z)
  idx <- data.frame(Calendar_year = 2015:2030, Transition_factor = 1); attr(idx, "index_year") <- 2022L
  r <- compute_small_claims(2020L, 2022L, idx, paid, z, large_claims_list = data.frame(Claim_id = character(0), Large_since = integer(0)),
                            large_claims_results = res, special_claims = data.frame(Claim_id = character(0)),
                            special_claims_results = sp)
  cat("small_ceded_quota_payments ohne RV-Programm: Länge", length(r$small_ceded_quota_payments),
      "Klasse", class(r$small_ceded_quota_payments)[1], "\n")
}

kopf("D-F03")
{
  dimn <- list(as.character(2020:2022), as.character(2020:2022))
  paid <- matrix(c(100, 0, 0, 110, 120, 0, 130, 140, 150), 3, dimnames = dimn)
  z <- matrix(0, 3, 3, dimnames = dimn)
  res <- list(large_claims_payments = z, large_claims_reserved = z,
              large_known_annuities_payments = z, large_annuities_reserved = z)
  sp <- list(special_claims_payments = z, special_claims_reserved = z,
             special_annuities_payments = z, special_annuities_reserved = z)
  idx <- data.frame(Calendar_year = 2015:2030, Transition_factor = 1); attr(idx, "index_year") <- 2022L
  re <- data.frame(Origin_year = c(2022L, 2021L, 2020L), Quota_share = c(0.3, 0.2, 0.1))
  r <- compute_small_claims(2020L, 2022L, idx, paid, z, large_claims_list = data.frame(Claim_id = character(0), Large_since = integer(0)),
                            large_claims_results = res, special_claims = data.frame(Claim_id = character(0)),
                            special_claims_results = sp, reinsurance = re)
  gross <- r$small_claims_payments + r$small_known_annuities_payments + r$small_future_annuities_payments
  m <- which(gross != 0)
  cat("angewandte Quoten in Zeilenreihenfolge:", paste(round(unique(r$small_ceded_quota_payments[m] / gross[m]), 2), collapse = "/"),
      "(richtig 0.1/0.2/0.3)\n")
}

kopf("D-F04")
{
  cat("generate_pattern(1x1):", tryCatch({generate_pattern(matrix(1000, 1, 1)); "kein Fehler"},
                                          error = function(e) conditionMessage(e)), "\n")
}

kopf("D-F05")
{
  cat("fill_up_triangle(1x1):", tryCatch({fill_up_triangle(matrix(1000, 1, 1), pattern = 1.1); "kein Fehler"},
                                          error = function(e) conditionMessage(e)), "\n")
}

kopf("D-F06")
{
  res <- matrix(1000, 1, 1, dimnames = list("2023", "2023"))
  idx <- data.frame(Calendar_year = 2020:2030, Transition_factor = 1); attr(idx, "index_year") <- 2023L
  par <- list(factors_additive_method = 0.5, mean_small_claims_annuity = c(100, rep(0, 129)))
  cat("future_annuities mit einem Anfalljahr:",
      tryCatch({generate_small_claims_future_annuities(par, res, idx); "kein Fehler"},
               error = function(e) conditionMessage(e)), "\n")
}

kopf("D-F07")
{
  # derselbe Bestand, zwei Indexjahre: das Ergebnis ändert sich
  pool <- data.frame(Claim_id = c("C1", "C2", "C1"), Annuity_id = c("A1", "A2", "A3"),
                     Origin_year = c(2020L, 2021L, 2020L), Calendar_year = c(2020L, 2021L, 2021L),
                     Entering_year = c(2020L, 2021L, 2021L), Annuity_start = c(2020L, 2021L, 2021L),
                     Annuity_end = c(2022L, 2023L, 2023L), Birth_year = c(1970L, 1971L, 1970L),
                     Gender = c("m", "f", "m"), Annual_payment = c(1000, 1000, 2000), Dynamic = 0)
  res <- matrix(0, 2, 2, dimnames = list(c("2020", "2021"), c("2020", "2021")))
  res[1, 1] <- 10000; res[2, 2] <- 10000
  mort <- data.frame(Gender = rep(c("m", "f"), each = 122), Age = rep(0:121, 2), Probability = 0)
  sh <- data.frame(Gender = c("m", "m", "f", "f"), Birth_year = c(1970L, 1971L, 1970L, 1971L), Age_shift = 0L)
  mk_idx <- function(iy) {
    i <- data.frame(Calendar_year = 2015:2275, Index_gross = 0.02, Index_re = 0)
    k <- cumprod(1 + i$Index_gross); i$Transition_factor <- k / k[i$Calendar_year == iy]
    attr(i, "index_year") <- iy
    i
  }
  lauf <- function(iy) {
    par <- generate_small_claims_annuities_parameters(pool, data.frame(Claim_id = character(0), Large_since = integer(0)),
                                                      data.frame(Claim_id = character(0)), mk_idx(iy), res, sh, mort)
    sum(generate_small_claims_future_annuities(par, res, mk_idx(iy)))
  }
  cat("künftige Basisrenten bei Indexjahr 2022/2018:", round(lauf(2022)), round(lauf(2018)), "\n")
}

kopf("E-F01")
{
  # IBNR-Zeilen sind im Aggregat ohne XL-Anteil
  sim <- array(0, dim = c(2, 250, 15),
               dimnames = list(c("C1", "IBNR1"), as.character(2024:2273), paste0("S", 1:15)))
  sim[1, , 1] <- 0; sim[2, 1, 1] <- 1000; sim[2, 1, 6] <- 400   # IBNR: brutto 1000, XL 400
  attr(sim, "ibnr_list") <- data.frame(Origin_year = 2023L, Dev_year_of_growing_large = 1L)
  dimn <- list("2023", "2023")
  lcl <- data.frame(Claim_id = "C1", Origin_year = 2023L)
  ed <- data.frame(Claim_id = "C1", Origin_year = 2023L, Calendar_year = 2023L,
                   Dev_year_since_large = 1L, Cl_payment_cal = 0, Cl_reserve = 0,
                   An_payment_cal = 0, An_reserve = 0)
  a <- aggregate_large_claims_results(sim, lcl, ed, matrix(0, 1, 1, dimnames = dimn),
                                      reinsurance = NULL, indices = data.frame(Calendar_year = 2023L),
                                      first_orig_year = 2023L, last_orig_year = 2023L)
  cat("XL-Anteil der IBNR-Zeile im Aggregat:", sum(a$large_ceded_xl_payments), "(richtig 400)\n")
}

kopf("E-F02")
{
  sim <- array(0, dim = c(2L, 250L, 7L))
  attr(sim, "ibnr_list") <- data.frame(Origin_year = integer(0), Dev_year_of_growing_large = integer(0))
  sim[1, 1, 3] <- 100; sim[2, 1, 3] <- 200
  lcl <- data.frame(Claim_id = c("C1", "C2"), Origin_year = c(2020L, 2021L))
  ed <- data.frame(Claim_id = c("C1", "C2"), Origin_year = c(2020L, 2021L), Calendar_year = c(2020L, 2021L),
                   Dev_year_since_large = c(1L, 1L), Cl_payment_cal = c(10, 20), Cl_reserve = c(100, 200),
                   An_payment_cal = 0, An_reserve = 0)
  h <- matrix(c(10, 0, 0, 20), 2, dimnames = list(c("C1", "C2"), c("2020", "2021")))
  re <- data.frame(Origin_year = c(2021L, 2020L), Priority = 0, Limit = 1e9, Base_year = 0L,
                   Margin_type = "none", Margin = 0, Quota_share = c(0.5, 0.1))
  idx <- data.frame(Calendar_year = 2020:2271, Index_gross = 0, Index_re = 0); attr(idx, "index_year") <- 2021
  a <- suppressWarnings(aggregate_large_claims_results(sim, lcl, ed, h, re, idx, 2020L, 2021L))
  cat("Quotenabgabe 2020/2021 auf die Zahlung 2022:", unname(a$large_ceded_quota_payments["2020", "2022"]),
      unname(a$large_ceded_quota_payments["2021", "2022"]), "(richtig 10 und 100)\n")
}

kopf("E-F03")
{
  z <- data.frame(Claim_id = "S1", Origin_year = 2020L, Calendar_year = 2020L, Dev_year_since_large = 0L,
                  Cl_payment_cal = 999, Cl_reserve = 999, An_payment_cal = 999, An_reserve = 999)
  sim <- array(0, dim = c(1, 250, 7)); sim[1, 1, 1] <- 50
  attr(sim, "ibnr_list") <- data.frame(Origin_year = 2021L, Dev_year_of_growing_large = 1L)
  cat("Aggregat ohne bekannte Schäden:",
      tryCatch({aggregate_large_claims_results(sim, data.frame(Claim_id = character(0), Origin_year = integer(0)),
                                               z, matrix(0, 1, 1), NULL, data.frame(Calendar_year = 2020:2271), 2021L, 2021L)
                ; "kein Fehler"}, error = function(e) conditionMessage(e)), "\n")
}

kopf("E-F04")
{
  i <- data.frame(Calendar_year = 1989:2273, Index_gross = 0.02); attr(i, "index_year") <- 2022
  cat("indices_ok ohne Spalte Index_re:", indices_ok(i, 1989, 2023), "\n")
}

kopf("E-F05")
{
  r <- indices_ok(NULL, 1989, 2023)
  cat("indices_ok(NULL):", class(r), "|", r, "\n")
}

kopf("E-F06")
{
  df <- data.frame(Gender = rep(c("m", "f"), each = 2), Age = c(0L, 1L, 0L, 1L),
                   Probability = c(-5, 1, 0, 1))
  cat("mortality_ok mit q = -5:", mortality_ok(df), "(richtig FALSE)\n")
}

kopf("E-F07")
{
  re <- data.frame(Origin_year = 2020L, Priority = 1e5, Base_year = 2020L,
                   Margin_type = "SIC", Margin = 0.1, Quota_share = 0.3)  # Limit fehlt
  idx <- data.frame(Calendar_year = 2020:2270, Index_gross = 0, Index_re = 0, Transition_factor = 1)
  cat("reinsurance_ok ohne Spalte Limit:", reinsurance_ok(re, idx, 2020L, 2020L), "\n")
}

kopf("E-F08")
{
  payments <- matrix(0, nrow = 3, ncol = 3 + 250)
  rownames(payments) <- 2019:2021; colnames(payments) <- 2019:2271
  payments[, 1] <- 1000; payments[, 4] <- 500
  options(openxlsx2.string_nums = FALSE)
  wb <- add_sicr_worksheet(openxlsx2::wb_workbook(), "test", payments)
  cat("Option nach add_sicr_worksheet:", getOption("openxlsx2.string_nums"), "(richtig FALSE)\n")
}

kopf("F-F02")
{
  cat("Legendenbeschriftung im Einzelschaden-Backtesting: Q99 bekommt",
      "\"25% - 75%\", Q90 \"10% - 90%\", Q75 \"1% - 99%\" (R/plots.R:1309-1315)\n")
}

kopf("F-F03")
{
  sim <- array(0, dim = c(1, 250, 2), dimnames = list("A", as.character(2023:2272), c("r1", "r2")))
  sim[1, 1:2, ] <- 100000
  attr(sim, "last_orig_year") <- 2022
  attr(sim, "large_claims_list") <- data.frame(Claim_id = "A", Origin_year = 2000,
                                               Exit_reserve_class = 1, Dev_year_since_large = 3)
  neu <- data.frame(Claim_id = "A", Calendar_year = 2022, Cl_payment_cal = 0)
  g <- backtesting_multiyears(sim_result_series_old = sim, extended_claims_data_new = neu,
                              reserve_classes = 1, dev_years = 3)
  cat("Jahre in der Grafik ohne Folgejahr:", sort(g$data$Year), "(richtig: ein Jahr)\n")
}
