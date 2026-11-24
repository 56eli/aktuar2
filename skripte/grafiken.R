# Gemeinsame Daten- und Grafikfunktionen für Prüfbericht und Präsentation.
# Alle Funktionen lesen die Quellen im Repo über einen Wurzelpfad; Standard ist
# die Umgebungsvariable AKTUAR_ROOT, sonst das aktuelle Verzeichnis.
#
# Verwendung aus bericht/ oder praesentation/:
#   source("../skripte/grafiken.R")
#   grafik_paper(root = "..")

standard_wurzel <- function(root) {
   normalizePath(root, mustWork = FALSE)
}

lies_zeilen <- function(datei) {
   readLines(datei, encoding = "UTF-8", warn = FALSE)
}

gruppen <- c(A = "Kernsimulation", B = "Datenaufbereitung",
             C = "IBNR, Sonderschäden, RV", D = "Renten, Basisschäden",
             E = "Ausgabe, Eingabeprüfungen", F = "Plots, Backtesting")

# Colourblind-safe palette (Okabe-Ito), consistent across all figures.
pal_schwere <- c(kritisch = "#CC79A7", hoch = "#D55E00",
                 mittel = "#E69F00", niedrig = "#56B4E9")
pal_paper <- c("konform" = "#009E73", "konform (Fehler)" = "#E69F00",
               "abweichend" = "#D55E00", "optional" = "#56B4E9",
               "kein Paperbezug" = "#999999")
pal_status <- c("grün" = "#009E73", "rot" = "#D55E00",
                "keine Daten" = "#E8E8E8")
pal_richtung <- c(schneller = "#009E73", langsamer = "#D55E00")

theme_aktuar <- function(base_size = 12) {
   ggplot2::theme_minimal(base_size = base_size) +
      ggplot2::theme(
         plot.title = ggplot2::element_text(face = "bold", size = base_size + 2,
                                            hjust = 0, colour = "#222222"),
         plot.subtitle = ggplot2::element_text(colour = "#555555"),
         plot.caption = ggplot2::element_text(colour = "#666666",
                                              size = base_size - 3, hjust = 0),
         axis.title = ggplot2::element_text(colour = "#333333"),
         axis.text = ggplot2::element_text(colour = "#333333"),
         panel.grid.minor = ggplot2::element_blank(),
         panel.grid.major = ggplot2::element_line(colour = "#E5E5E5", linewidth = 0.3),
         legend.position = "bottom",
         legend.title = ggplot2::element_blank(),
         plot.title.position = "plot",
         plot.caption.position = "plot",
         plot.margin = ggplot2::margin(8, 12, 8, 8)
      )
}

# ---------------------------------------------------------------------------
# Daten aus den Markdown-Quellen
# ---------------------------------------------------------------------------

daten_befunde <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   root <- standard_wurzel(root)
   dateien <- sort(Sys.glob(file.path(root, "analyse", "[A-F]_*.md")))
   zeilen <- unlist(lapply(dateien, function(f) {
      grep("^\\| [A-F]-[A-Z][0-9]+ \\|", lies_zeilen(f), value = TRUE)
   }), use.names = FALSE)
   teile <- lapply(strsplit(zeilen, "\\|"), function(x) trimws(x[2:6]))
   t <- do.call(rbind, teile)
   data.frame(id = t[, 1], funktion = t[, 2], art = t[, 3],
              schwere = t[, 4], beschreibung = t[, 5],
              stringsAsFactors = FALSE)
}

daten_fehler <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   b <- daten_befunde(root)
   b$gruppe <- substr(b$id, 1, 1)
   b$typ <- substr(b$id, 3, 3)
   f <- b[b$typ == "F", , drop = FALSE]
   f$schwere <- factor(f$schwere, c("kritisch", "hoch", "mittel", "niedrig"))
   f[order(f$schwere, f$id), , drop = FALSE]
}

daten_verbesserungen <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   b <- daten_befunde(root)
   b$gruppe <- substr(b$id, 1, 1)
   b$typ <- substr(b$id, 3, 3)
   v <- b[b$typ == "V", , drop = FALSE]
   v[order(v$gruppe, v$id), , drop = FALSE]
}

daten_paper <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   root <- standard_wurzel(root)
   f <- file.path(root, "analyse", "paper_abgleich.md")
   z <- grep("^\\| D\\.[0-9]+\\.[0-9]+ \\|", lies_zeilen(f), value = TRUE)
   teile <- strsplit(z, "\\|")
   d <- data.frame(
      nr = trimws(vapply(teile, `[`, character(1), 2)),
      einstufung = trimws(vapply(teile, `[`, character(1), 5)),
      stringsAsFactors = FALSE
   )
   d$kapitel <- sub("^D\\.([0-9]+).*$", "D.\\1", d$nr)
   d$einstufung <- factor(
      d$einstufung,
      levels = c("konform", "konform (Fehler)", "abweichend",
                 "optional", "kein Paperbezug")
   )
   d
}

# ---------------------------------------------------------------------------
# Grafiken
# ---------------------------------------------------------------------------

grafik_paper <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   d <- daten_paper(root)
   d$kapitel <- factor(d$kapitel, levels = paste0("D.", 1:11))
   ggplot2::ggplot(d, ggplot2::aes(x = kapitel, fill = einstufung)) +
      ggplot2::geom_bar(width = 0.72) +
      ggplot2::scale_fill_manual(values = pal_paper, drop = FALSE, name = NULL) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.05))) +
      ggplot2::labs(
         x = "Kapitel der Checkliste", y = "Prüfpunkte",
         title = sprintf("%d Prüfpunkte der eigenen Checkliste D.1–D.11", nrow(d)),
         subtitle = "Aus Kapitel 2 abgeleitet; der DAV-Bericht hat keinen Anhang D",
         caption = "Quelle: analyse/paper_abgleich.md"
      ) +
      theme_aktuar() +
      ggplot2::theme(legend.position = "bottom")
}

grafik_schwere <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   d <- daten_fehler(root)
   d$gruppe <- factor(d$gruppe, levels = names(gruppen))
   beschriftung <- c(
      A = "A\nKernsimulation", B = "B\nDatenaufbereitung",
      C = "C\nIBNR, Sonder,\nRV", D = "D\nRenten,\nBasisschäden",
      E = "E\nAusgabe,\nPrüfungen", F = "F\nPlots,\nBacktesting"
   )
   ggplot2::ggplot(d, ggplot2::aes(x = gruppe, fill = schwere)) +
      ggplot2::geom_bar(width = 0.72) +
      ggplot2::scale_fill_manual(values = pal_schwere, drop = TRUE, name = NULL) +
      ggplot2::scale_x_discrete(labels = beschriftung) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.05))) +
      ggplot2::labs(
         x = NULL, y = "belegte Fehler",
         title = sprintf("%d belegte Fehler nach Gruppe und Schwere", nrow(d)),
         subtitle = sprintf("%d kritisch · %d hoch · %d mittel · %d niedrig",
                            sum(d$schwere == "kritisch"), sum(d$schwere == "hoch"),
                            sum(d$schwere == "mittel"), sum(d$schwere == "niedrig")),
         caption = "Quelle: analyse/A_*.md bis analyse/F_*.md"
      ) +
      theme_aktuar() +
      ggplot2::theme(legend.position = "bottom")
}

grafik_wirkung <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   root <- standard_wurzel(root)
   w <- utils::read.csv(file.path(root, "nachpruefung", "ergebnisse", "wirkung.csv"),
                        stringsAsFactors = FALSE, check.names = FALSE)
   wert <- function(id, muster = NULL) {
      i <- which(w$ID == id)
      if (!is.null(muster)) i <- i[grepl(muster, w$Groesse[i], fixed = TRUE)]
      if (!length(i)) return(NA_real_)
      w$Abweichung_prozent[i[1]]
   }

   # F-F01 aus dem Vignetten-Backtesting: Korrektur hebt den Ist-Wert an.
   ff <- utils::read.csv(file.path(root, "nachpruefung", "ergebnisse", "f_f01_vignette.csv"),
                         stringsAsFactors = FALSE, check.names = FALSE)
   i_ff <- which(ff$Reserveklasse == "Summe")[1]
   ff_wert <- if (length(i_ff) && is.finite(ff$Ist_original[i_ff]) &&
                 ff$Ist_original[i_ff] != 0) {
      (ff$Ist_korrigiert[i_ff] / ff$Ist_original[i_ff] - 1) * 100
   } else {
      wert("F-F01", "1. Folgejahr")
   }

   d <- data.frame(
      id = c("A-F01", "A-F01", "A-F01", "D-F01", "D-F07",
             "E-F01", "E-F01", "F-F01", "B-F01", "C-F03", "D-F03/E-F02"),
      beschriftung = c(
         "A-F01 Nachlaufpool, Grenzen 0/100k",
         "A-F01 Nachlaufpool, Grenzen 0/250k",
         "A-F01 Nachlaufpool, Grenzen 0/500k",
         "D-F01 undiskontierte Renten",
         "D-F07 künftige Basisrenten, Indexjahr 2022/2018",
         "E-F01 Nettoreserve, Priorität 500.000",
         "E-F01 zediertes XL, Priorität 500.000",
         "F-F01 Ist-Wert im Vignetten-Backtest",
         "B-F01 Jahre mit falschem Index",
         "C-F03 erwartete IBNR-Schäden",
         "D-F03/E-F02 Anfalljahre mit falscher Quote"
      ),
      wert = c(
         wert("A-F01", "0/1e+05"),
         wert("A-F01", "0/250000"),
         wert("A-F01", "0/5e+05"),
         wert("D-F01", "Undiskontierte"),
         wert("D-F07", "Indexjahr 2022 gegen 2018"),
         wert("E-F01", "Nettoreserve Grossschaden, Prioritaet 500000"),
         wert("E-F01", "Zediertes XL Grossschaden, Prioritaet 500000"),
         ff_wert,
         wert("B-F01", "Anteil Jahre"),
         wert("C-F03", "Summe erwartete"),
         wert("D-F03/E-F02", "Anteil Anfalljahre")
      ),
      art = c(rep("gemessen", 8), rep("permutationsabhängig", 3)),
      stringsAsFactors = FALSE
   )
   d$art <- factor(d$art, c("gemessen", "permutationsabhängig"))
   d$panel <- factor(ifelse(d$id %in% c("B-F01", "D-F03/E-F02"),
                            "Anteil falsch zugeordneter Jahre",
                            "Änderung durch die Korrektur"),
                     c("Änderung durch die Korrektur", "Anteil falsch zugeordneter Jahre"))
   d$beschriftung <- factor(d$beschriftung, levels = rev(d$beschriftung))
   d$text <- paste0(sub(".", ",", sprintf(ifelse(d$panel == "Änderung durch die Korrektur", "%+.1f", "%.1f"),
                                          d$wert), fixed = TRUE), " %")

   ggplot2::ggplot(d, ggplot2::aes(x = wert, y = beschriftung,
                                   colour = art, shape = art)) +
      ggplot2::geom_vline(xintercept = 0, colour = "#888888", linewidth = 0.4) +
      ggplot2::geom_point(size = 3.2) +
      ggplot2::geom_text(ggplot2::aes(label = text),
                         hjust = ifelse(d$wert >= 0, -0.25, 1.25),
                         size = 3.1, show.legend = FALSE) +
      ggplot2::facet_grid(panel ~ ., scales = "free", space = "free_y") +
      ggplot2::scale_colour_manual(values = c(gemessen = "#0072B2",
                                              permutationsabhängig = "#D55E00"), name = NULL) +
      ggplot2::scale_shape_manual(values = c(gemessen = 16,
                                             permutationsabhängig = 17), name = NULL) +
      ggplot2::scale_x_continuous(labels = function(x) paste0(format(x, decimal.mark = ",", trim = TRUE), " %"),
                                  expand = ggplot2::expansion(mult = c(0.4, 0.3))) +
      ggplot2::labs(
         x = NULL, y = NULL,
         title = "Wirkung der belegten Fehler auf die Beispieldaten",
         subtitle = "Dreiecke: Wert hängt von der zufälligen Umordnung der Eingabe ab (Seed 42)",
         caption = "Quellen: nachpruefung/ergebnisse/wirkung.csv und f_f01_vignette.csv"
      ) +
      theme_aktuar() +
      ggplot2::theme(legend.position = "bottom",
                     strip.text.y = ggplot2::element_text(angle = 0, hjust = 0, face = "bold"))
}

grafik_testmatrix_kompakt <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   root <- standard_wurzel(root)
   r2 <- utils::read.csv(file.path(root, "gegenpruefung", "both_ways.csv"), stringsAsFactors = FALSE)
   r3 <- utils::read.csv(file.path(root, "nachpruefung", "ergebnisse", "both_ways_stichprobe.csv"),
                         stringsAsFactors = FALSE)
   vm <- utils::read.csv(file.path(root, "nachpruefung", "ergebnisse", "mutanten_verbesserungen.csv"),
                         stringsAsFactors = FALSE)
   zeile <- function(pruefung, lauf, ok, n) data.frame(pruefung = pruefung, lauf = lauf, ok = ok, n = n)
   d <- rbind(
      zeile("Runde 2: alle 30 Fehlertests", "Original sicr\nmuss bestehen", sum(r2$failed_original == 0), nrow(r2)),
      zeile("Runde 2: alle 30 Fehlertests", "Korrektur\nmuss anschlagen", sum(r2$failed_patch > 0), nrow(r2)),
      zeile("Runde 2: alle 30 Fehlertests", "Mutant\nmuss anschlagen", sum(r2$failed_mutant > 0), nrow(r2)),
      zeile("Runde 3: Stichprobe, eigene Mutanten", "Original sicr\nmuss bestehen", sum(r3$Lauf == "original" & r3$ok == "ja"), sum(r3$Lauf == "original")),
      zeile("Runde 3: Stichprobe, eigene Mutanten", "Korrektur\nmuss anschlagen", sum(r3$Lauf == "korrektur" & r3$ok == "ja"), sum(r3$Lauf == "korrektur")),
      zeile("Runde 3: Stichprobe, eigene Mutanten", "Mutant\nmuss anschlagen", sum(r3$Lauf == "mutant" & r3$ok == "ja"), sum(r3$Lauf == "mutant")),
      zeile("Runde 3: 12 Gleichheitstests", "Original sicr\nmuss bestehen", sum(vm$Test_original == "gruen"), nrow(vm)),
      zeile("Runde 3: 12 Gleichheitstests", "Mutant\nmuss anschlagen", sum(vm$Test_mutant == "rot"), nrow(vm))
   )
   laeufe <- c("Original sicr\nmuss bestehen", "Korrektur\nmuss anschlagen", "Mutant\nmuss anschlagen")
   d$lauf <- factor(d$lauf, laeufe)
   d$pruefung <- factor(d$pruefung, rev(unique(d$pruefung)))
   d$voll <- d$ok == d$n
   ggplot2::ggplot(d, ggplot2::aes(x = lauf, y = pruefung, fill = voll)) +
      ggplot2::geom_tile(colour = "white", linewidth = 1.5) +
      ggplot2::geom_text(ggplot2::aes(label = paste0(ok, " / ", n)), colour = "white",
                         size = 7, fontface = "bold") +
      ggplot2::scale_fill_manual(values = c("TRUE" = "#009E73", "FALSE" = "#D55E00"),
                                 labels = c("TRUE" = "alle wie erwartet", "FALSE" = "Abweichung"),
                                 drop = TRUE, name = NULL) +
      ggplot2::scale_x_discrete(position = "top") +
      ggplot2::labs(x = NULL, y = NULL,
                    title = "Jeder Test unterscheidet richtig von falsch",
                    caption = "Quellen: gegenpruefung/both_ways.csv;\nnachpruefung/ergebnisse/both_ways_stichprobe.csv, mutanten_verbesserungen.csv") +
      theme_aktuar(base_size = 14) +
      ggplot2::theme(panel.grid = ggplot2::element_blank(), legend.position = "none")
}

grafik_testmatrix <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   root <- standard_wurzel(root)
   r2 <- utils::read.csv(file.path(root, "gegenpruefung", "both_ways.csv"),
                         stringsAsFactors = FALSE, check.names = FALSE)
   r3 <- utils::read.csv(file.path(root, "nachpruefung", "ergebnisse",
                                   "both_ways_stichprobe.csv"),
                         stringsAsFactors = FALSE, check.names = FALSE)
   vm <- utils::read.csv(file.path(root, "nachpruefung", "ergebnisse",
                                   "mutanten_verbesserungen.csv"),
                         stringsAsFactors = FALSE, check.names = FALSE)

   ids <- unique(c(r2$id, vm$ID))
   spalten <- c("R2 Original", "R2 Korrektur", "R2 Mutant",
                "R3 Original", "R3 Korrektur", "R3 Mutant",
                "V Original", "V Mutant")
   d <- expand.grid(id = ids, spalte = spalten, KEEP.OUT.ATTRS = FALSE,
                    stringsAsFactors = FALSE)
   d$status <- "keine Daten"

   for (i in seq_len(nrow(d))) {
      id <- d$id[i]
      sp <- d$spalte[i]
      if (sp %in% c("R2 Original", "R2 Korrektur", "R2 Mutant")) {
         z <- r2[r2$id == id, , drop = FALSE]
         if (nrow(z)) {
            d$status[i] <- switch(
               sp,
               "R2 Original" = ifelse(z$failed_original[1] == 0, "grün", "rot"),
               "R2 Korrektur" = ifelse(z$failed_patch[1] > 0, "rot", "grün"),
               "R2 Mutant" = ifelse(z$failed_mutant[1] > 0, "rot", "grün")
            )
         }
      } else if (sp %in% c("R3 Original", "R3 Korrektur", "R3 Mutant")) {
         lauf <- sub("^R3 ", "", sp)
         z <- r3[r3$ID == id & r3$Lauf == tolower(lauf), , drop = FALSE]
         if (nrow(z)) {
            d$status[i] <- c(gruen = "grün", rot = "rot", fehler = "Abbruch")[[z$Ergebnis[1]]]
         }
      } else {
         z <- vm[vm$ID == id, , drop = FALSE]
         if (nrow(z)) {
            d$status[i] <- switch(
               sp,
               "V Original" = c(gruen = "grün", rot = "rot", fehler = "Abbruch")[[z$Test_original[1]]],
               "V Mutant" = c(gruen = "grün", rot = "rot", fehler = "Abbruch")[[z$Test_mutant[1]]]
            )
         }
      }
   }

   erwartet <- ifelse(grepl("Original$", d$spalte), "grün", "rot")
   d$bewertung <- factor(ifelse(d$status == "keine Daten", "nicht geprüft",
                                ifelse(d$status == erwartet, "wie erwartet", "nicht wie erwartet")),
                         c("wie erwartet", "nicht wie erwartet", "nicht geprüft"))
   d$text <- ifelse(d$status == "grün", "besteht", ifelse(d$status == "rot", "schlägt an", ifelse(d$status == "Abbruch", "Abbruch", "")))
   d$id <- factor(d$id, levels = rev(ids))
   d$spalte <- factor(d$spalte, levels = spalten,
                      labels = sub(" ", "\n", spalten))

   ggplot2::ggplot(d, ggplot2::aes(x = spalte, y = id, fill = bewertung)) +
      ggplot2::geom_tile(colour = "white", linewidth = 0.6, show.legend = TRUE) +
      ggplot2::geom_text(ggplot2::aes(label = text), colour = "white", size = 2.4) +
      ggplot2::scale_fill_manual(values = c("wie erwartet" = "#009E73",
                                            "nicht wie erwartet" = "#D55E00",
                                            "nicht geprüft" = "#EEEEEE"),
                                 drop = FALSE, name = NULL) +
      ggplot2::scale_x_discrete(position = "top") +
      ggplot2::labs(
         x = NULL, y = NULL,
         title = "Belastbarkeit der Tests: jeder Test unterscheidet richtig von falsch",
         subtitle = paste("Original: Test muss bestehen. Korrektur und Mutant: Test muss anschlagen.",
                          "R2 = Runde 2 (alle 30), R3 = Runde 3 (Stichprobe 10, eigene Mutanten),",
                          "V = Mutanten gegen die Gleichheitstests der 12 Verbesserungen", sep = "\n"),
         caption = "Quellen: gegenpruefung/both_ways.csv; nachpruefung/ergebnisse/both_ways_stichprobe.csv und mutanten_verbesserungen.csv"
      ) +
      theme_aktuar() +
      ggplot2::theme(
         axis.text.x.top = ggplot2::element_text(size = 9, lineheight = 0.9),
         panel.grid = ggplot2::element_blank(),
         legend.position = "bottom"
      )
}

grafik_benchmarks <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   root <- standard_wurzel(root)
   d <- utils::read.csv(
      file.path(root, "nachpruefung", "ergebnisse",
                "benchmarks_spanne_zusammenfassung.csv"),
      stringsAsFactors = FALSE, check.names = FALSE
   )
   d <- d[is.finite(d$Faktor_min) & is.finite(d$Faktor_max), , drop = FALSE]
   d$richtung <- ifelse(d$Faktor_median >= 1, "schneller", "langsamer")
   d$ID <- factor(d$ID, levels = d$ID[order(d$Faktor_median)])

   ggplot2::ggplot(d, ggplot2::aes(y = ID)) +
      ggplot2::geom_vline(xintercept = 1, linetype = "dashed", colour = "#777777") +
      ggplot2::geom_segment(
         ggplot2::aes(x = Faktor_min, xend = Faktor_max, y = ID, yend = ID,
                      colour = richtung),
         linewidth = 1.1
      ) +
      ggplot2::geom_point(ggplot2::aes(x = Faktor_median, colour = richtung),
                          size = 2.7) +
      ggplot2::geom_text(
         ggplot2::aes(x = Faktor_max, label = sprintf("%.1f–%.1f×", Faktor_min, Faktor_max)),
         hjust = -0.12, size = 3.1
      ) +
      ggplot2::scale_x_log10(expand = ggplot2::expansion(mult = c(0.08, 0.22))) +
      ggplot2::scale_colour_manual(values = pal_richtung, name = NULL) +
      ggplot2::labs(
         x = "Faktor original / verbessert (log; > 1 = schneller)", y = NULL,
         title = "Laufzeit der Verbesserungen: Spannen aus fünf Läufen",
         subtitle = "Punkt = Median, Strich = Minimum–Maximum; 1× = keine Änderung",
         caption = "Quelle: nachpruefung/ergebnisse/benchmarks_spanne_zusammenfassung.csv"
      ) +
      theme_aktuar() +
      ggplot2::theme(legend.position = "bottom")
}

grafik_runden <- function(root = Sys.getenv("AKTUAR_ROOT", ".")) {
   themen <- c("Anhang D", "E-F01", "F-F01", "Paper-Punkte", "Benchmarks")
   runden <- c("Runde 1\nAudit", "Runde 2\nGegenprüfung", "Runde 3\nNachprüfung")
   d <- data.frame(
      thema = rep(themen, each = 3),
      runde = rep(runden, times = 5),
      text = c(
         "46 Punkte als\nAnhang D", "kein Anhang D:\neigene Checkliste", "kein Anhang D\n(PDF selbst geprüft)",
         "kritisch", "hoch: 0,0 % im Beispiel;\nPrio. 500.000: −7 % XL", "hoch bestätigt;\nPrio. 500.000: −7 % XL, +3 % netto",
         "rund 16 %", "+9,1 % / +22,8 %\n(Jahre ohne Daten)", "+5,95 % im Backtesting\nder Vignette (2023)",
         "3 fehlen", "2 optional,\n1 Anwenderpflicht", "2 optional,\n1 kein Paperbezug",
         "Punktfaktoren", "3 Läufe:\nSpannen", "5 Läufe:\nSpannen"
      ),
      stringsAsFactors = FALSE
   )
   d$thema <- factor(d$thema, levels = rev(themen))
   d$runde <- factor(d$runde, levels = runden)

   ggplot2::ggplot(d, ggplot2::aes(x = runde, y = thema, fill = runde)) +
      ggplot2::geom_tile(colour = "white", linewidth = 1.2) +
      ggplot2::geom_text(ggplot2::aes(label = text), size = 3.1, lineheight = 0.9) +
      ggplot2::scale_fill_manual(values = c("#D6EAF3", "#FBE4C4", "#D5EFE6"),
                                 guide = "none") +
      ggplot2::labs(
         x = NULL, y = NULL,
         title = "Was die Prüfrunden geändert haben",
         subtitle = "Von der Auditfassung über die Gegenprüfung zum Endstand",
         caption = "Quellen: analyse/*.md, gegenpruefung/bericht.md, nachpruefung/bericht.md"
      ) +
      theme_aktuar() +
      ggplot2::theme(
         panel.grid = ggplot2::element_blank(),
         axis.text.x = ggplot2::element_text(face = "bold")
      )
}
