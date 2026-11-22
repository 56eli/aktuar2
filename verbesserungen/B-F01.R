# Korrektur zu B-F01: Indexreihe zuerst nach Kalenderjahr sortieren und
# anschliessend sicherstellen, dass keine Jahresluecken vorliegen.
expand_historic_indices_v <- function(historic_indices,
                                      first_orig_year,
                                      last_orig_year,
                                      index_gross_future = 0,
                                      index_re_future = 0) {
   if (!historic_indices_ok(historic_indices, first_orig_year, last_orig_year)) {
      stop("Dataframe historic_indices is not valid.")
   }

   historic_indices <- historic_indices[order(historic_indices$Calendar_year), , drop = FALSE]
   if (!"Index_re" %in% colnames(historic_indices)) {
      historic_indices$Index_re <- 0
   }

   if (any(diff(historic_indices$Calendar_year) != 1L)) {
      stop("historic_indices must contain consecutive calendar years without gaps")
   }

   first_future_year <- max(historic_indices$Calendar_year) + 1L
   future_years <- seq.int(first_future_year, length.out = 250L)

   rbind(
      data.frame(Calendar_year = as.integer(historic_indices$Calendar_year),
                 Index_gross = historic_indices$Index_gross,
                 Index_re = historic_indices$Index_re),
      data.frame(Calendar_year = as.integer(future_years),
                 Index_gross = rep(index_gross_future, 250L),
                 Index_re = rep(index_re_future, 250L))
   )
}
