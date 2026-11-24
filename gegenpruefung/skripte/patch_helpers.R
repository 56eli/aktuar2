# Wendet die Korrekturen des Repos auf den sicr-Namensraum an (Gegenrichtung).
# Wrapper-Korrekturen, die die Originalfunktion aufrufen, werden auf die
# gespeicherte Originalfunktion umgebogen.
suppressPackageStartupMessages({ library(sicr) })

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

patch_fun <- function(name, fn) {
  ns <- asNamespace("sicr")
  unlockBinding(name, ns); assign(name, fn, envir = ns); lockBinding(name, ns)
  pe <- as.environment("package:sicr")
  if (exists(name, envir = pe, inherits = FALSE)) {
    unlockBinding(name, pe); assign(name, fn, envir = pe); lockBinding(name, pe)
  }
  invisible(TRUE)
}

# Liefert die Liste der gepatchten Originalnamen und lässt die Patches stehen.
# Die Originale werden als Attribut mitgegeben, restore_corrections() stellt sie zurück.
patch_corrections <- function(ids, root = Sys.getenv("AKTUAR_ROOT", ".")) {
  ns <- asNamespace("sicr")
  patched <- character()
  original <- list()
  for (kid in ids) {
    env <- new.env(parent = ns)
    sys.source(file.path(root, "verbesserungen", paste0(kid, ".R")), envir = env)
    for (n in ls(env)) {
      if (!endsWith(n, "_v")) next
      f <- get(n, envir = env)
      if (!is.function(f)) next
      orig <- sub("_v$", "", n)
      if (!exists(orig, envir = ns, inherits = FALSE)) next
      if (is.null(original[[orig]])) original[[orig]] <- get(orig, envir = ns)
      patch_fun(orig, reroute(f, orig))
      patched <- c(patched, orig)
    }
  }
  structure(unique(patched), original = original)
}

restore_corrections <- function(patched) {
  original <- attr(patched, "original")
  for (nm in names(original)) patch_fun(nm, original[[nm]])
  invisible(NULL)
}
