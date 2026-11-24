# Vergleicht die drei Fassungen von indices_ok_v() (E-F04, E-F05, E-V01) auf denselben Eingaben.
# Aufruf im Container: Rscript gegenpruefung/skripte/indices_varianten.R
suppressPackageStartupMessages({ library(sicr) })
root <- Sys.getenv("AKTUAR_ROOT", normalizePath("."))
b <- readRDS(file.path(root, "gegenpruefung", "cache", "basis.rds"))
good <- b$indices

lade <- function(id) {
  env <- new.env(parent = asNamespace("sicr"))
  sys.source(file.path(root, "verbesserungen", paste0(id, ".R")), envir = env)
  get("indices_ok_v", env)
}
v <- list("E-F04" = lade("E-F04"), "E-F05" = lade("E-F05"), "E-V01" = lade("E-V01"),
          "original" = sicr::indices_ok)

faelle <- list(
  gueltig = good,
  ohne_Index_re = good[, c("Calendar_year", "Index_gross", "Transition_factor")],
  Calendar_year_als_double = { d <- good; d$Calendar_year <- as.numeric(d$Calendar_year); d },
  unsortiert = good[sample(nrow(good)), ]
)

ergebnis <- function(f, x) tryCatch({
  r <- f(x, 1989, 2023); paste0(class(r)[1], ":", paste(r, collapse = ","))
}, error = function(e) paste("ERROR:", conditionMessage(e)),
   warning = function(w) paste("WARN:", conditionMessage(w)))

cat(sprintf("%-24s %-12s %-12s %-12s %-12s\n", "Fall", names(v)[1], names(v)[2], names(v)[3], names(v)[4]))
for (nm in names(faelle)) {
  cat(sprintf("%-24s %-12s %-12s %-12s %-12s\n", nm,
              ergebnis(v[[1]], faelle[[nm]]), ergebnis(v[[2]], faelle[[nm]]),
              ergebnis(v[[3]], faelle[[nm]]), ergebnis(v[[4]], faelle[[nm]])))
}

# Regression: liefert eine Fassung fuer einen Fall etwas anderes als das Original?
cat("\nAbweichung vom Original (E-F04 / E-F05 / E-V01):\n")
for (nm in names(faelle)) {
  o <- ergebnis(v[["original"]], faelle[[nm]])
  cat(sprintf("%-24s %-6s %-6s %-6s\n", nm,
              ifelse(ergebnis(v[[1]], faelle[[nm]]) == o, "gleich", "ANDERS"),
              ifelse(ergebnis(v[[2]], faelle[[nm]]) == o, "gleich", "ANDERS"),
              ifelse(ergebnis(v[[3]], faelle[[nm]]) == o, "gleich", "ANDERS")))
}
