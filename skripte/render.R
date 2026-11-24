#!/usr/bin/env Rscript
# Rendert Bericht und Präsentation aus der Repo-Wurzel.
#   Rscript skripte/render.R
# Der Bericht behält sein github_document-Format (bericht/bericht.md);
# die Präsentation wird als selbstenthaltene HTML-Datei geschrieben.

root <- normalizePath(".", mustWork = TRUE)
Sys.setenv(AKTUAR_ROOT = root)
options(encoding = "UTF-8")

render_datei <- function(rel, ausgabe) {
   eingabe <- file.path(root, rel)
   if (!file.exists(eingabe)) {
      stop("Eingabe fehlt: ", eingabe, call. = FALSE)
   }
   alt <- setwd(dirname(eingabe))
   on.exit(setwd(alt), add = TRUE)
   rmarkdown::render(
      input = basename(eingabe),
      output_file = ausgabe,
      quiet = FALSE
   )
   invisible(file.path(dirname(eingabe), ausgabe))
}

render_datei(file.path("bericht", "bericht.Rmd"), "bericht.md")
render_datei(file.path("praesentation", "praesentation.Rmd"), "praesentation.html")
