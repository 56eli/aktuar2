# E-F06: Korrektur zu mortality_ok() (R/data_checks.R:684-688)
# Fehler: Der Tippfehler `df$Probabilty` (fehlendes "i") liefert NULL, weil "Probabilty" kein
# Praefix der Spalte "Probability" ist. any(NULL < 0 | NULL > 1) ist FALSE, die Pruefung der
# Sterbewahrscheinlichkeiten laeuft also nie. mortality_ok() gibt daher TRUE fuer Datensaetze
# mit negativen oder > 1 liegenden Wahrscheinlichkeiten zurueck (solange das Maximum 1 ist).
# Korrektur: Spaltenname Probability.

mortality_ok_v <- function(mortality) {
   structure_list <- list(
      Gender      = "character",
      Age         = "integer",
      Probability = "numeric"
   )

   structure <- data.frame(Colname = names(structure_list), Coltype = unlist(structure_list))

   df <- mortality

   p <- TRUE

   if (is.null(df)) {return(p)} #NULL is ok, dataframe will not be used then.

   # dataframe check
   if (!is.data.frame(df)) {
      cat("mortality must be a dataframe.\n")
      return(FALSE)}

   # structure check
   if (!check_dataframe_structure(df, structure)) return(FALSE)

   # check for double entries
   if (any(duplicated(df[,c("Gender", "Age")]))) {
      cat("At least one combination of Gender and Age is included more than once in mortality.\n")
      p <- FALSE
   }

   # check Gender
   if (!all(df$Gender %in% c("m", "f"))) {
      cat("At least one entry in mortality has invalid Gender. Must be one of 'f' and 'm'.\n")
      p <- FALSE
   }

   # check if all ages between 0 and max are included
   min_age_f <- min(df[df$Gender == "f", "Age"])
   min_age_m <- min(df[df$Gender == "m", "Age"])
   max_age_f <- max(df[df$Gender == "f", "Age"])
   max_age_m <- max(df[df$Gender == "m", "Age"])
   if (any(!all((min_age_f:max_age_f) %in% df[df$Gender == "f", "Age"]),
           !all((min_age_m:max_age_m) %in% df[df$Gender == "m", "Age"]))) {
      cat("Not every age between minimum and maximum age is included in mortality. Please check for gaps.\n")
      p <- FALSE
   }

   # check Probability
   if (any(df$Probability < 0 | df$Probability > 1)) {
      cat("At least one Probability in mortality is not between 0 and 1.\n")
      p <- FALSE
   }

   # check if maximum for m and f is 1.
   if (!max(df[df$Gender == "f","Probability"]) * max(df[df$Gender == "m","Probability"]) == 1) {
      cat("The maximum probability in mortality must be 1 for each female and male.\n")
      p <- FALSE
   }

   return(p)
}
