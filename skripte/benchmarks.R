# Führt alle Benchmarks unter bench/ aus und schreibt ergebnisse/benchmarks.csv
suppressPackageStartupMessages({ library(bench); library(sicr) })
Sys.setenv(AKTUAR_ROOT = normalizePath("."))
zeilen <- lapply(list.files("bench", "\\.R$", full.names = TRUE), function(f) {
  id <- sub("\\.R$", "", basename(f))
  env <- new.env()
  # jeden Top-Level-Ausdruck einzeln auswerten und alle bench_mark-Werte einsammeln,
  # auch wenn das Skript sie nur ausgibt und nicht zuweist
  werte <- tryCatch(withCallingHandlers(
    lapply(parse(f, keep.source = FALSE), eval, envir = env),
    warning = function(w) invokeRestart("muffleWarning")),
    error = function(e) { message(id, ": ", conditionMessage(e)); list() })
  kandidaten <- c(werte, mget(ls(env), envir = env))
  b <- Filter(function(x) inherits(x, "bench_mark"), kandidaten)
  if (!length(b)) return(data.frame(id = id, ausdruck = NA, median_ms = NA, speicher_mb = NA))
  b <- b[[1]]
  data.frame(id = id, ausdruck = as.character(b$expression),
             median_ms = round(as.numeric(b$median) * 1000, 3),
             speicher_mb = round(as.numeric(b$mem_alloc) / 2^20, 3))
})
erg <- do.call(rbind, zeilen)
dir.create("ergebnisse", showWarnings = FALSE)
write.csv(erg, "ergebnisse/benchmarks.csv", row.names = FALSE)
print(erg, row.names = FALSE)
