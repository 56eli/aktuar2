# Korrektur zu D-F01
#
# Bei bekannten Renten gehört Spalte j der Zahlungsmatrix zum Jahr Calendar_year + j. Die Zahlung zu
# Beginn von Cy+1 ist sicher (Rente zum Stichtag aktiv), danach muss der Rentner die Jahre Cy+1, Cy+2, …
# überleben, in denen er die Alter x+1, x+2, … erreicht (x = Cy - Birth_year). Statt q(x), q(x+1), …
# braucht es also q(x+1), q(x+2), … Das erreicht man, indem man das Bewertungsjahr um eins erhöht;
# die Altersverschiebung hängt nur vom Geburtsjahr ab und bleibt dadurch unverändert.
#
# Für künftige Renten aus dem Pool (Spalte 1 = Eintrittsjahr) ist die Ausrichtung von sicr richtig.
generate_annuity_probabilities_v <- function(annuities, mortality, age_shift,
                                             future_annuities = FALSE) {
   if (!future_annuities) {
      annuities$Calendar_year <- annuities$Calendar_year + 1L
   }
   sicr::generate_annuity_probabilities(annuities = annuities, mortality = mortality,
                                        age_shift = age_shift)
}
