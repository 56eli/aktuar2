# Verbesserung zu B-V01: direkte Umsetzung der Paperformel ohne doppeltes pmin;
# dadurch kuerzer und unmittelbar als lineare Abnahme lesbar.
tail_factor_v <- function(dev_year,
                          start_of_tail,
                          end_of_tail) {
   tail_length <- end_of_tail - start_of_tail + 1
   pmax(0, pmin(1, (end_of_tail - dev_year + 1) / tail_length))
}
