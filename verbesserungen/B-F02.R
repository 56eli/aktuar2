# Korrektur zu B-F02: index_year explizit validieren, statt mit einem
# numeric(0)-Nenner und einer kryptischen data.frame-Fehlermeldung abzubrechen.
add_transition_factor_v <- function(expanded_indices, index_year) {
   if (length(index_year) != 1L || is.na(index_year)) {
      stop("index_year must be a single calendar year")
   }
   if (anyDuplicated(expanded_indices$Calendar_year)) {
      stop("expanded_indices must not contain duplicate calendar years")
   }

   index_position <- match(index_year, expanded_indices$Calendar_year)
   if (is.na(index_position)) {
      stop("index_year must be contained in expanded_indices")
   }

   factors <- cumprod(1 + expanded_indices$Index_gross)
   expanded_indices$Transition_factor <- factors / factors[index_position]
   attr(expanded_indices, "index_year") <- index_year
   expanded_indices
}
