# F-F01 am Backtesting-Beispiel der sicr-Vignette (vignettes/sicr.Rmd, Abschnitt "Backtesting"):
# alte Reservierung bis 2022 (Indexjahr 2022), Backtesting des Kalenderjahres 2023.
# Gemessen wird der Ist-Wert je Reserveklasse in backtesting_1y_per_reserve_class() (Original,
# deflationiert) gegen die Korrektur (_v, nominal). Der Erwartungswert ist in beiden gleich.
suppressPackageStartupMessages({ library(sicr); library(dplyr); library(ggplot2); library(tidyr) })
root <- Sys.getenv("AKTUAR_ROOT", ".")
source(file.path(root, "verbesserungen", "F-F01.R"))
set.seed(2022)

claims_data_old <- filter(claims_data_xmpl, Calendar_year <= 2022)
historic_indices_old <- filter(historic_indices_xmpl, Calendar_year <= 2022)
indices_old <- expand_historic_indices(historic_indices_old, first_orig_year = 1989, last_orig_year = 2022,
                                       index_gross_future = 0.03, index_re_future = 0.02)
indices_old <- add_transition_factor(indices_old, index_year = 2022)
rk <- c(1, 200001, 400001, 700001, 1400001)
ecd <- prepare_data(claims_data = claims_data_old, indices = indices_old, threshold = 400000,
                    first_orig_year = 1989, last_orig_year = 2022, expected_year_of_growing_large = 3,
                    reserve_classes = rk, pool_of_annuities = pool_of_annuities_xmpl)
pools <- generate_pools(extended_claims_data = ecd, reserve_classes = rk, years_for_pools = 2014:2022,
                        start_of_tail = 17, end_of_tail = 50, lower_outlier_limit = -Inf,
                        upper_outlier_limit = Inf, pool_of_annuities = pool_of_annuities_xmpl)
lcl <- generate_claims_list(extended_claims_data = ecd, first_orig_year = 1989, last_orig_year = 2022)
history <- generate_history_per_claim(data = ecd, column = "Cl_payment_cal",
                                      first_orig_year = 1989, last_orig_year = 2022)
series <- sicr_series(n = 50, large_claims_list = lcl, first_orig_year = 1989, last_orig_year = 2022,
                      pools = pools, indices = indices_old, history = history, progress = FALSE)
ecd_new <- prepare_data(claims_data = claims_data_xmpl, indices = indices_xmpl, threshold = 400000,
                        first_orig_year = 1989, last_orig_year = 2023, expected_year_of_growing_large = 3,
                        reserve_classes = rk, pool_of_annuities = pool_of_annuities_xmpl)

werte <- function(g) g$data %>% filter(Type %in% c("Expected", "Actual")) %>%
   select(Reserve_class, Type, Value) %>% pivot_wider(names_from = Type, values_from = Value)
o <- werte(backtesting_1y_per_reserve_class(series, ecd_new))
k <- werte(backtesting_1y_per_reserve_class_v(series, ecd_new))
tf <- setNames(indices_xmpl$Transition_factor, indices_xmpl$Calendar_year)
erg <- data.frame(Reserveklasse = o$Reserve_class, Erwartung = round(o$Expected),
                  Ist_original = round(o$Actual), Ist_korrigiert = round(k$Actual),
                  Faktor = round(k$Actual / o$Actual, 4))
erg <- rbind(erg, data.frame(Reserveklasse = "Summe", Erwartung = round(sum(o$Expected)),
                             Ist_original = round(sum(o$Actual)), Ist_korrigiert = round(sum(k$Actual)),
                             Faktor = round(sum(k$Actual) / sum(o$Actual), 4)))
print(erg, row.names = FALSE)
cat("Transition_factor 2023 (Indexjahr 2022):", round(tf[["2023"]], 4), "\n")
dir.create(file.path(root, "nachpruefung", "ergebnisse"), showWarnings = FALSE, recursive = TRUE)
write.csv(erg, file.path(root, "nachpruefung", "ergebnisse", "f_f01_vignette.csv"), row.names = FALSE)
