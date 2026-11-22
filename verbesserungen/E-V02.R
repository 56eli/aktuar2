# E-V02: Verbesserung zu exposure_ok() (R/data_checks.R:353-389)
# Die Funktion sammelt alle Befunde im Flag `p` und kehrt erst am Ende zurueck. Mit fruehen
# Rueckgaben (early returns) entfaellt das Flag, die Funktion wird kuerzer und der Ablauf
# offensichtlicher. Der Rueckgabewert ist identisch; bei mehreren Befunden wird nur noch die
# erste Meldung ausgegeben (das Original gab alle aus).

exposure_ok_v <- function(exposure, first_orig_year, last_orig_year) {
   structure_list <- list(
      Origin_year  = "integer",
      Exposure     = "numeric"
   )
   structure <- data.frame(Colname = names(structure_list), Coltype = unlist(structure_list))

   df <- exposure

   if (is.null(df)) return(TRUE) # NULL ist ok, der Datensatz wird dann nicht verwendet

   if (!is.data.frame(df)) {
      cat("exposure must be a dataframe.\n")
      return(FALSE)
   }

   if (!check_dataframe_structure(df, structure)) return(FALSE)

   if (anyDuplicated(df$Origin_year) > 0) {
      cat("At least one Origin_year has more than one entry in exposure.\n")
      return(FALSE)
   }

   if (!all(first_orig_year:last_orig_year %in% df$Origin_year)) {
      cat("At least one Origin_year between first_orig_year and last_orig_year is missing in exposure.\n")
      return(FALSE)
   }

   return(TRUE)
}
