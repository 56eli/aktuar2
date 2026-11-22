# Korrektur zu D-F01
#
# generate_annuity_payments() schneidet bei bekannten (aktiven) Renten das
# laufende Kalenderjahr ab: Spalte 1 der Zahlungsmatrix ist Calendar_year + 1.
# generate_annuity_probabilities() beginnt dagegen mit dem Alter im
# Calendar_year (Spalte 1 = Tod bis zum Beginn des Calendar_year, also 0).
# Dadurch wird die erste zukünftige Zahlung mit Ueberlebenswahrscheinlichkeit
# 1 statt S(1) bewertet; alle weiteren Zahlungen sind um ein Jahr verschoben.
#
# Die Korrektur verschiebt die Wahrscheinlichkeiten fuer bekannte Renten um
# eine Spalte. Fuer zukuenftige Renten aus dem Pool (future_annuities = TRUE)
# ist die urspruengliche Ausrichtung richtig, weil dort Spalte 1 der Zahlungen
# dem Eintrittsjahr (Calendar_year = Entering_year) entspricht.
generate_annuity_probabilities_v <- function(annuities,
                                             mortality,
                                             age_shift,
                                             future_annuities = FALSE) {
   probs <- sicr::generate_annuity_probabilities(annuities = annuities,
                                                 mortality = mortality,
                                                 age_shift = age_shift)
   if (future_annuities) {
      return(probs)
   }
   # Spalte j der Zahlungen gehoert zu Calendar_year + j, benoetigt wird also
   # die Sterbewahrscheinlichkeit aus Spalte j + 1. Die letzte Spalte wird mit
   # 1 aufgefuellt (nach 130 Jahren ist der Empfaenger sicher verstorben,
   # jedenfalls fuer die in mortality_xmpl vorgesehenen Alter).
   cbind(probs[, -1, drop = FALSE], 1)
}
