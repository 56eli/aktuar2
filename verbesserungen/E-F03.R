# E-F03: Korrektur zu aggregate_large_claims_results() (R/aggregate_large_claims_results.R:93)
# Fehler: `ind_known_claims <- 1:NROW(large_claims_list)` liefert fuer eine leere Schadenliste
# (0 bekannte Grossschaeden, nur Spaetgrossschaeden/IBNR) den Indexvektor c(1, 0) statt
# integer(0). Die 0 selektiert nichts, die 1 aber die erste (IBNR-)Zeile von sim_result, sodass
# cashflow Zeilen hat, obwohl claims_orig_years leer ist. convert_single2dev_year_prediction()
# bricht deshalb mit "cashflow must have same number of rows as claims_orig_years" ab.
# Korrektur: seq_len() liefert fuer 0 Zeilen einen leeren Indexvektor.

aggregate_large_claims_results_v <- function(sim_result,
                                           large_claims_list,
                                           large_extended_claims_data,
                                           history,
                                           reinsurance = NULL,
                                           indices,
                                           first_orig_year,
                                           last_orig_year) {
   # rows of known claims
   ind_known_claims <- seq_len(NROW(large_claims_list))


   # empty triangle and prediction is used where not data is available
   empty_triangle <- skeleton_triangle(first_orig_year = first_orig_year,
                                       last_orig_year = last_orig_year)
   empty_prediction <- skeleton_prediction(first_orig_year = first_orig_year,
                                           last_orig_year = last_orig_year)



   ##### Large Claims #####
   # Claims (without annuities)
   large_claims_paid <- generate_triangle(data = large_extended_claims_data,
                                                   col_name = "Cl_payment_cal",
                                                   first_orig_year = first_orig_year,
                                                   last_orig_year = last_orig_year)

   large_claims_reserved <- generate_triangle(data = large_extended_claims_data,
                                              col_name = "Cl_reserve",
                                              first_orig_year = first_orig_year,
                                              last_orig_year = last_orig_year)

   large_claims_prediction <- convert_single2dev_year_prediction(cashflow = sim_result[ind_known_claims,,3],
                                                                 claims_orig_years = large_claims_list$Origin_year,
                                                                 first_orig_year = first_orig_year,
                                                                 last_orig_year = last_orig_year)

   large_claims_payments <- cbind(large_claims_paid, large_claims_prediction)


   # Known annuities
   large_annuities_paid <- generate_triangle(data = large_extended_claims_data,
                                                      col_name = "An_payment_cal",
                                                      first_orig_year = first_orig_year,
                                                      last_orig_year = last_orig_year)

   large_annuities_reserved <- generate_triangle(data = large_extended_claims_data,
                                                 col_name = "An_reserve",
                                                 first_orig_year = first_orig_year,
                                                 last_orig_year = last_orig_year)

   large_known_annuities_prediction <- convert_single2dev_year_prediction(cashflow = sim_result[ind_known_claims,,4],
                                                                          claims_orig_years = large_claims_list$Origin_year,
                                                                          first_orig_year = first_orig_year,
                                                                          last_orig_year = last_orig_year)

   large_known_annuities_payments <- cbind(large_annuities_paid, large_known_annuities_prediction)


   # Future annuities
   large_future_annuities_prediction <- convert_single2dev_year_prediction(cashflow = sim_result[ind_known_claims,,5],
                                                                           claims_orig_years = large_claims_list$Origin_year,
                                                                           first_orig_year = first_orig_year,
                                                                           last_orig_year = last_orig_year)

   large_future_annuities_payments <- cbind(empty_triangle, large_future_annuities_prediction)


   # ibnr
   ibnr_list <- attr(sim_result, "ibnr_list")
   if (NROW(ibnr_list) == 0) {
      large_ibnr_payments <- cbind(empty_triangle, empty_prediction)
   } else {
      ind_ibnr <- (NROW(large_claims_list) + 1):NROW(sim_result)
      large_ibnr_payments <- cbind(empty_triangle,
                                   convert_single2dev_year_prediction(cashflow = sim_result[ind_ibnr,,1],
                                                                      claims_orig_years = ibnr_list$Origin_year,
                                                                      first_orig_year = first_orig_year,
                                                                      last_orig_year = last_orig_year))
   }


   # reinsurance
   if (!is.null(reinsurance)) {
      large_ceded_xl_per_claim_history <- xl_cashflow(future_payments = matrix(0, nrow = NROW(large_claims_list), ncol = 250),
                                                      claims_list = large_claims_list,
                                                      history = history,
                                                      reinsurance = reinsurance,
                                                      indices = indices,
                                                      output = "history")

      # xl
      large_ceded_xl_paid <- convert_single2dev_year_triangle(cashflow = large_ceded_xl_per_claim_history,
                                                                       claims_orig_years = large_claims_list$Origin_year,
                                                                       first_orig_year = first_orig_year,
                                                                       last_orig_year = last_orig_year)

      large_ceded_xl_prediction <- convert_single2dev_year_prediction(cashflow = sim_result[ind_known_claims,,6],
                                                                      claims_orig_years = large_claims_list$Origin_year,
                                                                      first_orig_year = first_orig_year,
                                                                      last_orig_year = last_orig_year)

      large_ceded_xl_payments <- cbind(large_ceded_xl_paid, large_ceded_xl_prediction)


      # quota share
      large_ceded_quota_payments <- (large_claims_payments +
                                        large_known_annuities_payments +
                                        large_future_annuities_payments +
                                        large_ibnr_payments) *
         reinsurance$Quota_share[reinsurance$Origin_year %in% first_orig_year:last_orig_year]
   } else {
      large_ceded_xl_payments <- large_ceded_quota_payments <- cbind(empty_triangle, empty_prediction)
   }

   return(list(large_claims_payments = large_claims_payments,
               large_claims_reserved = large_claims_reserved,
               large_known_annuities_payments = large_known_annuities_payments,
               large_annuities_reserved = large_annuities_reserved,
               large_future_annuities_payments = large_future_annuities_payments,
               large_ibnr_payments = large_ibnr_payments,
               large_ceded_xl_payments = large_ceded_xl_payments,
               large_ceded_quota_payments = large_ceded_quota_payments))
}
