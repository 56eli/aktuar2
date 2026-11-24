# Unabhaengige Nachpruefung der Wirkungszahlen aus gegenpruefung/bericht.md
# Aufruf aus der Repo-Wurzel:
#   Rscript nachpruefung/skripte/wirkung.R
# Es wird ausschliesslich sicr 1.1.1 und die Beispiel-Daten des Pakets benutzt.

root <- Sys.getenv("AKTUAR_ROOT", ".")
setwd(root)
suppressPackageStartupMessages(library(sicr))
outdir <- file.path(root, "nachpruefung", "ergebnisse")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

quelle <- function(rel) {
   e <- new.env(parent = globalenv())
   sys.source(file.path(root, rel), envir = e)
   e
}

zeilen <- list()
add_row <- function(id, groesse, original, korrigiert, abweichung = NULL,
                    anmerkung = "") {
   if (is.null(abweichung)) {
      abweichung <- if (is.finite(original) && is.finite(korrigiert) &&
                        abs(korrigiert) > 0) {
         (original - korrigiert) / korrigiert * 100
      } else {
         NA_real_
      }
   }
   zeilen[[length(zeilen) + 1L]] <<- data.frame(
      ID = id,
      Groesse = groesse,
      Original = round(original, 6),
      Korrigiert = round(korrigiert, 6),
      Abweichung_prozent = round(abweichung, 4),
      Anmerkung = anmerkung,
      stringsAsFactors = FALSE
   )
}

first_orig_year <- 1989L
last_orig_year <- 2023L
reserve_classes <- c(1, 200001, 400001, 700001, 1400001)

cat("Baue die Beispiel-Daten des Pakets auf ...\n")
extended <- prepare_data(claims_data = claims_data_xmpl,
                         indices = indices_xmpl,
                         threshold = 400000,
                         first_orig_year = first_orig_year,
                         last_orig_year = last_orig_year,
                         expected_year_of_growing_large = 3,
                         reserve_classes = reserve_classes,
                         pool_of_annuities = pool_of_annuities_xmpl)

# ---------------------------------------------------------------------------
# A-F01: Masse der Nachlaufpools bei verschiedenen Ausreisser-Grenzen
# ---------------------------------------------------------------------------
cat("A-F01: Nachlaufpoolmassen ...\n")
envA <- quelle("verbesserungen/A-F01.R")
for (grenze in c(100000, 250000, 500000)) {
   args <- list(extended_claims_data = extended,
                reserve_classes = reserve_classes,
                years_for_pools = 2014:2023,
                start_of_tail = 17,
                end_of_tail = 50,
                lower_outlier_limit = 0,
                upper_outlier_limit = grenze,
                pool_of_annuities = pool_of_annuities_xmpl)
   pools_o <- do.call(generate_pools, args)
   pools_v <- do.call(get("generate_pools_v", envir = envA), args)
   masse_o <- sum(vapply(pools_o[[2]], function(df) sum(df$Ind_cl_payment_cal), numeric(1)))
   masse_v <- sum(vapply(pools_v[[2]], function(df) sum(df$Ind_cl_payment_cal), numeric(1)))
   add_row("A-F01", paste0("Nachlaufpoolmasse, Grenzen 0/", grenze),
           masse_o, masse_v,
           anmerkung = "Summe der Ind_cl_payment_cal in pools[[2]]; generate_pools vs generate_pools_v")
}

# ---------------------------------------------------------------------------
# B-F01: permutierte historische Indexreihe
# ---------------------------------------------------------------------------
cat("B-F01: permutierte Indexreihe ...\n")
envB <- quelle("verbesserungen/B-F01.R")
set.seed(42)
perm_idx <- historic_indices_xmpl[sample(NROW(historic_indices_xmpl)), , drop = FALSE]
exp_o <- expand_historic_indices(perm_idx, first_orig_year, last_orig_year,
                                 index_gross_future = 0.03, index_re_future = 0.02)
exp_v <- get("expand_historic_indices_v", envir = envB)(
   perm_idx, first_orig_year, last_orig_year,
   index_gross_future = 0.03, index_re_future = 0.02)
stopifnot(NROW(exp_o) == NROW(exp_v),
          all(exp_o$Calendar_year == exp_v$Calendar_year))
falsch <- abs(exp_o$Index_gross - exp_v$Index_gross) > 1e-12
anteil <- mean(falsch) * 100
rel <- abs(exp_o$Index_gross - exp_v$Index_gross) /
   ifelse(abs(exp_v$Index_gross) < 1e-12, NA_real_, abs(exp_v$Index_gross))
max_rel <- max(rel, na.rm = TRUE) * 100
add_row("B-F01", "Anteil Jahre mit falschem Index (%)", anteil, 0,
        abweichung = anteil,
        anmerkung = paste0("permutierte historic_indices_xmpl, seed 42, ",
                           sum(falsch), " von ", length(falsch),
                           " Jahren; Original gegen expand_historic_indices_v"))
add_row("B-F01", "Max. relative Indexabweichung (%)", max_rel, 0,
        abweichung = max_rel,
        anmerkung = "Maximum der relativen Abweichung je Kalenderjahr")

# ---------------------------------------------------------------------------
# Spezialschaeden wie in der Paket-Vignette auswaehlen (wird fuer C-F03,
# D-F07 und E-F01 benoetigt).
# ---------------------------------------------------------------------------
id1 <- extended$Claim_id[extended$Calendar_year == 2023 &
                            extended$Dev_year_since_large == 7 &
                            extended$Ind_cl_reserve > 5e6]
id2 <- extended$Claim_id[extended$Calendar_year == 2023 &
                            extended$Dev_year_since_large == 8 &
                            extended$Ind_cl_reserve > 6e6]
id3 <- extended$Claim_id[extended$Calendar_year == 2023 &
                            extended$Dev_year_since_large == 8 &
                            extended$Ind_cl_reserve > 4e6 &
                            extended$Ind_cl_reserve < 6e6]
id4 <- extended$Claim_id[extended$Calendar_year == 2023 &
                            extended$Dev_year_since_large == 13 &
                            extended$Ind_cl_reserve > 2e6]
id5 <- extended$Claim_id[extended$Calendar_year == 2023 &
                            extended$Dev_year_since_large > 15 &
                            extended$Ind_cl_reserve > 4e6]
special_ids <- unique(c(id1, id2, id3, id4, id5))
special_claims <- data.frame(Claim_id = special_ids,
                             Reserve2BE_percentage = 0.8,
                             Rollout_type = "linear",
                             stringsAsFactors = FALSE)

special <- compute_special_claims(special_claims = special_claims,
                                  extended_claims_data = extended,
                                  first_orig_year = first_orig_year,
                                  last_orig_year = last_orig_year,
                                  end_of_tail = 50,
                                  external_patterns = NULL,
                                  active_annuities = active_annuities_xmpl,
                                  age_shift = age_shift_xmpl,
                                  mortality = mortality_xmpl,
                                  reinsurance = reinsurance_xmpl,
                                  indices = indices_xmpl)

large_extended <- extended[!extended$Claim_id %in% special_ids, , drop = FALSE]
large_claims_list <- generate_claims_list(large_extended, first_orig_year, last_orig_year)
large_reserved <- generate_triangle(large_extended, "Cl_reserve",
                                    first_orig_year, last_orig_year)
small_reserved <- all_claims_reserved_xmpl - large_reserved -
   special$special_claims_reserved

# ---------------------------------------------------------------------------
# C-F03: erwartete IBNR-Schaeden bei permutierter Exposure
# ---------------------------------------------------------------------------
cat("C-F03: permutierte Exposure ...\n")
envC <- quelle("verbesserungen/C-F03.R")
add_mod <- get_additive_ibnr_model(large_claims_list, first_orig_year, last_orig_year,
                                   exposure_xmpl, 2014:2023)
set.seed(42)
perm_exp <- exposure_xmpl[sample(NROW(exposure_xmpl)), , drop = FALSE]
exp_ibnr_o <- get_expected_ibnr_numbers(add_mod, perm_exp)
exp_ibnr_v <- get("get_expected_ibnr_numbers_v", envir = envC)(add_mod, perm_exp)
add_row("C-F03", "Summe erwartete IBNR-Schaeden, permutierte Exposure",
        sum(exp_ibnr_o), sum(exp_ibnr_v),
        anmerkung = paste0("Summe der Matrix get_expected_ibnr_numbers; permutierte exposure_xmpl, seed 42; ",
                           "Modell aus get_additive_ibnr_model(large_claims_list, 2014:2023)"))

# ---------------------------------------------------------------------------
# D-F01: undiskontierte Rentenzahlungen aktiver Renten
# ---------------------------------------------------------------------------
cat("D-F01: Sterbetafel-Alter der aktiven Renten ...\n")
envD01 <- quelle("verbesserungen/D-F01.R")
ann_pay <- generate_annuity_payments(annuities = active_annuities_xmpl,
                                     last_orig_year = last_orig_year)
prob_o <- generate_annuity_probabilities(annuities = active_annuities_xmpl,
                                         mortality = mortality_xmpl,
                                         age_shift = age_shift_xmpl)
prob_v <- get("generate_annuity_probabilities_v", envir = envD01)(
   annuities = active_annuities_xmpl, mortality = mortality_xmpl,
   age_shift = age_shift_xmpl)
rent_o <- sum(roll_out_annuity(ann_pay, prob_o, "end_of_probs"))
rent_v <- sum(roll_out_annuity(ann_pay, prob_v, "end_of_probs"))
add_row("D-F01", "Undiskontierte Rentenzahlungen (Summe)", rent_o, rent_v,
        anmerkung = "roll_out_annuity(payments, probs, \"end_of_probs\") = payments * (1 - probs); active_annuities_xmpl")

# ---------------------------------------------------------------------------
# D-F03 / E-F02: Quoten unter permutiertem RV-Datensatz
# ---------------------------------------------------------------------------
cat("D-F03/E-F02: permutierter RV-Datensatz ...\n")
set.seed(42)
perm_reins <- reinsurance_xmpl[sample(NROW(reinsurance_xmpl)), , drop = FALSE]
jahre <- first_orig_year:last_orig_year
q_o <- perm_reins$Quota_share[perm_reins$Origin_year %in% jahre]
q_v <- perm_reins$Quota_share[match(jahre, perm_reins$Origin_year)]
falsche_q <- abs(q_o - q_v) > 1e-12
anteil_q <- mean(falsche_q) * 100
max_q <- max(abs(q_o - q_v)) * 100
add_row("D-F03/E-F02", "Anteil Anfalljahre mit falscher Quote (%)", anteil_q, 0,
        abweichung = anteil_q,
        anmerkung = paste0("permutierte reinsurance_xmpl, seed 42, ",
                           sum(falsche_q), " von ", length(falsche_q),
                           " Jahren; Zeilenposition gegen match(Origin_year)"))
add_row("D-F03/E-F02", "Max. Quotenabweichung (Prozentpunkte)", max_q, 0,
        abweichung = max_q,
        anmerkung = "Maximum |Quota_share_original - Quota_share_korrigiert| in Prozentpunkten")

# ---------------------------------------------------------------------------
# D-F07: kuenftige Basisrenten in Abhaengigkeit vom Indexjahr
# ---------------------------------------------------------------------------
cat("D-F07: kuenftige Basisrenten, Indexjahr 2022 gegen 2018 ...\n")
envD07 <- quelle("verbesserungen/D-F07.R")

basis_idx <- indices_xmpl[, c("Calendar_year", "Index_gross", "Index_re")]
idx_2022 <- add_transition_factor(basis_idx, 2022)
idx_2018 <- add_transition_factor(basis_idx, 2018)

params_2022 <- generate_small_claims_annuities_parameters(
   pool_of_annuities = pool_of_annuities_xmpl,
   large_claims_list = large_claims_list,
   special_claims = special_claims,
   indices = idx_2022,
   small_claims_reserved = small_reserved,
   age_shift = age_shift_xmpl,
   mortality = mortality_xmpl)
params_2018 <- generate_small_claims_annuities_parameters(
   pool_of_annuities = pool_of_annuities_xmpl,
   large_claims_list = large_claims_list,
   special_claims = special_claims,
   indices = idx_2018,
   small_claims_reserved = small_reserved,
   age_shift = age_shift_xmpl,
   mortality = mortality_xmpl)

summe_zukunft <- function(m) {
   k <- tail(seq_len(NCOL(m)), 250)
   sum(m[, k, drop = FALSE])
}
res_2022_o <- generate_small_claims_future_annuities(params_2022, small_reserved, idx_2022)
res_2018_o <- generate_small_claims_future_annuities(params_2018, small_reserved, idx_2018)
res_2022_v <- get("generate_small_claims_future_annuities_v", envir = envD07)(
   params_2022, small_reserved, idx_2022)
res_2018_v <- get("generate_small_claims_future_annuities_v", envir = envD07)(
   params_2018, small_reserved, idx_2018)

s22_o <- summe_zukunft(res_2022_o)
s18_o <- summe_zukunft(res_2018_o)
s22_v <- summe_zukunft(res_2022_v)
s18_v <- summe_zukunft(res_2018_v)
add_row("D-F07", "Kuenftige Basisrenten, Indexjahr 2022 gegen 2018",
        s22_o, s18_o,
        anmerkung = paste0("Originalfunktion mit zwei Indexjahren, gleiche Indexreihe; ",
                           "Summe der 250 Zukunftsspalten. _v: 2022=", round(s22_v, 2),
                           ", 2018=", round(s18_v, 2), " (Differenz ",
                           round((s22_v - s18_v) / s18_v * 100, 4), " %)"))
add_row("D-F07", "Kuenftige Basisrenten, Original gegen Korrektur (Indexjahr 2022)",
        s22_o, s22_v,
        anmerkung = "generate_small_claims_future_annuities vs _v; gleiches Indexjahr 2022")

# ---------------------------------------------------------------------------
# E-F01: Nettoreserve und zediertes XL im Grossschadenaggregat
# ---------------------------------------------------------------------------
cat("E-F01: Grossschadenaggregat mit und ohne Prioritaet 500000 ...\n")
envE01 <- quelle("verbesserungen/E-F01.R")

pools_large <- generate_pools(extended_claims_data = large_extended,
                              reserve_classes = reserve_classes,
                              years_for_pools = 2014:2023,
                              start_of_tail = 17,
                              end_of_tail = 50,
                              lower_outlier_limit = -Inf,
                              upper_outlier_limit = Inf,
                              pool_of_annuities = pool_of_annuities_xmpl)
history_large <- generate_history_per_claim(large_extended, "Cl_payment_cal",
                                             first_orig_year, last_orig_year) +
   generate_history_per_claim(large_extended, "An_payment_cal",
                              first_orig_year, last_orig_year)

aggregat_kennzahlen <- function(sim_result, reins) {
   agg_o <- aggregate_large_claims_results(
      sim_result = sim_result,
      large_claims_list = large_claims_list,
      large_extended_claims_data = large_extended,
      history = history_large,
      reinsurance = reins,
      indices = indices_xmpl,
      first_orig_year = first_orig_year,
      last_orig_year = last_orig_year)
   agg_v <- get("aggregate_large_claims_results_v", envir = envE01)(
      sim_result = sim_result,
      large_claims_list = large_claims_list,
      large_extended_claims_data = large_extended,
      history = history_large,
      reinsurance = reins,
      indices = indices_xmpl,
      first_orig_year = first_orig_year,
      last_orig_year = last_orig_year)

   kennzahlen <- function(agg) {
      k <- tail(seq_len(NCOL(agg$large_claims_payments)), 250)
      brutto <- sum(agg$large_claims_payments[, k, drop = FALSE]) +
         sum(agg$large_known_annuities_payments[, k, drop = FALSE]) +
         sum(agg$large_future_annuities_payments[, k, drop = FALSE]) +
         sum(agg$large_ibnr_payments[, k, drop = FALSE])
      cxl <- sum(agg$large_ceded_xl_payments[, k, drop = FALSE])
      cquote <- sum(agg$large_ceded_quota_payments[, k, drop = FALSE])
      c(brutto = brutto, cxl = cxl, cquote = cquote,
        netto = brutto - cxl - cquote)
   }
   list(o = kennzahlen(agg_o), v = kennzahlen(agg_v))
}

reins_default <- reinsurance_xmpl
reins_500 <- reinsurance_xmpl
reins_500$Priority <- 500000

for (variante in c("default", "p500")) {
   reins <- if (variante == "default") reins_default else reins_500
   sim <- sicr(n = 1, large_claims_list = large_claims_list,
               first_orig_year = first_orig_year,
               last_orig_year = last_orig_year,
               pools = pools_large, indices = indices_xmpl,
               history = history_large,
               exposure = exposure_xmpl,
               years_for_ibnr_pools = 2014:2023,
               active_annuities = active_annuities_xmpl,
               age_shift = age_shift_xmpl,
               mortality = mortality_xmpl,
               reinsurance = reins, seed = 12345,
               progress = FALSE, summary = FALSE)
   kk <- aggregat_kennzahlen(sim, reins)
   label <- if (variante == "default") "Beispielprioritaeten" else "Prioritaet 500000"
   add_row("E-F01", paste0("Nettoreserve Grossschaden, ", label),
           kk$o[["netto"]], kk$v[["netto"]],
           anmerkung = paste0("n=1, seed=12345; Brutto - XL - Quote im Grossschadenaggregat; ",
                              "Original gegen aggregate_large_claims_results_v"))
   add_row("E-F01", paste0("Zediertes XL Grossschaden, ", label),
           kk$o[["cxl"]], kk$v[["cxl"]],
           anmerkung = "Summe large_ceded_xl_payments, Zukunftsspalten (250)")
}

# ---------------------------------------------------------------------------
# F-F01: Nominal- gegen Indexbasis im 1-Jahres-Backtesting
# ---------------------------------------------------------------------------
cat("F-F01: Verzerrung durch Deflationierung ...\n")
tf <- setNames(indices_xmpl$Transition_factor, as.character(indices_xmpl$Calendar_year))
faktor_1 <- unname(tf[["2023"]] / tf[["2022"]])
faktor_5 <- unname(tf[["2027"]] / tf[["2022"]])
add_row("F-F01", "Verzerrung Backtesting 2023 (Vignette), Faktor nominal/deflationiert",
        faktor_1, 1,
        anmerkung = "Transition_factor[2023]/Transition_factor[2022]; Korrektur vergleicht nominal, Faktor 1")
add_row("F-F01", "Verzerrung hypothetisches Backtesting 2027, Faktor nominal/deflationiert",
        faktor_5, 1,
        anmerkung = "Transition_factor[2027]/Transition_factor[2022]; Korrektur vergleicht nominal, Faktor 1")

erg <- do.call(rbind, zeilen)
write.csv(erg, file.path(outdir, "wirkung.csv"), row.names = FALSE, quote = TRUE)
cat("Geschrieben:", file.path(outdir, "wirkung.csv"), "\n")
print(erg, row.names = FALSE)
