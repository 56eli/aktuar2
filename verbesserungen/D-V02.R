# Verbesserung D-V02: rollout_best_estimate() ohne wiederholte Vorberechnung
#
# Das Original ruft fuer jedes Element von best_estimate settlement_rates()
# und cum2inc() erneut auf, obwohl beide nur vom Pattern abhaengen. Die
# verbesserte Version berechnet beide einmal und verwendet vapply. Das
# Ergebnis (inklusive Warnungen und Rueckfall auf die erste Folgejahr-Zahlung)
# bleibt identisch.
rollout_best_estimate_v <- function(best_estimate, pattern, dev_year) {
   pattern_length <- NROW(pattern) + 1
   settle_rates <- sicr:::settlement_rates(pattern)
   increments <- sicr::cum2inc(settle_rates)

   rollout_one <- function(be, dy) {
      cashflow <- rep(0, 250)

      if (!is.numeric(dy) | dy < 1 | dy %% 1 != 0) {
         cashflow[1] <- be
         warning("dev_year must be positive integer. Best estimate was allocated to the first subsequent year.")
         return(cashflow)
      }

      if (dy > (pattern_length - 1)) {
         cashflow[1] <- be
         return(cashflow)
      }

      origin_value <- be / (1 - settle_rates[dy])
      if (is.na(origin_value) | is.infinite(origin_value)) {
         cashflow[1] <- be
      } else {
         cashflow[1:(pattern_length - dy)] <-
            origin_value * increments[(dy + 1):pattern_length]
      }

      return(cashflow)
   }

   n <- max(length(best_estimate), length(dev_year))
   best_estimate <- rep(best_estimate, length.out = n)
   dev_year <- rep(dev_year, length.out = n)

   return(vapply(seq_len(n),
                 function(i) rollout_one(best_estimate[i], dev_year[i]),
                 numeric(250)))
}
