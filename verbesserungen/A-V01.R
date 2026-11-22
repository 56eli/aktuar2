# Verbesserung A-V01: pools2dataframe() ohne wiederholtes rbind() in Schleifen.
# Statt in jedem Schleifendurchlauf den bereits aufgebauten Dataframe zu kopieren,
# werden alle Teil-Dataframes gesammelt und einmal mit do.call(rbind, ...) verbunden.
pools2dataframe_v <- function(pools) {
   reserve_classes <- attr(pools, "reserve_classes")
   max_reserve_class <- length(reserve_classes)
   max_dev_year <- length(pools[[1]][[1]]) + 1

   rows <- vector("list", max_reserve_class + 1)

   for (reserve_class in 0:max_reserve_class) {
      pretail_rows <- lapply(seq_len(max(0, max_dev_year - 1)), function(dev_year) {
         data.frame(Dev_year_since_large = as.integer(dev_year + 1L),
                    Entry_reserve_class = as.integer(reserve_class),
                    pools[[1]][[reserve_class + 1]][[dev_year]])
      })

      tail_row <- data.frame(Dev_year_since_large = as.integer(max_dev_year + 1L),
                             Entry_reserve_class = as.integer(reserve_class),
                             pools[[2]][[reserve_class + 1]])

      rows[[reserve_class + 1]] <- do.call(rbind, c(pretail_rows, list(tail_row)))
   }

   do.call(rbind, rows)
}
