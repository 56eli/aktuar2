# Korrektur zu C-F04
# generate_xl_indices_per_claim() (R/reinsurance.R:47-104) verankert die Indexklausel
# ein Jahr zu frueh. Zeile 76 bildet
#     cum_indices <- cumprod((1 + Index_re)[B : n])
# und Zeile 78/85 legt diesen Vektor ab Stelle B in die Matrix. Damit ist der Faktor
# im Basisjahr B bereits (1 + Index_re[B]) statt 1. Laut Doku (R/reinsurance.R:139-158)
# gilt aber f_i = 1, solange I_i/I_B < 1 + alpha, und im Basisjahr ist I_B/I_B = 1.
# Der implementierte Faktor entspricht I_i/I_(B-1): die Prioritaet wird um ein volles
# Indexjahr zu stark hochindexiert (und die Klausel greift ein Jahr zu frueh), wodurch
# der RV-Anteil systematisch zu klein ausfaellt.
# Korrektur: Faktor 1 bis einschliesslich Basisjahr, Indexierung ab B+1.

generate_xl_indices_per_claim_v <- function(claims_list,
                                            reinsurance,
                                            indices,
                                            first_orig_year,
                                            last_orig_year){
   # if reinsurance contains rows for younger origin years that last_orig_year, these rows must be deleted
   reinsurance <- reinsurance[reinsurance$Origin_year <= last_orig_year,]

   number_of_rows <- last_orig_year - first_orig_year + 1
   number_of_calendar_years <- NROW(indices)
   xl_indices_matrix <- matrix(nrow = number_of_rows,
                               ncol = number_of_calendar_years)
   for (current_row in 1:number_of_rows) {
      row_in_reinsurance_df <- which(reinsurance$Origin_year == (first_orig_year + current_row - 1))
      # throw error if there is no row for that origin year in reinsurance
      if (length(row_in_reinsurance_df) == 0) {
         stop(paste("No row in dataframe reinsurance for origin year", first_orig_year + current_row - 1))
      }
      indexation_year <- reinsurance$Base_year[row_in_reinsurance_df]
      margin_type <- reinsurance$Margin_type[row_in_reinsurance_df]
      if (margin_type == "FIC") {
         margin_type <- "APK"
         margin <- 0
      } else {
         margin <- reinsurance$Margin[row_in_reinsurance_df]}

      if (indexation_year == 0 | margin_type == "none") {
         xl_indices_matrix[current_row,] <- rep(1, number_of_calendar_years)
      } else {
         first_index_year <- indices$Calendar_year[1]
         position_of_base_year <- which(indices$Calendar_year == indexation_year)
         # Korrektur: die Indexierung beginnt erst im Jahr NACH dem Basisjahr,
         # im Basisjahr selbst ist I_B/I_B = 1
         cum_indices <- cumprod((1 + indices$Index_re)[seq.int(from = position_of_base_year + 1,
                                                               length.out = NROW(indices) - position_of_base_year)])
         if (margin_type == "APK") {
            xl_indices_matrix[current_row,] <- c(rep(1, indexation_year - first_index_year + 1),
                                                 ifelse(cum_indices >= (1 + margin),
                                                        cum_indices,
                                                        1))
         }

         if (margin_type == "SIC") {
            xl_indices_matrix[current_row,] <- c(rep(1, indexation_year - first_index_year + 1),
                                                 ifelse(cum_indices >= (1 + margin),
                                                        cum_indices/(1 + margin),
                                                        1))
         }
      }
   }

   rownames(xl_indices_matrix) <- first_orig_year:last_orig_year
   colnames(xl_indices_matrix) <- indices$Calendar_year

   xl_indices_per_claim <- xl_indices_matrix[c(as.character(claims_list$Origin_year)),
                                             colnames(xl_indices_matrix) >= first_orig_year,
                                             drop = FALSE]

   rownames(xl_indices_per_claim) <- claims_list$Claim_id
   return(xl_indices_per_claim)
}
