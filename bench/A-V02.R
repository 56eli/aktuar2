library(sicr)
library(bench)

# ---------------------------------------------------------------------------
# Benchmark A-V02: get_matrix_info() vs. get_matrix_info_v()
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "A-V02.R"))

start_of_tail <- 17
number_of_reserve_classes <- 6
lengths_vector <- c(rep(3, 90), c(5, 4, 6, 2, 7, 3))

original <- function() {
   for (reserve_class in 0:5) {
      for (dev_year in 2:50) {
         sicr:::get_matrix_info(dev_year, reserve_class, start_of_tail,
                                number_of_reserve_classes, lengths_vector, "start")
         sicr:::get_matrix_info(dev_year, reserve_class, start_of_tail,
                                number_of_reserve_classes, lengths_vector, "sample_size")
      }
   }
}

verbessert <- function() {
   for (reserve_class in 0:5) {
      for (dev_year in 2:50) {
         get_matrix_info_v(dev_year, reserve_class, start_of_tail,
                           number_of_reserve_classes, lengths_vector, "start")
         get_matrix_info_v(dev_year, reserve_class, start_of_tail,
                           number_of_reserve_classes, lengths_vector, "sample_size")
      }
   }
}

bench::mark(original = original(),
            verbessert = verbessert(),
            check = FALSE,
            iterations = 20)
