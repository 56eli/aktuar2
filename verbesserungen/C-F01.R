# Korrektur zu C-F01
# roll_out_single_claim() (R/special_claims.R:28-72) setzt in Zeile 30 die Variable
# 'art' statt 'type'. Ein ungueltiges 'type' wird daher nicht auf "linear" gesetzt,
# die Warnung verspricht aber genau das. Die Funktion liefert dann still einen
# Nullvektor, d.h. der Sonderschaden erhaelt keine Zahlung.
# Hier wird nur dieser Tippfehler behoben (und die doppelte Pruefung von 'years'
# zusammengefasst); die Berechnung selbst bleibt unveraendert.

roll_out_single_claim_v <- function(reserve, years = 1, type = "linear", external_pattern = NULL) {
   if (!type %in% c("linear", "constant", "external")) {
      warning("The parameter 'type' must be 'linear', 'constant' or 'external', will be set to 'linear'.")
      type <- "linear"
   }

   rolled_out_reserve <- rep(0, 250)

   if (type == "external") {
      if (is.null(external_pattern) |
          !is.numeric(external_pattern) |
          !is.vector(external_pattern) |
          length(external_pattern) > 250) {
         warning("external_pattern not usable, 'type' will be set to 'linear'.")
         type <- "linear"
      } else {
         if (abs(1 - sum(external_pattern)) > 0.05) {
            warning("Sum of external_pattern is not near 1, so the cashflow will not add up to reserve.")
         }
         rolled_out_reserve[seq_along(external_pattern)] <- reserve * external_pattern
      }
   }

   if (type %in% c("linear", "constant")) {
      if (!years %in% 1:250) {
         warning("Parameter 'years' must be an integer between 1 and 250, will be set to 1 here.")
         years <- 1
      }
   }

   if (type == "linear") {
      weights <- (years:1) / years
      rolled_out_reserve[1:years] <- reserve * weights / sum(weights)
   }

   if (type == "constant") {
      rolled_out_reserve[1:years] <- reserve / years
   }

   return(rolled_out_reserve)
}
