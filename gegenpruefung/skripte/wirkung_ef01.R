# Wirkung von E-F01 auf den Beispieldaten: XL-Anteil der IBNR-Spätgroßschäden in
# der Aggregation. Misst Brutto, Zediert-XL und Netto der Zukunftssummen.
# Aufruf: Rscript gegenpruefung/skripte/wirkung_ef01.R [n]
suppressPackageStartupMessages({ library(sicr) })
args <- commandArgs(trailingOnly = TRUE)
n <- if (length(args) >= 1) as.integer(args[1]) else 2L
prio <- if (length(args) >= 2) as.numeric(args[2]) else NA_real_
root <- Sys.getenv("AKTUAR_ROOT", normalizePath("."))
source(file.path(root, "gegenpruefung", "skripte", "patch_helpers.R"))
b <- readRDS(file.path(root, "gegenpruefung", "cache", "basis.rds"))
last <- b$last_orig_year

cat("sim start", format(Sys.time()), "\n")
re <- reinsurance_xmpl
if (!is.na(prio)) {
  # realistisches Programm mit niedrigerer Priorität, damit Spätgroßschäden XL auslösen
  re$Priority <- prio
  re$Limit <- 3 * prio
  re$Margin_type <- "SIC"
  re$Margin <- 0.2
}
set.seed(42)
sim <- sicr(n = n,
            large_claims_list = b$large_claims_list,
            first_orig_year = b$first_orig_year,
            last_orig_year = last,
            pools = b$pools,
            indices = b$indices,
            history = b$history,
            exposure = exposure_xmpl,
            years_for_ibnr_pools = 2014:2023,
            active_annuities = active_annuities_xmpl,
            age_shift = age_shift_xmpl,
            mortality = mortality_xmpl,
            reinsurance = re,
            progress = FALSE,
            summary = FALSE)
cat("sim fertig", format(Sys.time()), "\n")

agg <- function() aggregate_large_claims_results(
  sim_result = sim,
  large_claims_list = b$large_claims_list,
  large_extended_claims_data = b$extended_claims_data,
  history = b$history,
  reinsurance = re,
  indices = b$indices,
  first_orig_year = b$first_orig_year,
  last_orig_year = last)

zukunft <- function(m) {
  jahre <- suppressWarnings(as.integer(colnames(m)))
  m[, jahre > last, drop = FALSE]
}
summe <- function(x) sum(as.numeric(x))

a0 <- agg()
patch_corrections("E-F01")
a1 <- agg()

brutto0 <- summe(zukunft(a0$large_claims_payments)) + summe(zukunft(a0$large_known_annuities_payments)) +
  summe(zukunft(a0$large_future_annuities_payments)) + summe(zukunft(a0$large_ibnr_payments))
brutto1 <- summe(zukunft(a1$large_claims_payments)) + summe(zukunft(a1$large_known_annuities_payments)) +
  summe(zukunft(a1$large_future_annuities_payments)) + summe(zukunft(a1$large_ibnr_payments))
xl0 <- summe(zukunft(a0$large_ceded_xl_payments))
xl1 <- summe(zukunft(a1$large_ceded_xl_payments))
q0 <- summe(zukunft(a0$large_ceded_quota_payments))
q1 <- summe(zukunft(a1$large_ceded_quota_payments))
netto0 <- brutto0 - xl0 - q0
netto1 <- brutto1 - xl1 - q1

cat("IBNR XL im Simulationsergebnis:", sum(sim[(nrow(b$large_claims_list)+1):nrow(sim), , 6]), "\n")
cat(sprintf("Prioritaet=%s Limit=%s\n", format(prio), format(if (is.na(prio)) NA else 3*prio)))
cat(sprintf("n=%d IBNR-Zeilen: %d von %d\n", n, nrow(sim) - nrow(b$large_claims_list), nrow(sim)))
cat(sprintf("E-F01 Brutto Zukunft: original %.0f, korrigiert %.0f\n", brutto0, brutto1))
cat(sprintf("E-F01 Ceded XL:       original %.0f, korrigiert %.0f, Abweichung %+.2f %%\n",
            xl0, xl1, 100 * (xl0 / xl1 - 1)))
cat(sprintf("E-F01 Ceded Quota:    original %.0f, korrigiert %.0f, Abweichung %+.2f %%\n",
            q0, q1, 100 * (q0 / q1 - 1)))
cat(sprintf("E-F01 Netto Zukunft:  original %.0f, korrigiert %.0f, Abweichung %+.2f %%\n",
            netto0, netto1, 100 * (netto0 / netto1 - 1)))
cat(sprintf("E-F01 Netto/Anteil:   original %.4f %%, korrigiert %.4f %%\n",
            100 * netto0 / brutto0, 100 * netto1 / brutto1))
