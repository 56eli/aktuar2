# Korrektur zu D-F07
#
# generate_small_claims_future_annuities() indexiert die erwarteten
# Rentenzahlen mit `apply_index(..., index_year, last_orig_year + column, ...)`,
# also von einem einheitlichen Indexjahr in das Zukunftsjahr. Die Faktoren
# wurden aber aus Reserven gebildet, die vom jeweiligen Anfalljahr auf das
# Indexjahr indexiert wurden. Dadurch bleibt ein Faktor I(Anfalljahr)/I(Indexjahr)
# stehen: das Ergebnis haengt vom willkuerlich waehlbaren Indexjahr ab.
#
# Die Korrektur indexiert deshalb jede Zeile (jedes Anfalljahr) vom eigenen
# Anfalljahr in das Zukunftsjahr. Das ist aequivalent dazu, das
# Reservenvolumen des Anfalljahres in das Zukunftsjahr zu indexieren und
# anschliessend mit dem Faktor zu multiplizieren. Zusaetzlich werden
# einspaltige Eingaben und externe Faktorvektoren anderer Laenge abgefangen.
generate_small_claims_future_annuities_v <- function(small_claims_annuities_parameters_list,
                                                     small_claims_reserved,
                                                     indices) {
   first_orig_year <- min(as.integer(rownames(small_claims_reserved)))
   last_orig_year <- max(as.integer(rownames(small_claims_reserved)))
   years_count <- last_orig_year - first_orig_year + 1
   origin_years <- first_orig_year:last_orig_year

   factors_additive_method <- small_claims_annuities_parameters_list$factors_additive_method
   mean_small_claims_annuity <- small_claims_annuities_parameters_list$mean_small_claims_annuity

   # Faktoren auf die vorhandenen Abwicklungsjahre auffuellen/kuerzen
   factors <- rep(0, years_count)
   usable <- min(length(factors_additive_method), years_count)
   if (usable > 0) {
      factors[seq_len(usable)] <- factors_additive_method[seq_len(usable)]
   }

   reserve_dev1 <- sicr::cal_year2dev_year(small_claims_reserved)[, 1]

   # Erwartete zukuenftige Anzahlen in Abwicklungsjahr-Darstellung
   counts <- outer(reserve_dev1, factors, "*")
   # beobachteten Teil (inkl. Diagonale) auf 0 setzen
   counts[col(counts) + row(counts) <= years_count + 1] <- 0

   # Umschalten auf Kalenderjahr-Darstellung (Spalte = zukuenftiges Jahr)
   switched <- matrix(0, years_count, years_count)
   for (current_row in seq_len(years_count)) {
      if (current_row >= 2) {
         columns <- seq_len(current_row - 1)
         switched[current_row, columns] <-
            counts[current_row, columns + years_count - current_row + 1]
      }
   }

   # Indexierung zeilenweise vom Anfalljahr in das Zukunftsjahr
   for (current_column in seq_len(years_count)) {
      new_year <- last_orig_year + current_column
      switched[, current_column] <- vapply(
         seq_len(years_count),
         function(current_row) {
            sicr::apply_index(switched[current_row, current_column],
                              origin_years[current_row],
                              new_year,
                              indices)
         },
         numeric(1))
   }

   result_matrix <- sicr::skeleton_prediction(first_orig_year, last_orig_year)
   for (current_row in seq_len(years_count)) {
      for (current_column in seq_len(years_count)) {
         if (switched[current_row, current_column] != 0) {
            result_matrix[current_row, (current_column):(current_column + 129)] <-
               result_matrix[current_row, (current_column):(current_column + 129)] +
               mean_small_claims_annuity * switched[current_row, current_column]
         }
      }
   }

   return(cbind(sicr::skeleton_triangle(first_orig_year, last_orig_year),
                result_matrix))
}
