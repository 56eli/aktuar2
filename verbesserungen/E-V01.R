# E-V01: Verbesserung zu indices_ok() (R/data_checks.R:513-517)
# Die Sortierpruefung `any(!df$Calendar_year == df$Calendar_year[order(df$Calendar_year)])`
# sortiert den Vektor (O(n log n)) und vergleicht elementweise. `is.unsorted()` prueft dasselbe
# in einem Durchlauf, ohne Kopien anzulegen - kuerzer und schneller (siehe bench/E-V01.R).
# Das Verhalten der Pruefung (TRUE/FALSE, Meldung) bleibt unveraendert.

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
   if (is.unsorted(df$Calendar_year)) {
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
