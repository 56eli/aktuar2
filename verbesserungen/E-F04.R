# E-F04: Korrektur zu indices_ok() (R/data_checks.R:477-532)
# Fehler: indices_ok() legt in Zeile 479-485 eine Struktur (Calendar_year, Index_gross, Index_re)
# an, ruft check_dataframe_structure() aber nie auf. Fehlende Spalten (z. B. Index_re) oder falsche
# Spaltentypen werden deshalb nicht erkannt; der Aufruf in sicr() (R/sicr.R:331) laesst ungueltige
# Indizes durch, was erst tief in xl_cashflow()/apply_index() zu falschen Ergebnissen oder Fehlern fuehrt.
# Korrektur: Strukturpruefung direkt nach der Dataframe-Pruefung.

indices_ok_v <- function(indices, first_orig_year, last_orig_year) {

   structure_list <- list(
      Calendar_year = "integer",
      Index_gross   = "numeric",
      Index_re      = "numeric"
   )

   structure <- data.frame(Colname = names(structure_list), Coltype = unlist(structure_list))

   p <- TRUE

   df <- indices

   # check for NULL
   if (is.null(df)) {
      cat("indices must not be NULL.")
      return("FALSE")}

   # dataframe check
   if (!is.data.frame(df)) {
      cat("indices must be a dataframe.\n")
      return(FALSE)}

   # structure check (fehlte im Original)
   if (!check_dataframe_structure(df, structure)) return(FALSE)

   # check for double entries
   if (any(duplicated(df[,c("Calendar_year")]))) {
      cat("At least one Calendar_year is included more than once.\n")
      p <- FALSE
   }

   # check if all calendar years + 250 future calendar years are included
   if (!all(first_orig_year:(last_orig_year + 250) %in% df$Calendar_year)) {
      cat("At least one Calendar_year between first_orig_year and last_orig_year + 250 is missing.\n")
      p <- FALSE
   }

   # check for correct order
   if (any(!df$Calendar_year == df$Calendar_year[order(df$Calendar_year)])) {
      cat("Calendar_year is in wrong order.\n")
      p <- FALSE
   }

   # check if index is between -1 and 1
   if (any(df$Index_re < -1 | df$Index_re > 1 | df$Index_gross < -1 | df$Index_gross > 1)) {
      cat("At least one index is not between -1 and 1.\n")
      p <- FALSE
   }

   # check for attribute index_year
   if (!is.numeric(attr(df, "index_year"))) {
      cat("Attribute index_year is missing. Please use predefined functions to create dataframe indices.")
      p <- FALSE
   }

   return(p)
}
