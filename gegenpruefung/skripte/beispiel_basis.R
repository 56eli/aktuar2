# Aufbau der Beispieldaten aus der Paket-Vignette (sicr::sicr), ohne Sonderschäden,
# damit jede Wirkungsmessung auf denselben Eingaben läuft.
# Aufruf im Container: Rscript gegenpruefung/skripte/beispiel_basis.R
suppressPackageStartupMessages({ library(sicr) })
root <- Sys.getenv("AKTUAR_ROOT", normalizePath("."))
cache <- file.path(root, "gegenpruefung", "cache")
dir.create(cache, showWarnings = FALSE)

first_orig_year <- 1989
last_orig_year <- 2023
threshold <- 400000
reserve_classes <- c(1, 200001, 400001, 700001, 1400001)

expanded_indices <- expand_historic_indices(historic_indices = historic_indices_xmpl,
                                            first_orig_year = first_orig_year,
                                            last_orig_year = last_orig_year,
                                            index_gross_future = 0.03,
                                            index_re_future = 0.02)
indices <- add_transition_factor(expanded_indices = expanded_indices, index_year = 2022)

extended_claims_data <- prepare_data(claims_data = claims_data_xmpl,
                                     indices = indices,
                                     threshold = threshold,
                                     first_orig_year = first_orig_year,
                                     last_orig_year = last_orig_year,
                                     expected_year_of_growing_large = 3,
                                     reserve_classes = reserve_classes,
                                     pool_of_annuities = pool_of_annuities_xmpl)

pools <- generate_pools(extended_claims_data = extended_claims_data,
                        reserve_classes = reserve_classes,
                        years_for_pools = 2014:2023,
                        start_of_tail = 17,
                        end_of_tail = 50,
                        lower_outlier_limit = -Inf,
                        upper_outlier_limit = Inf,
                        pool_of_annuities = pool_of_annuities_xmpl)

claims_history <- generate_history_per_claim(data = extended_claims_data, column = "Cl_payment_cal",
                                             first_orig_year = first_orig_year,
                                             last_orig_year = last_orig_year)
annuities_history <- generate_history_per_claim(data = extended_claims_data, column = "An_payment_cal",
                                                first_orig_year = first_orig_year,
                                                last_orig_year = last_orig_year)
history <- claims_history + annuities_history
large_claims_list <- generate_claims_list(extended_claims_data = extended_claims_data,
                                          first_orig_year = first_orig_year,
                                          last_orig_year = last_orig_year)

saveRDS(list(first_orig_year = first_orig_year, last_orig_year = last_orig_year,
             threshold = threshold, reserve_classes = reserve_classes,
             indices = indices, extended_claims_data = extended_claims_data,
             pools = pools, history = history, large_claims_list = large_claims_list),
        file.path(cache, "basis.rds"))

cat("Zeilen extended_claims_data:", nrow(extended_claims_data), "\n")
cat("Schaeden in large_claims_list:", nrow(large_claims_list), "\n")
cat("Indizes:", nrow(indices), "Jahre, index_year", attr(indices, "index_year"), "\n")
cat("Pools: pretail", length(pools[[1]][[1]]), "Reserveklassen", length(pools[[1]]), "\n")
