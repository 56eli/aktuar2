# Korrektur zu B-F04: leere Vektoren und leere Matrizen werden ohne
# NA-Erzeugung bzw. Dimensionsfehler unveraendert zurueckgegeben.
cum2inc_v <- function(cum_triangle) {
   if (is.vector(cum_triangle)) {
      if (length(cum_triangle) == 0L) {
         return(cum_triangle)
      }
      inc_triangle <- c(cum_triangle[1], diff(cum_triangle))
      return(inc_triangle)
   }

   if (NROW(cum_triangle) == 0L || NCOL(cum_triangle) == 0L) {
      return(cum_triangle)
   }

   inc_triangle <- cbind(cum_triangle[, 1],
                         t(diff(t(cum_triangle))))
   colnames(inc_triangle) <- colnames(cum_triangle)
   return(inc_triangle)
}
