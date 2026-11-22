# Korrektur zu D-F03
#
# compute_small_claims() wendet die Quota-Share-Quote positionsabhaengig an:
# `reinsurance$Quota_share[reinsurance$Origin_year %in% first:last]`.
# Die Reihenfolge/Vollstaendigkeit des Datensatzes wird nicht geprueft. Bei
# unsortierten, unvollstaendigen oder zusaetzliche Jahre enthaltenden
# RV-Daten wird die Quote dadurch dem falschen Anfalljahr zugeordnet; bei
# abweichender Laenge wird sie sogar spaltenweise durch die Matrix recycelt.
#
# Die Korrektur erzeugt einen nach Anfalljahren vollstaendigen und sortierten
# Datensatz und uebergibt diesen an die Originalfunktion.
compute_small_claims_v <- function(..., reinsurance = NULL) {
   args <- list(...)
   first_orig_year <- args$first_orig_year
   last_orig_year <- args$last_orig_year
   origin_years <- first_orig_year:last_orig_year

   if (is.null(reinsurance)) {
      reinsurance <- data.frame(Origin_year = origin_years,
                                Quota_share = 0)
   } else {
      quota <- reinsurance$Quota_share[match(origin_years, reinsurance$Origin_year)]
      quota[is.na(quota)] <- 0
      reinsurance <- data.frame(Origin_year = origin_years,
                                Quota_share = quota)
   }

   do.call(sicr::compute_small_claims,
           c(args, list(reinsurance = reinsurance)))
}
