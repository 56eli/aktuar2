# Verbesserung C-V01 (kuerzer / lesbarer, vektorisiert)
# generate_ibnr_pools() (R/ibnr.R:287-299) baut die Pools mit einer for-Schleife und
# einem data.frame-Filter pro Abwicklungsjahr. Das laesst sich mit einem einzigen
# logischen Vektor und lapply/which erledigen; das Ergebnis ist identisch
# (Liste der Laenge last_orig_year - first_orig_year, Eintrag k enthaelt die
# Zeilennummern der Schaeden mit Dev_year_of_growing_large == k + 1, die in
# years_for_ibnr_pools gross geworden sind).

generate_ibnr_pools_v <- function(large_claims_list,
                                  first_orig_year,
                                  last_orig_year,
                                  years_for_ibnr_pools){
   if (last_orig_year <= first_orig_year) {return(list())}

   in_pool_years <- large_claims_list$Large_since %in% years_for_ibnr_pools
   dev_year_of_growing_large <- large_claims_list$Dev_year_of_growing_large

   # Eintrag k gehoert zum Abwicklungsjahr k + 1
   lapply(seq_len(last_orig_year - first_orig_year),
          function(k) which(in_pool_years & dev_year_of_growing_large == (k + 1)))
}
