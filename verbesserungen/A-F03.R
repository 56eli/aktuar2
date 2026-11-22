# Korrektur zu A-F03.
# sicr() indiziert die 250 zukuenftigen Kalenderjahre mit
#   tail(indices$Transition_factor, 250)[year]
# und unterstellt damit stillschweigend max(indices$Calendar_year) == last_orig_year.
# Richtig ist der Zugriff ueber das Kalenderjahr last_orig_year + year.
# Die Korrektur ist als Hilfsfunktion formuliert, weil sicr() selbst 861 Zeilen hat;
# in sicr() ersetzt sie die Zeile
#   known_claims_realisation[, year, 3] * future_index_factors_v(indices, last_orig_year)[year]
future_index_factors_v <- function(indices, last_orig_year, horizon = 250) {
   future_years <- seq.int(last_orig_year + 1L, last_orig_year + horizon)
   missing_years <- setdiff(future_years, indices$Calendar_year)
   if (length(missing_years) > 0) {
      stop("indices does not contain all calendar years from last_orig_year + 1 to last_orig_year + 250")
   }
   indices$Transition_factor[match(future_years, indices$Calendar_year)]
}
