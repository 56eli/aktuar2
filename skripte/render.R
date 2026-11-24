#!/usr/bin/env Rscript
# Rendert Bericht und Methoden-Artefakt aus der Repo-Wurzel.
#   Rscript skripte/render.R
# Der Bericht behält sein github_document-Format (bericht/bericht.md);
# das Artefakt wird als selbstenthaltene HTML-Datei geschrieben.

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
render_datei(file.path("artefakt", "sicr_methode.Rmd"), "sicr_methode.html")

# Das Artefakt muss ohne Netz auskommen: keine externen Skripte, Stile, Schriften
# oder Bilder und kein MathJax-Lader.
html_pfad <- file.path("artefakt", "sicr_methode.html")
html <- paste(readLines(html_pfad, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
link_tags <- regmatches(html, gregexpr("<link[^>]*>", html,
                                       ignore.case = TRUE, perl = TRUE))[[1]]
extern <- grepl('src="http', html, fixed = TRUE) ||
   any(grepl('href="http', link_tags, fixed = TRUE)) ||
   grepl("@import", html, fixed = TRUE) ||
   grepl("url(http", html, fixed = TRUE) ||
   grepl("mathjax", html, ignore.case = TRUE)
if (extern) {
   stop("sicr_methode.html lädt externe Ressourcen oder MathJax", call. = FALSE)
}
