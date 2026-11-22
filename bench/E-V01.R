library(sicr)

# E-V01: Sortierpruefung in indices_ok() - Sortieren + elementweiser Vergleich
# gegen is.unsorted(). Gleiches Ergebnis (siehe tests/verbesserungen/test-E-V01.R),
# aber ohne zusaetzliche Kopie des Vektors.

aufsteigend <- seq_len(1000000)

bench::mark(original = any(!aufsteigend == aufsteigend[order(aufsteigend)]),
            verbessert = is.unsorted(aufsteigend),
            check = FALSE,
            iterations = 20)
