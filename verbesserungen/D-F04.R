# Korrektur zu D-F04
#
# generate_pattern() verwendet `1:(ndim0 - 1)` und ruft cl_factor() auch dann
# mit dev_year = 0 auf, wenn das Dreieck nur eine Spalte (ein einziges
# Abwicklungsjahr) hat. 1:0 ist c(1, 0); cl_factor(., 0) bricht mit
# "dev_year must be integer greater 0" ab.
#
# Die Korrektur iteriert nur ueber tatsaechlich vorhandene Abwicklungsjahre
# und liefert fuer ein einspaltiges Dreieck einen leeren Pattern-Vektor.
# Zusaetzlich wird int2ext_transition auch auf Werte < 1 geprueft.
generate_pattern_v <- function(triangle,
                               volume = NULL,
                               external_pattern = NULL,
                               int2ext_transition = NULL) {
   ndim0 <- ncol(triangle)
   ndim <- if (is.null(external_pattern)) ndim0 else NROW(external_pattern) + 1

   internal_pattern <- rep(1, max(0, ndim0 - 1))
   if (ndim0 > 1) {
      for (dev_year in seq_len(ndim0 - 1)) {
         internal_pattern[dev_year] <- sicr::cl_factor(triangle, dev_year, volume)
      }
   }

   pattern <- internal_pattern
   if (is.null(int2ext_transition)) {
      int2ext_transition <- ndim0
   } else if (int2ext_transition > ndim |
              int2ext_transition < 1 |
              int2ext_transition %% 1 != 0) {
      int2ext_transition <- ndim0
   }

   if (!is.null(external_pattern) & ndim > int2ext_transition) {
      pattern[min(ndim0, int2ext_transition):(ndim - 1)] <-
         external_pattern[min(ndim0, int2ext_transition):(ndim - 1)]
   }

   return(pattern)
}
