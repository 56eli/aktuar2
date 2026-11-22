# Korrektur zu C-F05 (get_additive_ibnr_model(), R/ibnr.R:41-73)
#
# Zeile 49: 'max_dev_year <- max(1, NROW(orig_years) - 1)'. Das groesste
#     beobachtbare Abwicklungsjahr (seit Anfall) ist NROW(orig_years): der aelteste
#     Anfalljahrgang kann im letzten Kalenderjahr das Abwicklungsjahr N erreichen.
#     Mit N-1 wird dieses Abwicklungsjahr samt der dort beobachteten
#     Spaetgrossschaeden still ignoriert (Paper 2.4.5, S. 16: "fuer jedes
#     Abwicklungsjahr die Anzahl der bisher beobachteten Spaetgrossschaeden").
#     Folge: in get_expected_ibnr_numbers() fehlt die Spalte fuer dieses
#     Abwicklungsjahr, die erwartete Anzahl wird zu klein.
#
# Korrektur: sum_of_exposures als numeric, max_dev_year = NROW(orig_years).

get_additive_ibnr_model_v <- function(large_claims_list,
                                      first_orig_year,
                                      last_orig_year,
                                      exposure,
                                      years_for_ibnr_pools){

   Large_since <- NULL
   orig_years <- first_orig_year:last_orig_year
   max_dev_year <- max(1, NROW(orig_years))          # Korrektur (b): war NROW(orig_years) - 1
   dev_years <- 1:max_dev_year

   vexposure <- exposure$Exposure[match(orig_years, exposure$Origin_year)]

   ibnr_numbers <- integer(max_dev_year)
   sum_of_exposures <- numeric(max_dev_year)  # Stil: numeric statt integer (keine Wirkung, R wandelt um)

   # large_claims_list is filtered to chosen years that shall be used for the pools
   filtered_large_claims_list <- large_claims_list[large_claims_list$Large_since %in% years_for_ibnr_pools,]

   # calculate number of ibnr-claims that occured per development year
   # calculate the exposure sum of origin years that could have produced ibnr claims per development year.
   for (dev_year in dev_years) {
      ibnr_numbers[dev_year] <- NROW(filtered_large_claims_list[
         filtered_large_claims_list$Dev_year_of_growing_large == dev_year,])
      sum_of_exposures[dev_year] <- sum(vexposure[(orig_years + dev_year - 1) %in% years_for_ibnr_pools])
   }

   additive_factors <- ibnr_numbers / sum_of_exposures

   return(data.frame(Dev_year = dev_years,
                     Ibnr_numbers = ibnr_numbers,
                     Sum_of_exposures = sum_of_exposures,
                     Factor = additive_factors))
}
