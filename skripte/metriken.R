# Code-Metriken für sicr 1.1.1: Umfang je Datei, zyklomatische Komplexität je Funktion,
# lintr-Befunde je Regel und Anteil doppelter Codezeilen je Datei.
# Aufruf: Rscript skripte/metriken.R [Pfad zum sicr-Quellbaum, Standard /sicr]
suppressPackageStartupMessages({ library(sicr); library(cyclocomp); library(lintr) })
args <- commandArgs(trailingOnly = TRUE)
quelle <- if (length(args)) args[1] else "/sicr"
dateien <- sort(list.files(file.path(quelle, "R"), "\\.R$", full.names = TRUE))
dir.create("ergebnisse", showWarnings = FALSE)

codezeilen <- function(f) {
  z <- trimws(readLines(f, warn = FALSE))
  z[nzchar(z) & !startsWith(z, "#")]
}

# Umfang und Duplikate: eine Codezeile gilt als Duplikat, wenn sie (ohne Einrückung, mindestens
# 25 Zeichen lang, damit "}" und "return(x)" nicht zählen) in der Datei mehr als einmal vorkommt.
umfang <- do.call(rbind, lapply(dateien, function(f) {
  z <- readLines(f, warn = FALSE); code <- codezeilen(f)
  lang <- code[nchar(code) >= 25]
  data.frame(datei = basename(f), zeilen = length(z), codezeilen = length(code),
             roxygen = sum(startsWith(trimws(z), "#'")),
             duplikat_anteil = if (length(lang)) round(mean(lang %in% lang[duplicated(lang)]), 3) else 0)
}))

# Zyklomatische Komplexität aller Funktionen im Namensraum (exportiert und intern)
ns <- asNamespace("sicr")
fn <- Filter(function(n) is.function(get(n, ns)), ls(ns, all.names = TRUE))
komplex <- data.frame(funktion = fn,
                      komplexitaet = vapply(fn, function(n) cyclocomp(get(n, ns)), numeric(1)),
                      exportiert = fn %in% getNamespaceExports("sicr"), row.names = NULL)
komplex <- komplex[order(-komplex$komplexitaet), ]

# lintr mit Standardregeln, außer Zeilenlänge (sicr nutzt bewusst 120 Zeichen) und Einrückung
# (sicr rückt mit 3 Leerzeichen ein): beides Stil, keine Qualitätsaussage.
regeln <- linters_with_defaults(line_length_linter = line_length_linter(120), indentation_linter = NULL)
l <- do.call(rbind, lapply(dateien, function(f) as.data.frame(lint(f, linters = regeln))))
lints <- if (nrow(l)) aggregate(list(anzahl = l$linter), list(regel = l$linter), length) else
  data.frame(regel = character(), anzahl = integer())
lints <- lints[order(-lints$anzahl), ]

write.csv(umfang, "ergebnisse/metriken_dateien.csv", row.names = FALSE)
write.csv(komplex, "ergebnisse/metriken_komplexitaet.csv", row.names = FALSE)
write.csv(lints, "ergebnisse/metriken_lintr.csv", row.names = FALSE)
print(umfang, row.names = FALSE)
cat("\nFunktionen:", nrow(komplex), "davon exportiert:", sum(komplex$exportiert), "\n")
print(head(komplex, 12), row.names = FALSE)
cat("\nlintr gesamt:", sum(lints$anzahl), "\n"); print(lints, row.names = FALSE)
