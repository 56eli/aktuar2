# Verbesserung zu B-V02: kalenderjahr- nach abwicklungsjahr-Dreieck ohne
# zeilenweisen R-Loop; die gueltigen Zellen werden einmal vektorisiert gefuellt.
cal_year2dev_year_v <- function(cal_year_triangle) {
   dimension <- nrow(cal_year_triangle)
   dev_year_triangle <- matrix(0, dimension, dimension)

   if (dimension > 0L) {
      row_index <- row(dev_year_triangle)
      col_index <- col(dev_year_triangle)
      keep <- row_index + col_index <= dimension + 1L
      dev_year_triangle[keep] <-
         cal_year_triangle[cbind(row_index[keep],
                                 row_index[keep] + col_index[keep] - 1L)]
   }

   rownames(dev_year_triangle) <- rownames(cal_year_triangle)
   colnames(dev_year_triangle) <- seq_len(dimension)
   return(dev_year_triangle)
}
