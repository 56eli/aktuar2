# Korrektur zu B-F03: seq_len(0) statt 1:0, damit leere Dreiecke nicht
# durch einen Zugriff auf die nicht vorhandene Zeile 1 abstuerzen.
inc2cum_v <- function(incr_triangle) {
   incr_triangle <- rbind(incr_triangle)
   cum_triangle <- incr_triangle
   for (i in seq_len(NROW(incr_triangle))) {
      cum_triangle[i, ] <- cumsum(incr_triangle[i, ])
   }
   return(cum_triangle)
}
