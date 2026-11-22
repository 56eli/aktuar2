# Korrektur zu A-F01 (und A-F02):
#   * Ausreisser-Grenzen werden bei den Nachlaufpools VOR der Hochskalierung auf das
#     Niveau des ersten Nachlaufjahres angewandt (die Grenzen sind laut Doku auf dem
#     Niveau von index_year definiert).
#   * Der Pretail-Bereich wird mit seq_len(max(0, start_of_tail - 2)) gebildet; fuer
#     start_of_tail <= 2 entstehen damit keine Pretail-Pools (statt Abwicklungsjahr 1/0).
generate_pools_v <- function(extended_claims_data,
                             reserve_classes,
                             years_for_pools,
                             start_of_tail,
                             end_of_tail,
                             lower_outlier_limit = -Inf,
                             upper_outlier_limit = Inf,
                             pool_of_annuities) {
   pool_columns_pretail <- c("Ind_cl_payment_cal",
                             "Exit_reserve_class",
                             "New_annuity_1",
                             "New_annuity_2",
                             "New_annuity_3",
                             "New_annuity_4",
                             "New_annuity_5",
                             "Ind_entry_cl_reserve")
   pool_columns_tail <- c(pool_columns_pretail[1:7],
                          "Dev_year_since_large",
                          "Ind_entry_cl_reserve")

   # Abwicklungsjahre 2 ... start_of_tail - 1 (leer, falls start_of_tail <= 2)
   pretail_dev_years <- seq_len(max(0, start_of_tail - 2)) + 1

   ### Pretail-Pools
   pretail_pools <- lapply(0:length(reserve_classes), function(reserve_class) {
      lapply(pretail_dev_years, function(dev_year) {
         pool <- extended_claims_data[
            extended_claims_data$Dev_year_since_large == dev_year &
               extended_claims_data$Entry_reserve_class == reserve_class &
               extended_claims_data$Calendar_year %in% years_for_pools,
            pool_columns_pretail]

         if (NROW(pool) == 0) {
            # Dummy-Zeile: keine Zahlung, keine neue Rente, Reserveklasse bleibt
            pool[1, ] <- c(0, reserve_class, 0, 0, 0, 0, 0, 0)
         }

         # Pretail-Zahlungen liegen bereits auf dem Niveau von index_year
         pool$Ind_cl_payment_cal <- pmax(lower_outlier_limit,
                                         pmin(upper_outlier_limit,
                                              pool$Ind_cl_payment_cal))
         pool
      })
   })

   ### Nachlauf-Pools
   tail_pools <- lapply(0:length(reserve_classes), function(reserve_class) {
      pool <- extended_claims_data[
         extended_claims_data$Dev_year_since_large >= start_of_tail &
            extended_claims_data$Dev_year_since_large <= end_of_tail &
            extended_claims_data$Entry_reserve_class == reserve_class &
            extended_claims_data$Calendar_year %in% years_for_pools,
         pool_columns_tail]

      if (NROW(pool) == 0) {
         pool[1, ] <- c(0, reserve_class, 0, 0, 0, 0, 0, 0, 0)
      }

      # A-F01: Grenzen zuerst auf dem Niveau von index_year anwenden ...
      pool$Ind_cl_payment_cal <- pmax(lower_outlier_limit,
                                      pmin(upper_outlier_limit,
                                           pool$Ind_cl_payment_cal))
      # ... und erst danach auf das Niveau des ersten Nachlaufjahres hochskalieren.
      pool$Ind_cl_payment_cal <- pool$Ind_cl_payment_cal /
         tail_factor(pool$Dev_year_since_large, start_of_tail, end_of_tail)

      pool$Dev_year_since_large <- NULL
      pool
   })

   pools <- list(pretail_pools, tail_pools, pool_of_annuities)
   attr(pools, "reserve_classes") <- reserve_classes
   attr(pools, "years_for_pools") <- years_for_pools
   attr(pools, "start_of_tail") <- start_of_tail
   attr(pools, "end_of_tail") <- end_of_tail
   attr(pools, "lower_outlier_limit") <- lower_outlier_limit
   attr(pools, "upper_outlier_limit") <- upper_outlier_limit
   attr(pools, "threshold") <- attr(extended_claims_data, "threshold")
   attr(pools, "index_year") <- attr(extended_claims_data, "index_year")
   pools
}
