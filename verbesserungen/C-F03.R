# Korrektur zu C-F03
# get_expected_ibnr_numbers() (R/ibnr.R:96-122) setzt stillschweigend voraus, dass
# 'exposure' aufsteigend nach Origin_year sortiert ist:
#   - Zeile 104 bildet rev(exposure$Exposure),
#   - Zeile 109 dreht die Zeilen der Matrix wieder um,
#   - Zeile 118 beschriftet die Zeilen mit exposure$Origin_year.
# Bei anderer Reihenfolge werden die erwarteten Anzahlen den falschen Anschluessjahren
# zugeordnet (die aeltesten Jahre erhalten die IBNR-Zahlen der juengsten und umgekehrt).
# Korrektur: exposure wird intern nach Origin_year sortiert.

get_expected_ibnr_numbers_v <- function(additive_ibnr_model, exposure){
   # Neu: die Zeilenreihenfolge von 'exposure' darf das Ergebnis nicht beeinflussen
   exposure <- exposure[order(exposure$Origin_year), , drop = FALSE]

   # to save computing time the matrix is only created until the maximum development year with factor > 0
   max_dev_year_with_ibnr <- max(c(2, subset(additive_ibnr_model,
                                             additive_ibnr_model$Ibnr_numbers > 0)$Dev_year))

   factors <- additive_ibnr_model$Factor[2:max_dev_year_with_ibnr]

   # write exposure in every column
   expected_ibnr_numbers <- matrix(rev(exposure$Exposure),
                                   nrow = NROW(exposure),
                                   ncol = max_dev_year_with_ibnr - 1)
   # set upper left triangle to 0 and revert rows
   expected_ibnr_numbers[lower.tri(expected_ibnr_numbers)] <- 0
   expected_ibnr_numbers <- expected_ibnr_numbers[NROW(expected_ibnr_numbers):1, , drop = FALSE]

   # apply factors
   expected_ibnr_numbers <- t(t(expected_ibnr_numbers) * factors)

   # in case of only one origin year, na's are produced here, these are set to 0
   expected_ibnr_numbers[is.na(expected_ibnr_numbers)] <- 0

   # names
   rownames(expected_ibnr_numbers) <- exposure$Origin_year
   colnames(expected_ibnr_numbers) <- 2:max_dev_year_with_ibnr

   return(expected_ibnr_numbers)
}
