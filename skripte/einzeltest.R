# Führt eine Testdatei mit ausführlicher Ausgabe aus: Rscript skripte/einzeltest.R <datei>
suppressPackageStartupMessages({ library(testthat); library(sicr) })
Sys.setenv(AKTUAR_ROOT = normalizePath("."))
for (f in commandArgs(TRUE)) { cat("=====", f, "\n"); test_file(f, reporter = "check", stop_on_failure = FALSE) }
