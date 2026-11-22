# Führt alle Befund- und Gleichheitstests aus und schreibt eine Ergebnistabelle.
# Aufruf aus der Repo-Wurzel: Rscript skripte/tests_ausfuehren.R
suppressPackageStartupMessages({ library(testthat); library(sicr) })
root <- normalizePath(".")
Sys.setenv(AKTUAR_ROOT = root)
dateien <- c(list.files("befunde", "^test-.*\\.R$", full.names = TRUE),
             list.files("tests/verbesserungen", "^test-.*\\.R$", full.names = TRUE))
ergebnis <- do.call(rbind, lapply(dateien, function(f) {
  r <- as.data.frame(test_file(f, reporter = "silent", stop_on_failure = FALSE))
  if (!nrow(r)) return(NULL)
  data.frame(datei = f, test = r$test,
             ok = !r$failed & !r$error & !r$skipped,
             fehlgeschlagen = r$failed > 0, abbruch = r$error, uebersprungen = r$skipped > 0,
             sekunden = round(r$real, 2))
}))
dir.create("ergebnisse", showWarnings = FALSE)
write.csv(ergebnis, "ergebnisse/testergebnisse.csv", row.names = FALSE)
cat(sprintf("%d Tests: %d bestanden, %d fehlgeschlagen, %d Abbruch, %d übersprungen\n",
            nrow(ergebnis), sum(ergebnis$ok), sum(ergebnis$fehlgeschlagen),
            sum(ergebnis$abbruch), sum(ergebnis$uebersprungen)))
print(ergebnis[!ergebnis$ok, c("datei", "test")], row.names = FALSE)
quit(status = as.integer(!all(ergebnis$ok)))
