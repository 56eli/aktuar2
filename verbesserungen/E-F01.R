# E-F01: Korrektur zu aggregate_large_claims_results() (R/aggregate_large_claims_results.R:157-186)
# Fehler: Der XL-Anteil der Spaetgrossschaeden (IBNR) wird nicht in large_ceded_xl_payments
# aufgenommen. sim_result enthaelt diese Anteile in Matrix 6 auch fuer die IBNR-Zeilen
# (R/sicr.R:591-592), und der Quotenanteil der IBNR-Zeilen wird in Zeile 193 sehr wohl
# beruecksichtigt. "Netto = Brutto - gedeckt" (Paper S. 55) ist damit im Standardfall
# (IBNR- und XL-Rueckversicherung aktiv) zu hoch.
# Korrektur: XL-Vorhersage der IBNR-Zeilen zu large_ceded_xl_payments addieren.

aggregate_large_claims_results_v <- function(sim_result,
                                             large_claims_list,
                                             large_extended_claims_data,
                                             history,
                                             reinsurance = NULL,
                                             indices,
                                             first_orig_year,
                                             last_orig_year) {
   result <- aggregate_large_claims_results(sim_result = sim_result,
                                            large_claims_list = large_claims_list,
                                            large_extended_claims_data = large_extended_claims_data,
                                            history = history,
                                            reinsurance = reinsurance,
                                            indices = indices,
                                            first_orig_year = first_orig_year,
                                            last_orig_year = last_orig_year)

   ibnr_list <- attr(sim_result, "ibnr_list")
   if (!is.null(reinsurance) && NROW(ibnr_list) > 0) {
      ind_ibnr <- (NROW(large_claims_list) + 1):NROW(sim_result)
      ibnr_xl <- convert_single2dev_year_prediction(cashflow = sim_result[ind_ibnr, , 6],
                                                   claims_orig_years = ibnr_list$Origin_year,
                                                   first_orig_year = first_orig_year,
                                                   last_orig_year = last_orig_year)
      future_years <- colnames(ibnr_xl)
      result$large_ceded_xl_payments[, future_years] <-
         result$large_ceded_xl_payments[, future_years] + ibnr_xl
   }

   return(result)
}
