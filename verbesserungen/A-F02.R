# Korrektur zu A-F02 (Pretail-Bereich bei start_of_tail <= 2).
# Die Korrektur von generate_pools() steht in verbesserungen/A-F01.R (generate_pools_v).
# Hier wird die zweite betroffene Stelle korrigiert: pools2matrix() bildet die
# Pretail-Schleife ebenfalls mit 2:(start_of_tail - 1); fuer start_of_tail = 2 wird
# daraus 2:1 = c(2, 1) und damit ein Zugriff auf lengths_vector[0].
pools2matrix_v <- function(pools) {
   ### lengths vector
   # start_of_tail und Anzahl der Reserveklassen werden aus pools abgeleitet
   start_of_tail <- length(pools[[1]][[1]]) + 2
   number_of_reserve_classes <- length(pools[[1]])

   n_pretail <- max(0, start_of_tail - 2)
   pretail_dev_years <- seq_len(n_pretail) + 1

   # Groessen der Pretail-Pools (Reihenfolge: Reserveklasse, dann Abwicklungsjahr)
   lengths_pretail <- unlist(lapply(0:(number_of_reserve_classes - 1), function(reserve_class) {
      vapply(pretail_dev_years, function(dev_year) {
         as.numeric(NROW(pools[[1]][[reserve_class + 1]][[dev_year - 1]]))
      }, numeric(1))
   }))

   # Groessen der Nachlauf-Pools
   lengths_tail <- vapply(0:(number_of_reserve_classes - 1), function(reserve_class) {
      as.numeric(NROW(pools[[2]][[reserve_class + 1]]))
   }, numeric(1))

   lengths_vector <- c(lengths_pretail, lengths_tail)

   ### sample matrix
   # max(c(1, ...)) verhindert eine 0-Zeilen-Matrix, falls einmal alle Pools leer sind
   n_pool_max <- max(c(1, lengths_vector))
   sample_matrix <- matrix(0,
                           nrow = n_pool_max * number_of_reserve_classes * max(1, start_of_tail - 1),
                           ncol = 7)

   for (reserve_class in 0:(number_of_reserve_classes - 1)) {
      # Pretail-Pools
      for (dev_year in pretail_dev_years) {
         range <- sicr:::get_matrix_info(dev_year = dev_year,
                                         reserve_class = reserve_class,
                                         start_of_tail = start_of_tail,
                                         number_of_reserve_classes = number_of_reserve_classes,
                                         lengths_vector = lengths_vector,
                                         output = "range")
         sample_matrix[range, ] <-
            as.matrix(pools[[1]][[reserve_class + 1]][[dev_year - 1]][, 1:7])
      }

      # Nachlauf-Pool
      range <- sicr:::get_matrix_info(dev_year = start_of_tail,
                                      reserve_class = reserve_class,
                                      start_of_tail = start_of_tail,
                                      number_of_reserve_classes = number_of_reserve_classes,
                                      lengths_vector = lengths_vector,
                                      output = "range")
      sample_matrix[range, ] <- as.matrix(pools[[2]][[reserve_class + 1]][, 1:7])
   }

   list(lengths_vector, sample_matrix, pools[[3]])
}
