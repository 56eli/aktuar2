# Verbesserung D-V01: generate_annuity_payments() ohne Zeilenschleife
#
# Die Zahlungen lassen sich direkt als Matrix aufbauen. Fuer Zeile i und
# Spalte j gilt:  Zahlung = indizierte Jahreszahlung_i * (1 + Dynamik_i)^e
# mit e = j - 1 + cut_first_i - leading_zeros_i, falls 0 <= e <= lasting_i,
# sonst 0. Das ersetzt die Schleife mit tail(), length() und NA-Ersetzung.
generate_annuity_payments_v <- function(annuities,
                                        last_orig_year,
                                        indices = NULL,
                                        future_annuities = FALSE) {
   if (NROW(annuities) < 1) {
      return(NULL)
   }

   leading_zeros <- pmax(0, annuities$Annuity_start - annuities$Entering_year)
   lasting <- ifelse(annuities$Annuity_end == 0,
                     130,
                     annuities$Annuity_end - annuities$Annuity_start)
   cut_first <- annuities$Calendar_year - annuities$Entering_year + 1
   if (future_annuities) {
      cut_first <- cut_first - 1
   }

   if (any(annuities$Calendar_year != last_orig_year)) {
      indexed_payment_per_year <- sicr::apply_index(
         payments = annuities$Annual_payment,
         original_cal_years = annuities$Calendar_year,
         new_cal_years = last_orig_year,
         indices = indices)
   } else {
      indexed_payment_per_year <- annuities$Annual_payment
   }

   exponents <- outer(cut_first - leading_zeros, 0:129, "+")
   valid <- exponents >= 0 & exponents <= lasting

   # pmax(..., 0) verhindert 0^negative_Exponent fuer ungueltige Zellen
   powers <- (1 + annuities$Dynamic)^pmax(exponents, 0)

   return(valid * indexed_payment_per_year * powers)
}
