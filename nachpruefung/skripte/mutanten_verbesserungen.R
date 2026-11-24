# Mutanten gegen die Gleichheitstests der 12 Verbesserungen (V-IDs)
# Aufruf aus der Repo-Wurzel:
#   Rscript nachpruefung/skripte/mutanten_verbesserungen.R
# Zu jeder Verbesserung wird eine absichtlich falsche, aber plausible Variante
# der _v()-Funktion eingesetzt. Der Gleichheitstest muss dann rot werden.

root <- Sys.getenv("AKTUAR_ROOT", ".")
setwd(root)
suppressPackageStartupMessages({ library(testthat); library(sicr) })
Sys.setenv(AKTUAR_ROOT = normalizePath(root))
outdir <- file.path(root, "nachpruefung", "ergebnisse")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
tmpdir <- Sys.getenv("TMPDIR", file.path(root, ".scratch"))
dir.create(tmpdir, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------------------
# Mutanten: rufen die echte _v()-Funktion auf und veraendern deren Ergebnis
# mit einem kleinen, funktionsspezifischen Fehler.
# ---------------------------------------------------------------------------
mut_A_V01 <- function(pools) {
   res <- pools2dataframe_v(pools)
   # Off-by-one: die Nachlaufzeile bekommt ein Abwicklungsjahr zu viel.
   m <- max(res$Dev_year_since_large)
   res$Dev_year_since_large[res$Dev_year_since_large == m] <- m + 1L
   res
}

mut_A_V02 <- function(dev_year, reserve_class, start_of_tail,
                      number_of_reserve_classes, lengths_vector, output) {
   res <- get_matrix_info_v(dev_year, reserve_class, start_of_tail,
                            number_of_reserve_classes, lengths_vector, output)
   # Off-by-one in der Poolgroesse.
   if (output == "sample_size") res <- res + 1
   res
}

mut_B_V01 <- function(dev_year, start_of_tail, end_of_tail) {
   # Off-by-one: der Nenner des linearen Abschmelzens ist um eins zu klein.
   tail_length <- end_of_tail - start_of_tail
   pmax(0, pmin(1, (end_of_tail - dev_year + 1) / tail_length))
}

mut_B_V02 <- function(cal_year_triangle) {
   res <- cal_year2dev_year_v(cal_year_triangle)
   # Off-by-one: die Diagonale wird um eins verschoben.
   if (NROW(res) > 1L) {
      for (i in seq_len(NROW(res) - 1L)) {
         res[i, i] <- res[i + 1L, i]
      }
   }
   res
}

mut_C_V01 <- function(large_claims_list, first_orig_year, last_orig_year,
                      years_for_ibnr_pools) {
   res <- generate_ibnr_pools_v(large_claims_list, first_orig_year,
                                last_orig_year, years_for_ibnr_pools)
   # Eine Zeile wird am Anfang des ersten Pools vergessen.
   if (length(res) > 0L && length(res[[1]]) > 0L) res[[1]] <- res[[1]][-1L]
   res
}

mut_C_V02 <- function(expected_rounded_ibnr_numbers) {
   res <- ibnr_transform2dataframe_v(expected_rounded_ibnr_numbers)
   # Off-by-one im Abwicklungsjahr seit Grosswerden.
   if (NROW(res) > 0L) res$Dev_year_since_large <- res$Dev_year_since_large + 1L
   res
}

mut_D_V01 <- function(annuities, last_orig_year, indices = NULL,
                      future_annuities = FALSE) {
   res <- generate_annuity_payments_v(annuities, last_orig_year, indices,
                                      future_annuities)
   # Zahlungsstrom um eine Spalte nach links verschoben.
   if (!is.null(res) && NCOL(res) > 1L) {
      res <- cbind(res[, -1L, drop = FALSE], 0)
   }
   res
}

mut_D_V02 <- function(best_estimate, pattern, dev_year) {
   res <- rollout_best_estimate_v(best_estimate, pattern, dev_year)
   # Die erste Folgejahreszahlung wird um 1 erhoeht.
   res[, 1] <- res[, 1] + 1
   res
}

mut_E_V01 <- function(indices, first_orig_year, last_orig_year) {
   res <- indices_ok_v(indices, first_orig_year, last_orig_year)
   # Rueckgabewert invertiert.
   !res
}

mut_E_V02 <- function(exposure, first_orig_year, last_orig_year) {
   res <- exposure_ok_v(exposure, first_orig_year, last_orig_year)
   # Rueckgabewert invertiert.
   !res
}

mut_F_V01 <- function(pools, large_claims_list) {
   res <- plot_pools_overview_v(pools, large_claims_list)
   # Eine Beobachtung zu viel im ersten Plot.
   if (!is.null(res[[1]]$data$Observations)) {
      res[[1]]$data$Observations <- res[[1]]$data$Observations + 1
   }
   res
}

mut_F_V02 <- function(large_claims_list, sim_result) {
   res <- plot_reserve_vs_be_v(large_claims_list, sim_result)
   # Ein Wert im ersten Balkendiagramm wird verschoben.
   if (!is.null(res$plot_rc$data$Value)) {
      res$plot_rc$data$Value <- res$plot_rc$data$Value + 1
   }
   res
}

cfg <- data.frame(
   id = c("A-V01", "A-V02", "B-V01", "B-V02", "C-V01", "C-V02",
          "D-V01", "D-V02", "E-V01", "E-V02", "F-V01", "F-V02"),
   fun = c("pools2dataframe_v", "get_matrix_info_v", "tail_factor_v",
           "cal_year2dev_year_v", "generate_ibnr_pools_v",
           "ibnr_transform2dataframe_v", "generate_annuity_payments_v",
           "rollout_best_estimate_v", "indices_ok_v", "exposure_ok_v",
           "plot_pools_overview_v", "plot_reserve_vs_be_v"),
   mutant = c("mut_A_V01", "mut_A_V02", "mut_B_V01", "mut_B_V02",
              "mut_C_V01", "mut_C_V02", "mut_D_V01", "mut_D_V02",
              "mut_E_V01", "mut_E_V02", "mut_F_V01", "mut_F_V02"),
   mutation = c(
      "Nachlaufzeile bekommt ein Abwicklungsjahr zu viel",
      "Poolgroesse sample_size um eins zu gross",
      "Nenner des linearen Nachlaufs um eins zu klein",
      "Diagonale des Abwicklungsdreiecks verschoben",
      "erste Poolzeile vergessen",
      "Dev_year_since_large um eins zu gross",
      "Rentenzahlungen um eine Spalte verschoben",
      "erste Folgejahreszahlung um eins erhoeht",
      "Rueckgabe von indices_ok_v invertiert",
      "Rueckgabe von exposure_ok_v invertiert",
      "eine Beobachtung im ersten Poolplot zu viel",
      "ein Wert im ersten Reservenplot verschoben"
   ),
   stringsAsFactors = FALSE
)

run_test <- function(path) {
   r <- tryCatch(
      as.data.frame(testthat::test_file(path, reporter = "silent",
                                        stop_on_failure = FALSE)),
      error = function(e) data.frame(failed = 1L, error = 1L)
   )
   if (!NROW(r)) return(list(gruen = FALSE, text = "keine Testergebnisse"))
   f <- sum(r$failed, na.rm = TRUE)
   e <- sum(r$error, na.rm = TRUE)
   list(gruen = (f == 0 && e == 0),
        text = paste0(f, " failed, ", e, " error"))
}

zeilen <- list()
for (i in seq_len(NROW(cfg))) {
   id <- cfg$id[i]
   cat("Teste", id, "...\n")
   test_datei <- file.path(root, "tests", "verbesserungen",
                           paste0("test-", id, ".R"))
   if (!file.exists(test_datei)) {
      zeilen[[length(zeilen) + 1L]] <- data.frame(
         ID = id, Mutation = cfg$mutation[i], Test_original = "rot",
         Test_mutant = "rot", Urteil = "diskriminiert_nicht",
         stringsAsFactors = FALSE)
      next
   }

   # (1) unveraenderter Test
   orig <- run_test(test_datei)

   # (2) Test mit eingesetztem Mutanten
   mut_datei <- tempfile(pattern = paste0("mut_", id, "_"), tmpdir = tmpdir,
                         fileext = ".R")
   dump(cfg$mutant[i], file = mut_datei, envir = globalenv())
   prefix <- c(
      sprintf("source(%s)", encodeString(mut_datei, quote = "\"")),
      "source <- function(file, local = FALSE, ...) {",
      "   base::source(file, local = FALSE, ...)",
      "   .target <- parent.frame()",
      sprintf("   assign(%s, %s, envir = .target)",
              encodeString(cfg$fun[i], quote = "\""), cfg$mutant[i]),
      "   invisible(NULL)",
      "}"
   )
   test_mut <- tempfile(pattern = paste0("testmut_", id, "_"),
                        tmpdir = tmpdir, fileext = ".R")
   writeLines(c(prefix, readLines(test_datei, warn = FALSE)), test_mut)
   mut <- run_test(test_mut)

   test_orig_txt <- if (orig$gruen) "gruen" else "rot"
   test_mut_txt <- if (mut$gruen) "gruen" else "rot"
   urteil <- if (orig$gruen && !mut$gruen) "diskriminiert" else "diskriminiert_nicht"
   cat("  original:", test_orig_txt, "(", orig$text, ")  mutant:",
       test_mut_txt, "(", mut$text, ")\n")
   zeilen[[length(zeilen) + 1L]] <- data.frame(
      ID = id,
      Mutation = cfg$mutation[i],
      Test_original = test_orig_txt,
      Test_mutant = test_mut_txt,
      Urteil = urteil,
      stringsAsFactors = FALSE
   )
}

erg <- do.call(rbind, zeilen)
write.csv(erg, file.path(outdir, "mutanten_verbesserungen.csv"),
          row.names = FALSE, quote = FALSE)
cat("Geschrieben:", file.path(outdir, "mutanten_verbesserungen.csv"), "\n")
print(erg, row.names = FALSE)
