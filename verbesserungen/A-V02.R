# Verbesserung A-V02: get_matrix_info() ohne ifelse().
# ifelse() wertet beide Zweige aus; beim Nachlauf werden dadurch Indizes gebildet,
# die weit ausserhalb von lengths_vector bzw. der sample_matrix liegen (nur der
# nicht zurueckgegebene Zweig ist betroffen). Hier werden nur die tatsaechlich
# benoetigten Indizes berechnet; zusaetzlich werden die Argumente explizit
# auf gleiche Laenge gebracht.
get_matrix_info_v <- function(dev_year,
                              reserve_class,
                              start_of_tail,
                              number_of_reserve_classes,
                              lengths_vector,
                              output) {
   n <- max(length(dev_year), length(reserve_class))
   dev_year <- rep_len(dev_year, n)
   reserve_class <- rep_len(reserve_class, n)

   n_pretail <- start_of_tail - 2
   n_pool_max <- max(lengths_vector)
   is_tail <- dev_year > (start_of_tail - 1)

   sample_size <- numeric(n)
   start <- numeric(n)

   if (any(!is_tail)) {
      sample_size[!is_tail] <-
         lengths_vector[dev_year[!is_tail] - 1 + reserve_class[!is_tail] * n_pretail]
      start[!is_tail] <-
         (reserve_class[!is_tail] * n_pretail + dev_year[!is_tail] - 2) * n_pool_max + 1
   }

   if (any(is_tail)) {
      sample_size[is_tail] <-
         lengths_vector[number_of_reserve_classes * n_pretail + reserve_class[is_tail] + 1]
      start[is_tail] <-
         (number_of_reserve_classes * n_pretail + reserve_class[is_tail]) * n_pool_max + 1
   }

   if (output == "sample_size") return(sample_size)
   if (output == "start") return(start)
   if (output == "range") return(start:(start + sample_size - 1))
   stop("Output must be sample_size, start or range!")
}
