# E-F07: Korrektur zu reinsurance_ok() (R/data_checks.R:551-558)
# Fehler: Die Spalte `Limit` fehlt in structure_list, obwohl xl_cashflow() sie zwingend verwendet
# (R/reinsurance.R:300: ind_limit <- reinsurance$Limit[origin_years] * adj_factor) und die
# Dokumentation von reinsurance_xmpl sie auffuehrt (R/data.R:233). Ein Rueckversicherungs-Dataframe
# ohne Limit wird von reinsurance_ok() als gueltig akzeptiert und fuehrt erst in xl_cashflow() zu
# numerischen Null-/Fehlwerten (NULL * Vektor).
# Korrektur: Existenz der Spalte Limit pruefen (bewusst ohne Typ-/NA-Pruefung, damit
# Beispieldaten mit Limit = NA fuer Jahre ohne XL nicht abgelehnt werden).

reinsurance_ok_v <- function(reinsurance, indices, first_orig_year, last_orig_year) {

   structure_list <- list(
      Origin_year   = "integer",
      Priority      = "numeric",
      Base_year     = "integer",
      Margin_type   = "character",
      Margin        = "numeric",
      Quota_share   = "numeric"
   )

   structure <- data.frame(Colname = names(structure_list), Coltype = unlist(structure_list))

   p <- TRUE

   df <- reinsurance

   if (is.null(df)) {return(p)} #NULL is ok, dataframe will not be used then.

   # dataframe check
   if (!is.data.frame(df)) {
      cat("reinsurance must be a dataframe.\n")
      return(FALSE)}

   # structure check
   if (!check_dataframe_structure(df, structure)) return(FALSE)

   # Limit is required by xl_cashflow() (R/reinsurance.R:300)
   if (!"Limit" %in% colnames(df)) {
      cat("Column Limit is missing.\n")
      p <- FALSE
   }

   # check for double entries
   if (any(duplicated(reinsurance[,c("Origin_year")]))) {
      cat("At least one Origin_year is included more than once.\n")
      p <- FALSE
   }

   # check if one origin year is missing
   if (!all(first_orig_year:last_orig_year %in% df$Origin_year)) {
      cat("At least one Origin_year is missing in reinsurance.\n")
      p <- FALSE
   }

   # check Margin_type
   if (!all(df$Margin_type %in% c("APK", "SIC", "FIC", "none"))) {
      cat("At least one Origin_year has invalid Margin_type. Must be one of 'APK', 'SIC', 'FIC' or 'none'\n")
      p <- FALSE
   }

   # check Margin
   if (any(df$Margin < 0 | df$Margin > 1)) {
      cat("At least one Origin_year's Margin is not between 0 and 1.\n")
      p <- FALSE
   }

   # Check Quota_share
   if (any(df$Quota_share < 0 | df$Quota_share > 1)) {
      cat("At least one Origin_years' Quota_share is not between 0 and 1.\n")
      p <- FALSE
   }

   # check Base_year
   if (any(df$Base_year > last_orig_year)) {
      cat("At least one Origin_years' Base_year is greater than last_orig_year.\n")
      p <- FALSE
   }

   # check if all base_years occur in indices.
   # this is important as the base year of the first_orig_year may be smaller than first_orig_year. This has to be
   # considered in the dataframe indices
   if (!all((min(df$Base_year[df$Base_year > 0],
                 first_orig_year):last_orig_year) %in% indices$Calendar_year)) {
      cat("At least one Calendar_year is missing in indices.
          Make sure all Base_years of reinsurance are included in indices.\n")
      p <- FALSE
   }

   return(p)
}
