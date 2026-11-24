# Both-ways-Stichprobe: 10 Befunde in drei Laeufen
# Aufruf aus der Repo-Wurzel:
#   Rscript nachpruefung/skripte/both_ways_stichprobe.R
# (a) unveraendertes sicr: der Fehlertest muss gruen sein
# (b) Originalfunktion durch die _v()-Korrektur ersetzt: der Fehlertest muss rot werden
# (c) Originalfunktion durch einen eigenen, anderen Mutanten ersetzt: muss rot werden

root <- Sys.getenv("AKTUAR_ROOT", ".")
setwd(root)
suppressPackageStartupMessages({ library(testthat); library(sicr) })
Sys.setenv(AKTUAR_ROOT = normalizePath(root))
outdir <- file.path(root, "nachpruefung", "ergebnisse")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
tmpdir <- Sys.getenv("TMPDIR", file.path(root, ".scratch"))
dir.create(tmpdir, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------------------
# Eigene Mutanten (bewusst andere als die stop("MUTANT: ...")-Mutanten in
# gegenpruefung/logs/). Sie rufen die Originalfunktion auf und veraendern das
# Ergebnis mit einem kleinen, fachspezifischen Fehler.
# ---------------------------------------------------------------------------
mut_A_F01 <- function(...) {
   res <- sicr::generate_pools(...)
   # Off-by-one: jede Nachlaufzahlung wird um 1 verschoben.
   for (i in seq_along(res[[2]])) {
      res[[2]][[i]]$Ind_cl_payment_cal <- res[[2]][[i]]$Ind_cl_payment_cal + 1
   }
   res
}

mut_B_F01 <- function(historic_indices, first_orig_year, last_orig_year,
                      index_gross_future = 0, index_re_future = 0) {
   res <- sicr::expand_historic_indices(historic_indices, first_orig_year,
                                        last_orig_year, index_gross_future,
                                        index_re_future)
   # Historische Indizes werden zusaetzlich umgedreht.
   h <- res$Calendar_year <= last_orig_year
   res$Index_gross[h] <- rev(res$Index_gross[h])
   res
}

mut_C_F03 <- function(additive_ibnr_model, exposure) {
   res <- sicr::get_expected_ibnr_numbers(additive_ibnr_model, exposure)
   # Die Zeilenbeschriftungen werden vertauscht (Werte bleiben an ihrem Platz).
   if (NROW(res) > 1L) {
      rn <- rownames(res)
      rn[c(1L, length(rn))] <- rn[c(length(rn), 1L)]
      rownames(res) <- rn
   }
   res
}

mut_C_F05 <- function(...) {
   res <- sicr::get_additive_ibnr_model(...)
   # Ein Abwicklungsjahr zu wenig.
   if (NROW(res) > 1L) res <- res[-NROW(res), , drop = FALSE]
   res
}

mut_D_F01 <- function(annuities, mortality, age_shift) {
   # Technisches Alter um zwei Jahre zu hoch angesetzt.
   a <- annuities
   a$Calendar_year <- a$Calendar_year + 2L
   sicr::generate_annuity_probabilities(a, mortality, age_shift)
}

mut_D_F03 <- function(..., reinsurance = NULL) {
   args <- list(...)
   if (!is.null(reinsurance)) {
      # Quote wird spaltenweise gedreht.
      reinsurance$Quota_share <- rev(reinsurance$Quota_share)
   }
   do.call(sicr::compute_small_claims,
           c(args, list(reinsurance = reinsurance)))
}

mut_D_F07 <- function(small_claims_annuities_parameters_list,
                      small_claims_reserved, indices) {
   res <- sicr::generate_small_claims_future_annuities(
      small_claims_annuities_parameters_list, small_claims_reserved, indices)
   # Letzte Zukunftsspalte um 1 erhoeht.
   if (NCOL(res) > 0L) res[, NCOL(res)] <- res[, NCOL(res)] + 1
   res
}

mut_E_F01 <- function(...) {
   res <- sicr::aggregate_large_claims_results(...)
   # Jede XL-Zahlung um 1 zu hoch.
   res$large_ceded_xl_payments <- res$large_ceded_xl_payments + 1
   res
}

mut_E_F02 <- function(...) {
   args <- list(...)
   if (!is.null(args$reinsurance)) {
      args$reinsurance$Quota_share <- rev(args$reinsurance$Quota_share)
   }
   do.call(sicr::aggregate_large_claims_results, args)
}

mut_F_F01_rc <- function(sim_result_series_old, extended_claims_data_new) {
   g <- sicr::backtesting_1y_per_reserve_class(sim_result_series_old,
                                               extended_claims_data_new)
   # Ist-Werte verdoppelt.
   g$data$Value[g$data$Type == "Actual"] <-
      g$data$Value[g$data$Type == "Actual"] * 2
   g
}

mut_F_F01_oy <- function(sim_result_series_old, extended_claims_data_new) {
   g <- sicr::backtesting_1y_per_origin_year(sim_result_series_old,
                                             extended_claims_data_new)
   # Ist-Werte verdoppelt.
   g$data$Value[g$data$Type == "Actual"] <-
      g$data$Value[g$data$Type == "Actual"] * 2
   g
}

cfg <- data.frame(
   id = c("A-F01", "B-F01", "C-F03", "C-F05", "D-F01",
          "D-F03", "D-F07", "E-F01", "E-F02", "F-F01"),
   mutation = c(
      "Nachlaufzahlungen um 1 verschoben",
      "historische Indizes zusaetzlich umgedreht",
      "erste und letzte Exposure-Zeile vertauscht",
      "letztes Abwicklungsjahr des IBNR-Modells entfernt",
      "technisches Alter um zwei Jahre zu hoch",
      "Quoten spaltenweise gedreht",
      "letzte Zukunftsspalte um 1 erhoeht",
      "alle XL-Zahlungen um 1 erhoeht",
      "Quoten spaltenweise gedreht",
      "Ist-Werte im Backtesting verdoppelt"
   ),
   stringsAsFactors = FALSE
)

# Zuordnung ID -> zu ersetzende Originalfunktion(en) und Mutant(en)
patch_liste <- list(
   "A-F01" = list(c("generate_pools"), c("mut_A_F01")),
   "B-F01" = list(c("expand_historic_indices"), c("mut_B_F01")),
   "C-F03" = list(c("get_expected_ibnr_numbers"), c("mut_C_F03")),
   "C-F05" = list(c("get_additive_ibnr_model"), c("mut_C_F05")),
   "D-F01" = list(c("generate_annuity_probabilities"), c("mut_D_F01")),
   "D-F03" = list(c("compute_small_claims"), c("mut_D_F03")),
   "D-F07" = list(c("generate_small_claims_future_annuities"), c("mut_D_F07")),
   "E-F01" = list(c("aggregate_large_claims_results"), c("mut_E_F01")),
   "E-F02" = list(c("aggregate_large_claims_results"), c("mut_E_F02")),
   "F-F01" = list(c("backtesting_1y_per_reserve_class",
                    "backtesting_1y_per_origin_year"),
                  c("mut_F_F01_rc", "mut_F_F01_oy"))
)

run_test <- function(path) {
   r <- tryCatch(
      as.data.frame(testthat::test_file(path, reporter = "silent",
                                        stop_on_failure = FALSE)),
      error = function(e) data.frame(failed = 1L, error = 1L)
   )
   # "rot" heisst: eine Erwartung schlaegt an, ohne Abbruch. Ein Abbruch (error > 0 oder
   # keine Ergebnisse) ist "fehler" und zaehlt nie als erkannter Mutant.
   if (!NROW(r)) return(list(gruen = FALSE, status = "fehler", f = NA, e = NA,
                             text = "keine Testergebnisse"))
   f <- sum(r$failed, na.rm = TRUE)
   e <- sum(r$error, na.rm = TRUE)
   status <- if (e > 0) "fehler" else if (f > 0) "rot" else "gruen"
   list(gruen = (status == "gruen"), status = status, f = f, e = e,
        text = paste0(f, " failed, ", e, " error"))
}

prefix_korrektur <- function(id, funs) {
   c(
      ".local_env <- new.env(parent = globalenv())",
      sprintf("base::source(%s, local = .local_env)",
              encodeString(file.path(root, "verbesserungen", paste0(id, ".R")),
                           quote = "\"")),
      "for (.nm in ls(.local_env, pattern = \"_v$\")) {",
      "   assign(sub(\"_v$\", \"\", .nm), get(.nm, envir = .local_env),",
      "          envir = environment())",
      "}"
   )
}

prefix_mutant <- function(funs, muts) {
   vapply(seq_along(funs), function(i) {
      sprintf("assign(%s, get(%s, envir = globalenv()), envir = environment())",
              encodeString(funs[i], quote = "\""),
              encodeString(muts[i], quote = "\""))
   }, character(1))
}

zeilen <- list()
for (i in seq_len(NROW(cfg))) {
   id <- cfg$id[i]
   test_datei <- file.path(root, "befunde", paste0("test-", id, ".R"))
   funs <- patch_liste[[id]][[1]]
   muts <- patch_liste[[id]][[2]]
   cat("=== ", id, " ===\n")

   laeufe <- list(
      original = list(prefix = NULL, mutation = "", erwartet = "gruen"),
      korrektur = list(prefix = prefix_korrektur(id, funs), mutation = "",
                       erwartet = "rot"),
      mutant = list(prefix = prefix_mutant(funs, muts),
                    mutation = cfg$mutation[i], erwartet = "rot")
   )

   for (lauf in names(laeufe)) {
      info <- laeufe[[lauf]]
      datei <- test_datei
      if (!is.null(info$prefix)) {
         datei <- tempfile(pattern = paste0("bw_", id, "_", lauf, "_"),
                           tmpdir = tmpdir, fileext = ".R")
         writeLines(c(info$prefix, readLines(test_datei, warn = FALSE)), datei)
      }
      r <- run_test(datei)
      ergebnis <- r$status
      ok <- if (ergebnis == info$erwartet) "ja" else "nein"
      cat("  ", lauf, ": ", ergebnis, " (", r$text, "), erwartet ",
          info$erwartet, " -> ", ok, "\n", sep = "")
      zeilen[[length(zeilen) + 1L]] <- data.frame(
         ID = id,
         Lauf = lauf,
         Mutation = info$mutation,
         Ergebnis = ergebnis,
         erwartet = info$erwartet,
         ok = ok,
         failed = r$f,
         error = r$e,
         stringsAsFactors = FALSE
      )
   }
}

erg <- do.call(rbind, zeilen)
write.csv(erg, file.path(outdir, "both_ways_stichprobe.csv"),
          row.names = FALSE, quote = FALSE)
cat("Geschrieben:", file.path(outdir, "both_ways_stichprobe.csv"), "\n")
print(erg, row.names = FALSE)
