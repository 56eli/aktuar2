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

# ioslides laedt MathJax immer von mathjax.rstudio.com nach, auch ohne Formeln. Die Folien
# enthalten keine Formeln; der Lader wird entfernt, damit die HTML-Datei ohne Netz auskommt.
html_pfad <- file.path("praesentation", "praesentation.html")
html <- paste(readLines(html_pfad, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
html <- sub("(?s)<!-- dynamically load mathjax[^\n]*\n<script>.*?</script>\n", "", html, perl = TRUE)
if (grepl("mathjax.rstudio.com", html, fixed = TRUE)) stop("MathJax-Lader nicht entfernt")
writeLines(html, html_pfad, useBytes = TRUE)
