#!/usr/bin/env Rscript
# Prueft, dass jeder "Reproduktion"-Block in upstream.md wie abgedruckt laeuft.
# Aufruf im Container: Rscript gegenpruefung/skripte/pruefe_upstream.R
root <- Sys.getenv("AKTUAR_ROOT", normalizePath("."))
md <- readLines(file.path(root, "gegenpruefung", "upstream.md"), warn = FALSE)
bloecke <- list(); id <- NA; offen <- FALSE; aktuell <- character(0)
for (z in md) {
  if (grepl("^### ", z)) id <- sub("^### ([A-Z]-[A-Z0-9]+).*", "\\1", z)
  if (!offen && grepl("^\\*\\*Reproduktion\\*\\*", z)) { starte <- TRUE; next }
  if (exists("starte") && starte && grepl("^```r$", z)) { offen <- TRUE; aktuell <- character(0); next }
  if (offen && grepl("^```$", z)) {
    bloecke[[length(bloecke) + 1]] <- list(id = id, code = aktuell)
    offen <- FALSE; starte <- FALSE; next
  }
  if (offen) aktuell <- c(aktuell, z)
}
cat("Blöcke gefunden:", length(bloecke), "\n")
for (b in bloecke) {
  f <- tempfile(fileext = ".R"); writeLines(b$code, f)
  r <- system2("Rscript", f, stdout = TRUE, stderr = TRUE)
  ok <- identical(attr(r, "status"), NULL)
  cat(sprintf("%-6s %-4s %s\n", b$id, if (ok) "ok" else "FEHLER",
              if (ok) tail(r[nzchar(r)], 2)[1] else paste(head(r, 2), collapse = " | ")))
}
