# Korrektur zu D-F02
#
# compute_small_claims() prueft `if (!is.null("reinsurance"))`. Das ist immer
# wahr, weil "reinsurance" ein Zeichenvektor und nicht NULL ist. Bei
# reinsurance = NULL wird dadurch eine 3x253-Matrix mit NULL multipliziert;
# das Ergebnis ist ein leerer Vektor statt der dokumentierten Nullmatrix.
#
# Die Korrektur uebergibt der Originalfunktion immer einen vollstaendigen
# Quota-Share-Datensatz (bei fehlendem RV-Programm mit Quote 0). Dadurch wird
# der fehlerhafte Zweig umgangen und das dokumentierte Ergebnis geliefert.
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
