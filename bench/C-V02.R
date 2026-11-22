# Benchmark zu C-V02: ibnr_transform2dataframe() (dplyr/tidyr) gegen die
# base-R-Variante. Beide erzeugen dieselbe Tabelle (siehe tests/verbesserungen/test-C-V02.R).

library(sicr)

source(file.path(Sys.getenv("AKTUAR_ROOT", "../.."), "verbesserungen", "C-V02.R"))

set.seed(42)
# realistische Groesse: 40 Anfalljahre x 60 Abwicklungsjahre mit 0 bis 2 erwarteten
# IBNR-Schaeden je Zelle (nach der Rundung), d.h. einige tausend Zeilen Ausgabe
expected_rounded_ibnr_numbers <- matrix(sample(0:2, 40 * 60, replace = TRUE),
                                        nrow = 40,
                                        dimnames = list(2000:2039, 2:61))

ergebnis <- bench::mark(original = ibnr_transform2dataframe(expected_rounded_ibnr_numbers),
                        verbessert = ibnr_transform2dataframe_v(expected_rounded_ibnr_numbers),
                        check = FALSE,
                        iterations = 20)
print(ergebnis)
