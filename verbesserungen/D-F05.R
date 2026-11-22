# Korrektur zu D-F05
#
# fill_up_triangle() verwendet `for (aj in (1:(ndim0 - 1)))`. Bei einem
# einspaltigen Dreieck ist das 1:0 = c(1, 0); fuer aj = 1 wird Spalte 2
# adressiert (bei ndim == ndim0 existiert sie nicht) und fuer aj = 0 wird in
# Zeile n_row + 1 geschrieben. Das fuehrt zu "subscript out of bounds".
#
# Die Korrektur iteriert nur ueber vorhandene Pretail-Spalten und liefert
# fuer ein einspaltiges Dreieck das (ggf. um den Tail erweiterte) Dreieck.
fill_up_triangle_v <- function(triangle,
                               pattern = NULL) {
   if (is.null(pattern)) {
      pattern <- if (ncol(triangle) > 1) {
         sicr::generate_pattern(triangle = triangle)
      } else {
         numeric(0)
      }
   }

   ndim0 <- ncol(triangle)
   ndim <- NROW(pattern) + 1
   n_row <- nrow(triangle)

   filled_triangle <- triangle
   if (ndim > ndim0) {
      filled_triangle <- cbind(filled_triangle,
                               matrix(0, ndim0, ndim - ndim0))
   }

   if (ndim0 > 1) {
      for (aj in seq_len(ndim0 - 1)) {
         filled_triangle[(n_row - aj + 1):n_row, aj + 1] <-
            filled_triangle[(n_row - aj + 1):n_row, aj] * pattern[aj]
      }
   }

   if (ndim > ndim0) {
      for (aj in ndim0:(ndim - 1)) {
         filled_triangle[, aj + 1] <- filled_triangle[, aj] * pattern[aj]
      }
   }

   colnames(filled_triangle) <- seq_len(ncol(filled_triangle))
   return(filled_triangle)
}
