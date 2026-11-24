# Benchmark-Spannen ueber K unabhaengige Laeufe der vorhandenen bench/-Dateien
# Aufruf aus der Repo-Wurzel:
#   Rscript nachpruefung/skripte/benchmarks_spanne.R [K]
# K ist standardmaessig 5.

root <- Sys.getenv("AKTUAR_ROOT", ".")
setwd(root)
suppressPackageStartupMessages({ library(bench); library(sicr) })
Sys.setenv(AKTUAR_ROOT = normalizePath(root))
outdir <- file.path(root, "nachpruefung", "ergebnisse")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
K <- if (length(args) >= 1L) as.integer(args[1]) else 5L
if (is.na(K) || K < 1L) K <- 5L
cat("Benchmark-Laeufe K =", K, "\n")

alle_ids <- c("A-V01", "A-V02", "B-V01", "B-V02", "C-V01", "C-V02",
              "D-V01", "D-V02", "E-V01", "E-V02", "F-V01", "F-V02")

ein_lauf <- function(lauf) {
   cat("Lauf", lauf, "von", K, "...\n")
   set.seed(1000L + lauf)
   dateien <- list.files(file.path(root, "bench"), "\\.R$", full.names = TRUE)
   faktoren <- setNames(rep(NA_real_, length(alle_ids)), alle_ids)

   for (f in dateien) {
      id <- sub("\\.R$", "", basename(f))
      env <- new.env(parent = globalenv())
      werte <- tryCatch(
         withCallingHandlers(
            lapply(parse(f, keep.source = FALSE), eval, envir = env),
            warning = function(w) invokeRestart("muffleWarning")
         ),
         error = function(e) {
            message(id, ": ", conditionMessage(e))
            list()
         }
      )
      kandidaten <- c(werte, mget(ls(env), envir = env))
      b <- Filter(function(x) inherits(x, "bench_mark"), kandidaten)
      if (!length(b)) next
      b <- b[[1]]
      med <- as.numeric(b$median)
      names(med) <- as.character(b$expression)
      if (all(c("original", "verbessert") %in% names(med))) {
         if (is.finite(med[["verbessert"]]) && med[["verbessert"]] > 0) {
            faktoren[id] <- med[["original"]] / med[["verbessert"]]
         }
      }
   }
   data.frame(ID = alle_ids,
              Lauf = rep.int(as.integer(lauf), length(alle_ids)),
              Faktor = unname(faktoren),
              stringsAsFactors = FALSE)
}

ergebnisse <- lapply(seq_len(K), ein_lauf)
erg <- do.call(rbind, ergebnisse)
write.csv(erg, file.path(outdir, "benchmarks_spanne.csv"),
          row.names = FALSE, quote = FALSE)

zusammenfassung <- do.call(rbind, lapply(alle_ids, function(id) {
   x <- erg$Faktor[erg$ID == id]
   x <- x[is.finite(x)]
   if (!length(x)) {
      return(data.frame(ID = id, Faktor_min = NA_real_,
                        Faktor_median = NA_real_, Faktor_max = NA_real_,
                        Laeufe = 0L, stringsAsFactors = FALSE))
   }
   data.frame(ID = id,
              Faktor_min = round(min(x), 4),
              Faktor_median = round(median(x), 4),
              Faktor_max = round(max(x), 4),
              Laeufe = length(x),
              stringsAsFactors = FALSE)
}))
write.csv(zusammenfassung,
          file.path(outdir, "benchmarks_spanne_zusammenfassung.csv"),
          row.names = FALSE, quote = FALSE)

cat("Geschrieben:", file.path(outdir, "benchmarks_spanne.csv"), "\n")
cat("Geschrieben:",
    file.path(outdir, "benchmarks_spanne_zusammenfassung.csv"), "\n")
print(zusammenfassung, row.names = FALSE)
