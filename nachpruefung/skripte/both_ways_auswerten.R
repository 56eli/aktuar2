# Exakter R-Port von gegenpruefung/skripte/both_ways_auswerten.py
# Aufruf aus der Repo-Wurzel:
#   Rscript nachpruefung/skripte/both_ways_auswerten.R
# Eingabe:  gegenpruefung/both_ways_roh.csv
# Ausgabe:  nachpruefung/ergebnisse/both_ways_r.csv
# Die Ausgabe soll mit gegenpruefung/both_ways.csv inhaltlich gleich sein (Python schreibt CRLF, R LF).

root <- Sys.getenv("AKTUAR_ROOT", ".")
setwd(root)
outdir <- file.path(root, "nachpruefung", "ergebnisse")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

raw_datei <- file.path(root, "gegenpruefung", "both_ways_roh.csv")
ziel_datei <- file.path(outdir, "both_ways_r.csv")
cat("Lese", raw_datei, "...\n")

roh <- read.csv(raw_datei, colClasses = "character", check.names = FALSE,
                stringsAsFactors = FALSE)

rot <- function(r) {
   r$error == "TRUE" || !(r$failed %in% c("0", ""))
}

# Letzte Zeile je (id, modus, test); die Reihenfolge des ersten Auftretens bleibt.
keys <- character(0)
last <- list()
for (i in seq_len(NROW(roh))) {
   k <- paste(roh$id[i], roh$modus[i], roh$test[i], sep = "\r")
   if (!k %in% keys) keys <- c(keys, k)
   last[[k]] <- roh[i, , drop = FALSE]
}

ids <- character(0)
for (k in keys) {
   i <- last[[k]]$id
   if (!i %in% ids) ids <- c(ids, i)
}

erg <- vector("list", length(ids))
for (j in seq_along(ids)) {
   id <- ids[j]
   blk <- list(
      orig = list(),
      patch = list(),
      mutant = list()
   )
   for (modus in names(blk)) {
      for (k in keys) {
         r <- last[[k]]
         if (r$id == id && r$modus == modus) {
            blk[[modus]][[length(blk[[modus]]) + 1L]] <- r
         }
      }
   }
   zusammen <- function(x) do.call(rbind, x)

   orig <- zusammen(blk$orig)
   patch <- zusammen(blk$patch)
   mutant <- zusammen(blk$mutant)

   ist_bug <- function(r) r$korrektur == "FALSE"
   orig_bug <- orig[vapply(seq_len(NROW(orig)), function(i) ist_bug(orig[i, ]), logical(1)), , drop = FALSE]
   patch_bug <- patch[vapply(seq_len(NROW(patch)), function(i) ist_bug(patch[i, ]), logical(1)), , drop = FALSE]
   mut_bug <- mutant[vapply(seq_len(NROW(mutant)), function(i) ist_bug(mutant[i, ]), logical(1)), , drop = FALSE]

   fo <- sum(vapply(seq_len(NROW(orig)), function(i) rot(orig[i, ]), logical(1)))
   fp <- sum(vapply(seq_len(NROW(patch)), function(i) rot(patch[i, ]), logical(1)))
   fm <- sum(vapply(seq_len(NROW(mutant)), function(i) rot(mutant[i, ]), logical(1)))

   erg[[j]] <- data.frame(
      id = id,
      test_datei = paste0("befunde/test-", id, ".R"),
      gepatchte_funktion = patch$gepatcht[1],
      failed_original = as.integer(fo),
      failed_patch = as.integer(fp),
      diskriminiert = if (fo == 0 && fp > 0) "ja" else "nein",
      failed_mutant = as.integer(fm),
      fehlerbloecke = as.integer(NROW(orig_bug)),
      korrekturbloecke = as.integer(NROW(orig) - NROW(orig_bug)),
      mutation_testet = if (fm > 0) "ja" else "nein",
      stringsAsFactors = FALSE
   )
}

ausgabe <- do.call(rbind, erg)
write.csv(ausgabe, ziel_datei, row.names = FALSE, quote = FALSE)
cat("Geschrieben:", ziel_datei, "\n")
print(ausgabe, row.names = FALSE)
