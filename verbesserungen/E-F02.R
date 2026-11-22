# E-F02: Korrektur zu aggregate_large_claims_results() (R/aggregate_large_claims_results.R:190-194)
# Fehler: Die Quotenrueckversicherung wird ueber die Zeilenposition zugeordnet:
# `reinsurance$Quota_share[reinsurance$Origin_year %in% first_orig_year:last_orig_year]`.
# Die Matrixzeilen sind aber Anfalljahre in der Reihenfolge first_orig_year:last_orig_year.
# Ist das Dataframe `reinsurance` nicht nach Origin_year sortiert (reinsurance_ok() verlangt
# das nicht), wird die Quote des falschen Anfalljahres angewendet; enthaelt es zusaetzliche
# Anfalljahre ausserhalb des Bereichs, wird der Vektor zu lang und die Multiplikation
# recycelt still. xl_cashflow() macht es richtig und ordnet per match() zu (R/reinsurance.R:296).
# Korrektur: Quote per match() dem Anfalljahr zuordnen (und fehlende Jahre als Fehler melden).

aggregate_large_claims_results_v <- function(sim_result,
                                             large_claims_list,
                                             large_extended_claims_data,
                                             history,
                                             reinsurance = NULL,
                                             indices,
                                             first_orig_year,
                                             last_orig_year) {
   if (!is.null(reinsurance)) {
      row_in_reinsurance <- match(first_orig_year:last_orig_year, reinsurance$Origin_year)
      if (any(is.na(row_in_reinsurance))) {
         stop("reinsurance must contain one row per origin year between first_orig_year and last_orig_year.")
      }
      # genau eine Zeile je Anfalljahr und in der Reihenfolge der Matrixzeilen
      reinsurance <- reinsurance[row_in_reinsurance, , drop = FALSE]
   }

   aggregate_large_claims_results(sim_result = sim_result,
                                  large_claims_list = large_claims_list,
                                  large_extended_claims_data = large_extended_claims_data,
                                  history = history,
                                  reinsurance = reinsurance,
                                  indices = indices,
                                  first_orig_year = first_orig_year,
                                  last_orig_year = last_orig_year)
}
