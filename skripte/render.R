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
extern_url <- "(https?:)?//"
extern <- grepl(paste0("(?i)\\bsrc\\s*=\\s*[\"']?", extern_url), html, perl = TRUE) ||
   any(grepl(paste0("(?i)\\bhref\\s*=\\s*[\"']?", extern_url), link_tags, perl = TRUE)) ||
   grepl("(?i)@import", html, perl = TRUE) ||
   grepl(paste0("(?i)url\\(\\s*[\"']?", extern_url), html, perl = TRUE) ||
   grepl("(?i)<script[^>]*mathjax", html, perl = TRUE)
if (extern) {
   stop("sicr_methode.html lädt externe Ressourcen oder MathJax", call. = FALSE)
}
