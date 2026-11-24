# Wirkungsmessung je Befund auf den Beispieldaten des Pakets, ein Prozess je Befund.
# Aufruf im Container: Rscript gegenpruefung/skripte/wirkung.R <ID>
# IDs: D-F01 A-F01 B-F01 C-F03 D-F03 E-F02 D-F07 F-F01
suppressPackageStartupMessages({ library(sicr) })
args <- commandArgs(trailingOnly = TRUE)
id <- args[1]
root <- Sys.getenv("AKTUAR_ROOT", normalizePath("."))
source(file.path(root, "gegenpruefung", "skripte", "patch_helpers.R"))
b <- readRDS(file.path(root, "gegenpruefung", "cache", "basis.rds"))
first <- b$first_orig_year; last <- b$last_orig_year
indices <- b$indices; ecd <- b$extended_claims_data; lcl <- b$large_claims_list

if (id == "D-F01") {
  zaehle <- function(probs) {
    pay <- generate_annuity_payments(annuities = active_annuities_xmpl, last_orig_year = last)
    sum(roll_out_annuity(pay, probs, stop.at = "end_of_probs"))
  }
  sum0 <- zaehle(generate_annuity_probabilities(annuities = active_annuities_xmpl,
                                                mortality = mortality_xmpl, age_shift = age_shift_xmpl))
  patch_corrections("D-F01")
  sum1 <- zaehle(generate_annuity_probabilities(annuities = active_annuities_xmpl,
                                                mortality = mortality_xmpl, age_shift = age_shift_xmpl))
  cat(sprintf("D-F01 undiskontiert: original %.0f, korrigiert %.0f, Abweichung %+.2f %%\n",
              sum0, sum1, 100 * (sum0 / sum1 - 1)))
}

if (id == "A-F01") {
  mk <- function(lim) generate_pools(extended_claims_data = ecd, reserve_classes = b$reserve_classes,
                                     years_for_pools = 2014:2023, start_of_tail = 17, end_of_tail = 50,
                                     lower_outlier_limit = lim[1], upper_outlier_limit = lim[2],
                                     pool_of_annuities = pool_of_annuities_xmpl)
  tailsum <- function(p) sum(vapply(p[[2]], function(d) sum(pmax(d$Ind_cl_payment_cal, 0)), numeric(1)))
  grid <- list(c(-Inf, Inf), c(0, 1e5), c(0, 2.5e5), c(0, 5e5))
  vorher <- vapply(grid, function(g) tailsum(mk(g)), numeric(1))
  patch_corrections("A-F01")
  nachher <- vapply(grid, function(g) tailsum(mk(g)), numeric(1))
  for (i in seq_along(grid)) {
    cat(sprintf("A-F01 Grenzen %s/%s: original %.0f, korrigiert %.0f, Abweichung %+.2f %%\n",
                format(grid[[i]][1], scientific = FALSE), format(grid[[i]][2], scientific = FALSE),
                vorher[i], nachher[i], 100 * (vorher[i] / nachher[i] - 1)))
  }
}

if (id == "B-F01") {
  set.seed(7)
  hp <- historic_indices_xmpl[sample(nrow(historic_indices_xmpl)), ]
  i0 <- add_transition_factor(expand_historic_indices(hp, first, last, 0.03, 0.02), 2022)
  iref <- add_transition_factor(expand_historic_indices(historic_indices_xmpl, first, last, 0.03, 0.02), 2022)
  m <- merge(i0[, c("Calendar_year", "Transition_factor")],
             iref[, c("Calendar_year", "Transition_factor")], by = "Calendar_year", suffixes = c("_o", "_r"))
  abw <- abs(m$Transition_factor_o / m$Transition_factor_r - 1)
  cat(sprintf("B-F01 permutierte Indizes: %.1f %% der Jahre weichen ab, max %.2f %%\n",
              100 * mean(abw > 1e-12), 100 * max(abw)))
  patch_corrections("B-F01")
  i1 <- add_transition_factor(expand_historic_indices(hp, first, last, 0.03, 0.02), 2022)
  m1 <- merge(i1[, c("Calendar_year", "Transition_factor")],
              iref[, c("Calendar_year", "Transition_factor")], by = "Calendar_year", suffixes = c("_k", "_r"))
  cat(sprintf("B-F01 korrigiert: max Abweichung %.2e\n",
              max(abs(m1$Transition_factor_k / m1$Transition_factor_r - 1))))
}

if (id == "C-F03") {
  set.seed(11)
  ep <- exposure_xmpl[sample(nrow(exposure_xmpl)), ]
  r0 <- round_expected_ibnr_numbers(get_expected_ibnr_numbers(
    get_additive_ibnr_model(lcl, first, last, ep, 2014:2023), ep))
  patch_corrections("C-F03")
  r1 <- round_expected_ibnr_numbers(get_expected_ibnr_numbers(
    get_additive_ibnr_model(lcl, first, last, ep, 2014:2023), ep))
  cat(sprintf("C-F03 erwartete IBNR-Schäden (Summe): original %.0f, korrigiert %.0f, Abweichung %+.1f %%\n",
              sum(r0), sum(r1), 100 * (sum(r0) / sum(r1) - 1)))
  d <- abs(r0 - r1)
  cat(sprintf("C-F03 betroffene Anfalljahre: %d von %d, Summe der falsch zugeordneten Schäden %.0f\n",
              sum(d > 0), length(d), sum(d)))
}

if (id %in% c("D-F03", "E-F02")) {
  set.seed(13)
  re <- reinsurance_xmpl[sample(nrow(reinsurance_xmpl)), ]
  jahre <- first:last
  falsch <- re$Quota_share[re$Origin_year %in% jahre]
  richtig <- re$Quota_share[match(jahre, re$Origin_year)]
  # D-F03 und E-F02 benutzen dieselbe Zuordnung (`%in%` ohne match); gemessen wird sie
  # deshalb einmal und fuer beide IDs ausgewiesen.
  cat(sprintf("%s permutierte RV-Jahre: %d von %d Anfalljahren erhalten eine falsche Quote, max %.1f Prozentpunkte, Ceded-Summe %+.1f %%\n",
              "D-F03/E-F02", sum(abs(falsch - richtig) > 1e-12), length(jahre),
              100 * max(abs(falsch - richtig)), 100 * (mean(falsch) / mean(richtig) - 1)))
}

if (id == "D-F07") {
  reserved <- sicr:::skeleton_triangle(first, last)
  reserved[upper.tri(reserved, diag = TRUE)] <- 1e6
  params <- generate_small_claims_annuities_parameters(pool_of_annuities = pool_of_annuities_xmpl,
                                                       large_claims_list = lcl,
                                                       special_claims = data.frame(Claim_id = character(0)),
                                                       indices = indices,
                                                       small_claims_reserved = reserved,
                                                       age_shift = age_shift_xmpl,
                                                       mortality = mortality_xmpl)
  idx <- function(j) add_transition_factor(expand_historic_indices(historic_indices_xmpl, first, last, 0.03, 0.02), j)
  s22 <- sum(generate_small_claims_future_annuities(params, reserved, idx(2022)))
  s18 <- sum(generate_small_claims_future_annuities(params, reserved, idx(2018)))
  cat(sprintf("D-F07 künftige Basisrenten: Indexjahr 2022 %.0f, Indexjahr 2018 %.0f, Abweichung %+.1f %%\n",
              s22, s18, 100 * (s22 / s18 - 1)))
  patch_corrections("D-F07")
  v22 <- sum(generate_small_claims_future_annuities(params, reserved, idx(2022)))
  v18 <- sum(generate_small_claims_future_annuities(params, reserved, idx(2018)))
  cat(sprintf("D-F07 korrigiert: Indexjahr 2022 %.0f, Indexjahr 2018 %.0f, Abweichung %+.2e\n",
              v22, v18, abs(v22 / v18 - 1)))
}

if (id == "F-F01") {
  iy <- attr(indices, "index_year")
  tf <- function(j) indices$Transition_factor[match(j, indices$Calendar_year)]
  kat <- c(2024, 2025, 2026, 2028)
  cat(sprintf("F-F01 Indexjahr %d; Übergangsfaktor %s; Verzerrung je Jahr %+.1f %%, nach 5 Jahren %+.1f %%\n",
              iy, paste(sprintf("%d=%.4f", kat, tf(kat)), collapse = " "),
              100 * (tf(2024) - 1), 100 * (tf(2028) - 1)))
}
