# Both-ways-Prüfung eines Befunds: patcht die Originalfunktion in sicr durch die
# Korrektur _v() (Gegenrichtung) bzw. durch einen offensichtlich falschen Mutanten
# (Sensitivität) und führt die Befunddatei aus.
# Aufruf: Rscript gegenpruefung/skripte/both_ways.R <ID> orig|patch|mutant [Korrekturdateien]
#   Korrekturdateien: Komma-Liste von IDs unter verbesserungen/ (Standard: die ID selbst),
#   z. B. A-F01,A-F02 wenn eine Korrektur auf zwei Dateien verteilt ist.
#
# Korrekturdateien, deren _v() die Originalfunktion aufruft (Wrapper), werden so
# umgebogen, dass der Aufruf auf die gespeicherte Originalfunktion zeigt; sonst
# riefe die gepatchte Funktion sich selbst auf. Das ist die Gegenrichtung, die der
# Korrekturvorschlag selbst beschreibt, keine unabhängige Neuimplementierung.
suppressPackageStartupMessages({ library(testthat); library(sicr) })

args <- commandArgs(trailingOnly = TRUE)
id <- args[1]
mode <- args[2]
stopifnot(length(args) >= 2, mode %in% c("orig", "patch", "mutant"))
korr_ids <- if (length(args) >= 3 && nzchar(args[3])) strsplit(args[3], ",")[[1]] else id

root <- Sys.getenv("AKTUAR_ROOT", normalizePath("."))
tf <- file.path(root, "befunde", paste0("test-", id, ".R"))

blocks <- local({
  e <- parse(tf, keep.source = FALSE)
  out <- lapply(Filter(function(x) is.call(x) && identical(x[[1]], as.name("test_that")), e),
                function(ex) {
                  desc <- tryCatch(eval(ex[[2]]), error = function(e) NA_character_)
                  body <- paste(deparse(ex[[3]]), collapse = " ")
                  data.frame(desc = as.character(desc)[1], korrektur = grepl("_v\\s*\\(", body))
                })
  do.call(rbind, out)
})

# Aufruf der Originalfunktion in einem Wrapper auf die gespeicherte Kopie umbiegen
reroute <- function(f, name) {
  # Textumbau: Aufrufe der eigenen Originalfunktion zeigen auf die gespeicherte Kopie.
  # (AST-Umbau scheitert an Aufrufen mit fehlenden Argumenten wie `x[1, ] <- ...`.)
  neu <- paste0(".orig_", name)
  txt <- paste(deparse(body(f), width.cutoff = 500L), collapse = "\n")
  txt <- gsub(paste0("sicr:::{0,3}", name), neu, txt)
  txt <- gsub(paste0("(^|[^A-Za-z0-9_.])", name, "\\s*\\("), paste0("\\1", neu, "("), txt)
  body(f) <- parse(text = txt)[[1]]
  penv <- new.env(parent = environment(f))
  assign(neu, get(name, envir = asNamespace("sicr")), envir = penv)
  environment(f) <- penv
  f
}

patch_names <- character()
patch_fun <- function(name, fn) {
  ns <- asNamespace("sicr")
  if (!exists(name, envir = ns, inherits = FALSE)) {
    message("keine Originalfunktion im Namensraum: ", name)
    return(invisible(FALSE))
  }
  unlockBinding(name, ns); assign(name, fn, envir = ns); lockBinding(name, ns)
  pe <- as.environment("package:sicr")
  if (exists(name, envir = pe, inherits = FALSE)) {
    unlockBinding(name, pe); assign(name, fn, envir = pe); lockBinding(name, pe)
  }
  invisible(TRUE)
}

# A-F03: der Fehler steht in sicr() selbst, die Korrektur ist eine Hilfsfunktion.
# Gegenrichtung: Hilfsfunktion in den Namensraum legen und die Zeile in sicr() ersetzen.
patch_sicr_inline <- function(mutant = FALSE) {
  ns <- asNamespace("sicr")
  s <- get("sicr", ns)
  txt <- paste(deparse(body(s)), collapse = "\n")
  alt <- "tail(indices$Transition_factor, 250)"
  if (!grepl(alt, txt, fixed = TRUE)) stop("A-F03: erwartete Zeile nicht gefunden")
  neu <- if (mutant) "1" else "indices$Transition_factor[match(last_orig_year + year, indices$Calendar_year)]"
  txt <- gsub(alt, neu, txt, fixed = TRUE)
  body(s) <- parse(text = txt)[[1]]
  patch_fun("sicr", s)
}

if (mode != "orig") {
  if (id == "A-F03") {
    patch_sicr_inline(mutant = identical(mode, "mutant"))
    patch_names <- "sicr"
  } else {
    for (kid in korr_ids) {
      env <- new.env(parent = asNamespace("sicr"))
      sys.source(file.path(root, "verbesserungen", paste0(kid, ".R")), envir = env)
      for (n in ls(env)) {
        if (!endsWith(n, "_v")) next
        f <- get(n, envir = env)
        if (!is.function(f)) next
        orig <- sub("_v$", "", n)
        f <- reroute(f, orig)
        if (mode == "mutant") f <- local({ nm <- orig; function(...) stop("MUTANT: ", nm, call. = FALSE) })
        if (patch_fun(orig, f)) patch_names <- c(patch_names, orig)
      }
    }
  }
}

logdir <- file.path(root, "gegenpruefung", "logs")
dir.create(logdir, showWarnings = FALSE)
txt <- capture.output(
  res <- tryCatch(
    as.data.frame(test_file(tf, reporter = SummaryReporter$new(max_reports = 100),
                            stop_on_failure = FALSE)),
    error = function(e) {
      cat("DATEIFEHLER:", conditionMessage(e), "\n")
      data.frame(test = "<Dateifehler>", failed = NA_integer_, skipped = NA_integer_,
                 error = TRUE, real = NA_real_)
    }))
writeLines(c(sprintf("## %s %s gepatcht=%s", id, mode, paste(patch_names, collapse = "+")), txt),
           file.path(logdir, sprintf("%s_%s.log", id, mode)))

if (!nrow(res)) res <- data.frame(test = "<keine Blöcke>", failed = 0L, skipped = 0L, error = FALSE)
typ <- blocks$korrektur[match(res$test, blocks$desc)]
out <- data.frame(
  id = id, modus = mode,
  test = res$test,
  korrektur = ifelse(is.na(typ), NA, typ),
  failed = as.integer(res$failed),
  error = as.logical(res$error),
  skipped = as.integer(res$skipped),
  gepatcht = paste(patch_names, collapse = "+"),
  stringsAsFactors = FALSE)

con <- file.path(root, "gegenpruefung", "both_ways_roh.csv")
neu <- !file.exists(con)
write.table(out, con, sep = ",", row.names = FALSE, col.names = neu, append = !neu, qmethod = "double")
cat(sprintf("%s %s: %d Blöcke, %d mit Fehlern\n", id, mode, nrow(out), sum(out$failed > 0 | out$error)))
