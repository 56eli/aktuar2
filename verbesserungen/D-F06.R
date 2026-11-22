# Korrektur zu D-F06
#
# generate_small_claims_future_annuities() bricht bei nur einem Anfalljahr ab:
# `2:dev_years_count` ist dann 2:1, und die Matrix hat nur eine Spalte; ausserdem
# laeuft die Schleife `for (current_row in 2:years_count)` ueber 2:1.
#
# Bei nur einem Anfalljahr existiert noch kein beobachteter Faktor fuer das
# naechste Abwicklungsjahr (das waere Abwicklungsjahr 2), also laesst sich keine
# Prognose schaetzen. Eine stille Nullprognose wuerde die kuenftigen Renten
# unterschaetzen (Gegenpruefung); die Korrektur bricht deshalb mit einer klaren
# Meldung ab und delegiert ab zwei Anfalljahren an die Originalfunktion.
generate_small_claims_future_annuities_v <- function(small_claims_annuities_parameters_list,
                                                     small_claims_reserved,
                                                     indices) {
   first_orig_year <- min(as.integer(rownames(small_claims_reserved)))
   last_orig_year <- max(as.integer(rownames(small_claims_reserved)))
   years_count <- last_orig_year - first_orig_year + 1
   dev_years_count <- length(small_claims_annuities_parameters_list$factors_additive_method)

   if (years_count < 2 || dev_years_count < 2) {
      stop("Kuenftige Basisrenten brauchen mindestens zwei Anfall- und Abwicklungsjahre; ",
           "mit einem Jahr laesst sich kein additiver Faktor schaetzen.", call. = FALSE)
   }

   sicr::generate_small_claims_future_annuities(
      small_claims_annuities_parameters_list = small_claims_annuities_parameters_list,
      small_claims_reserved = small_claims_reserved,
      indices = indices)
}
