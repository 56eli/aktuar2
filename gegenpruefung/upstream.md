# Befunde zu sicr 1.1.1 — Gegenprüfung des Audits

Gegenstand: **sicr 1.1.1**, Commit `c0ad2ade80dad83b1d6faec1bd4e34bd20233c92` (Stand 2026-11-24:
`refs/heads/main` unverändert, 0 offene Issues, 0 Pull Requests; `packageVersion()` im Prüf-Image 1.1.1).
Jeder Block läuft gegen **unverändertes sicr** und braucht nur `library(sicr)` und Base R.

Geprüft habe ich die Befunde nicht durch Lesen, sondern durch Rechnen: für jeden der 30 Fehler ist die
Gegenrichtung hergestellt (Originalfunktion durch die vorgeschlagene Korrektur gepatcht; der Befundtest
wird rot), zusätzlich durch einen offensichtlich falschen Mutanten (der Test wird ebenfalls rot). Der
Test `gegenpruefung/skripte/both_ways.R` und die Tabelle `gegenpruefung/both_ways.csv` zeigen das je ID.
Alle 30 Tests unterscheiden also. Die Zahlen unten stammen aus `gegenpruefung/skripte/wirkung.R` und
`wirkung_ef01.R` auf den Beispieldaten des Pakets.

Zwei Dinge vorweg, die die Gewichte verschieben:

- **E-F01 ist nicht kritisch.** Der XL-Anteil der Spätgroßschäden fehlt im Aggregat, das ist richtig;
  auf den Beispieldaten des Pakets ändert die Korrektur aber **0,0 %** der Reserve, weil dort kein
  IBNR-Schaden die Priorität (1,0–1,5 Mio.) übersteigt. Mit einer Priorität von 500.000 ändert sie
  das zedierte XL um −7,07 % und die Nettoreserve um +2,85 %. Das ist „hoch“, nicht „kritisch“.
- **Drei „fehlende Paper-Punkte“ sind keine Paketanforderungen.** Der Ergebnisbericht hat keinen
  Anhang D; die 46 Punkte sind die Gliederung des Prüfers. Die drei als „fehlt“ geführten Punkte
  (Großschadengrenze unter der Priorität, Ultimate-Backtesting, Ergebnisdokumentation) sind eine
  Empfehlung („sollte“, S. 11), eine Anwendung der UAG (Kap. 3) und eine Pflicht des Anwenders. Sie
  stehen deshalb unten unter „optional“, nicht als Lücke.

Schweregrade: kritisch = Reserve im Normalfall falsch · hoch = falsch in realistischen Datenlagen ·
mittel = Randfall oder Absturz · niedrig = Stil, Doku. Ich habe einen Schweregrad geändert (E-F01).

---

## A) Rechenfehler mit Reservenwirkung

### A-F01 — Ausreißergrenzen im Nachlauf wirken auf dem falschen Niveau

**Symptom.** Bei gesetzten Grenzen werden die Nachlaufzahlungen zuerst auf das Niveau des ersten
Nachlaufjahres hochskaliert und erst danach gekappt. Die Doku definiert die Grenzen auf
`index_year`-Niveau; die wirksame Grenze ist damit um den Tail-Faktor zu streng.

**Reproduktion**
```r
library(sicr)
d <- data.frame(Ind_cl_payment_cal = c(1000, -1000), Exit_reserve_class = 0L,
                New_annuity_1 = 0, New_annuity_2 = 0, New_annuity_3 = 0,
                New_annuity_4 = 0, New_annuity_5 = 0, Dev_year_since_large = 50L,
                Entry_reserve_class = 0L, Calendar_year = 2020L, Ind_entry_cl_reserve = 0)
attr(d, "threshold") <- 400000; attr(d, "index_year") <- 2020
p <- generate_pools(d, c(1), 2020L, 17, 50, -500, 1000, NULL)
p[[2]][[1]]$Ind_cl_payment_cal     # 1000 -500, erwartet 34000 -17000
```
**Datei:** `R/generate_pools.R:129-139` (Hochskalierung in Z. 129, Grenzen in Z. 137).
**Wirkung.** Auf den Beispielpools sinkt die Nachlaufpoolmasse um 4,95 % (Grenzen 0/100.000),
3,82 % (0/250.000) bzw. 2,90 % (0/500.000); ohne Grenzen 0,00 %. Die Reserve folgt der Poolmasse.
**Vorschlag.** Grenzen vor der Division anwenden:
```r
class_pool$Ind_cl_payment_cal <- pmax(lower, pmin(upper, class_pool$Ind_cl_payment_cal))
class_pool$Ind_cl_payment_cal <- class_pool$Ind_cl_payment_cal /
   tail_factor(class_pool$Dev_year_since_large, start_of_tail, end_of_tail)
```
**Test.** `sicr()` mit Grenzen liefert heute 1000/−500; nach der Korrektur 34000/−17000 — der
bestehende Test A-F01 ist vorher grün, nachher rot (both-ways gemessen).

### B-F01 — Historische Indizes werden nach Zeilenposition zugeordnet

**Symptom.** `expand_historic_indices()` baut die Jahresfolge `min:max+250`, hängt die Indexwerte aber
in Zeilenreihenfolge an. Eine unsortierte Indexreihe wird still falsch zugeordnet; Lücken erzeugen
einen unverständlichen Fehler.

**Reproduktion**
```r
library(sicr)
h <- data.frame(Calendar_year = c(2021, 2020, 2022), Index_gross = c(0.02, 0.05, 0.03))
e <- expand_historic_indices(h, 2020, 2022, 0.03, 0.02)
e$Index_gross[e$Calendar_year %in% c(2020, 2021)]   # 0.02 0.05, erwartet 0.05 0.02
```
**Datei:** `R/data_functions.R:47-49`.
**Wirkung.** Mit permutierter Beispielreihe sind 19,7 % der Jahre falsch, die größte Abweichung im
Übergangsfaktor 26,2 %; die korrigierte Fassung weicht 0,0 % ab, also exakt.
**Vorschlag.** Nach `Calendar_year` sortieren, Lücken prüfen und dann die 250 Zukunftswerte anhängen;
`match()` statt Zeilenposition.
**Test.** Die Beträge für 2020/2021 sind vorher 0.02/0.05, nachher 0.05/0.02.

### C-F03 — Exposure wird nach Zeilenposition statt nach Anfalljahr zugeordnet

**Symptom.** `get_expected_ibnr_numbers()` dreht `exposure$Exposure` um und setzt die Zeilennamen aus
`exposure$Origin_year`. Eine unsortierte Exposure-Tabelle verschiebt die erwarteten IBNR-Zahlen auf
die falschen Anfalljahre.

**Reproduktion**
```r
library(sicr)
m <- data.frame(Dev_year = 1:4, Ibnr_numbers = c(10L, 5L, 2L, 1L),
                Sum_of_exposures = rep(400L, 4), Factor = c(.025, .0125, .005, .0025))
s <- data.frame(Origin_year = 2020:2023, Exposure = c(1000, 1200, 1500, 1900))
get_expected_ibnr_numbers(m, s)["2023", ]    # 23.75 9.50 4.75
get_expected_ibnr_numbers(m, s[4:1, ])["2023", ]  # 0 0 0
```
**Datei:** `R/ibnr.R:104-118`.
**Wirkung.** Auf den Beispieldaten 35 statt 43 erwartete Spätgroßschäden (−18,6 %), 30 von 910
Anfalljahren falsch belegt.
**Vorschlag.** Exposure über `match(orig_years, exposure$Origin_year)` ziehen, nicht über die
Zeilennummer; Matrix wie bisher aufbauen.
**Test.** Beide Aufrufe müssen dasselbe liefern.

### D-F03 — Quota-Share folgt der Zeilenposition des RV-Datensatzes

**Symptom.** `compute_small_claims()` multipliziert die Zahlungsmatrix mit
`reinsurance$Quota_share[reinsurance$Origin_year %in% first:last]`. `%in%` behält die Reihenfolge des
RV-Dataframes; ein unsortierter Datensatz ordnet die Quote dem falschen Anfalljahr zu.

**Reproduktion**
```r
library(sicr)
dimn <- list(as.character(2020:2022), as.character(2020:2022))
paid <- matrix(c(100, 0, 0, 110, 120, 0, 130, 140, 150), 3, dimnames = dimn)
z <- matrix(0, 3, 3, dimnames = dimn)
res <- list(large_claims_payments = z, large_claims_reserved = z,
            large_known_annuities_payments = z, large_annuities_reserved = z)
sp <- list(special_claims_payments = z, special_claims_reserved = z,
           special_annuities_payments = z, special_annuities_reserved = z)
idx <- data.frame(Calendar_year = 2015:2030, Transition_factor = 1); attr(idx, "index_year") <- 2022L
re <- data.frame(Origin_year = c(2022L, 2021L, 2020L), Quota_share = c(0.3, 0.2, 0.1))
r <- compute_small_claims(2020L, 2022L, idx, paid, z,
                          large_claims_list = data.frame(Claim_id = character(0), Large_since = integer(0)),
                          large_claims_results = res, special_claims = data.frame(Claim_id = character(0)),
                          special_claims_results = sp, reinsurance = re)
gross <- r$small_claims_payments + r$small_known_annuities_payments + r$small_future_annuities_payments
m <- which(gross != 0)
unique(round(r$small_ceded_quota_payments[m] / gross[m], 2))
# 0.3 0.2 0.1 in Zeilenreihenfolge, erwartet 0.1 0.2 0.3
```
**Datei:** `R/small_claims.R:613`.
**Wirkung.** Auf der Beispiel-RV (`reinsurance_xmpl`) erhalten 19 von 35 Anfalljahren eine falsche
Quote, maximal 50 Prozentpunkte; die Jahressumme bleibt nur zufällig gleich. Die Messung ist für D-F03
und E-F02 dieselbe, weil beide Funktionen dieselbe Zuordnung benutzen (`%in%` statt `match`);
`gegenpruefung/wirkung_roh.txt`, Zeile „D-F03/E-F02“.
**Vorschlag.** `reinsurance$Quota_share[match(first:last, reinsurance$Origin_year)]`, fehlende Jahre
abbrechen (so macht es auch `xl_cashflow()`, `R/reinsurance.R:296`).
**Test.** Quoten 0,1/0,2/0,3 statt 0,3/0,2/0,1.

### D-F07 — Künftige Basisrenten hängen vom gewählten Indexjahr ab

**Symptom.** Die additiven Faktoren stammen aus Reserven, die auf `index_year` indexiert sind; die
Anwendung indexiert die Anzahl noch einmal von `index_year` in das Zukunftsjahr. Übrig bleibt ein
Faktor `I(Anfalljahr)/I(Indexjahr)`.

**Reproduktion**
```r
library(sicr)
pool <- data.frame(Claim_id = c("C1", "C2", "C1"), Annuity_id = c("A1", "A2", "A3"),
                   Origin_year = c(2020L, 2021L, 2020L), Calendar_year = c(2020L, 2021L, 2021L),
                   Entering_year = c(2020L, 2021L, 2021L), Annuity_start = c(2020L, 2021L, 2021L),
                   Annuity_end = c(2022L, 2023L, 2023L), Birth_year = c(1970L, 1971L, 1970L),
                   Gender = c("m", "f", "m"), Annual_payment = c(1000, 1000, 2000), Dynamic = 0)
res <- matrix(0, 2, 2, dimnames = list(c("2020", "2021"), c("2020", "2021")))
res[1, 1] <- 10000; res[2, 2] <- 10000
mort <- data.frame(Gender = rep(c("m", "f"), each = 122), Age = rep(0:121, 2), Probability = 0)
sh <- data.frame(Gender = c("m", "m", "f", "f"), Birth_year = c(1970L, 1971L, 1970L, 1971L),
                 Age_shift = 0L)
mk_idx <- function(iy) {
  i <- data.frame(Calendar_year = 2015:2275, Index_gross = 0.02, Index_re = 0)
  k <- cumprod(1 + i$Index_gross); i$Transition_factor <- k / k[i$Calendar_year == iy]
  attr(i, "index_year") <- iy; i
}
lauf <- function(iy) {
  par <- generate_small_claims_annuities_parameters(
    pool, data.frame(Claim_id = character(0), Large_since = integer(0)),
    data.frame(Claim_id = character(0)), mk_idx(iy), res, sh, mort)
  sum(generate_small_claims_future_annuities(par, res, mk_idx(iy)))
}
round(c(lauf(2022), lauf(2018)))   # 3941 4266 - derselbe Bestand, -7.6 %
```
**Datei:** `R/small_claims_future_annuities.R:311-315`.
**Wirkung.** Auf den Beispieldaten −10,6 % bei vier Jahren Indexjahrabstand, im Mini-Beispiel −7,6 %;
mit der Korrektur exakt 0,0 %.
**Vorschlag.** Zeilenweise vom eigenen Anfalljahr in das Zukunftsjahr indexieren (`apply_index(...,
origin_year[row], new_year, indices)`), wie in `verbesserungen/D-F07.R`.
**Test.** Zwei Indexjahre müssen dasselbe Ergebnis liefern.

### E-F01 — XL-Anteil der Spätgroßschäden fehlt in der Aggregation  *(Schwere: hoch, nicht kritisch)*

**Symptom.** `sicr()` schreibt den XL-Anteil auch für die IBNR-Zeilen (`R/sicr.R:591-592`);
`aggregate_large_claims_results()` übernimmt für das XL-Dreieck nur die bekannten Schäden
(`ind_known_claims`), für die Quote dagegen alle Zeilen. Netto ist zu hoch.

**Reproduktion**
```r
library(sicr)
sim <- array(0, dim = c(2, 250, 15), dimnames = list(c("C1", "IBNR1"),
              as.character(2024:2273), paste0("S", 1:15)))
sim[2, 1, 1] <- 1000; sim[2, 1, 6] <- 400        # IBNR: brutto 1000, XL 400
attr(sim, "ibnr_list") <- data.frame(Origin_year = 2023L, Dev_year_of_growing_large = 1L)
a <- aggregate_large_claims_results(sim,
       data.frame(Claim_id = "C1", Origin_year = 2023L),
       data.frame(Claim_id = "C1", Origin_year = 2023L, Calendar_year = 2023L,
                  Dev_year_since_large = 1L, Cl_payment_cal = 0, Cl_reserve = 0,
                  An_payment_cal = 0, An_reserve = 0),
       matrix(0, 1, 1), NULL, data.frame(Calendar_year = 2023L), 2023L, 2023L)
sum(a$large_ceded_xl_payments)   # 0, erwartet 400
```
**Datei:** `R/aggregate_large_claims_results.R:157-163` (IBNR nur Spalte 1) und `:181` (XL nur
`ind_known_claims`).
**Wirkung.** Auf den Beispieldaten mit dem mitgelieferten RV-Programm (Priorität 1,0–1,5 Mio.)
**0,0 %**: kein IBNR-Schaden übersteigt die Priorität. Mit Priorität 500.000: zediertes XL −7,07 %,
Nettoreserve +2,85 % (1,76 Mio. von 61,7 Mio.). Die Wirkung ist also programmabhängig; das ist der
Grund, „kritisch“ auf „hoch“ zu setzen.
**Vorschlag.** Im XL-Zweig die IBNR-Zeilen mitnehmen:
```r
large_ceded_xl_prediction[ind_ibnr, ] <- convert_single2dev_year_prediction(
   cashflow = sim_result[ind_ibnr, , 6], claims_orig_years = ibnr_list$Origin_year, ...)
```
**Test.** Mini-Fall vorher 0, nachher 400; auf den Beispieldaten bleibt die Reserve unverändert.

### E-F02 — Quotenabgabe im Aggregat über die Zeilenposition

**Symptom.** Dieselbe Ursache wie D-F03, eine Ebene höher:
`reinsurance$Quota_share[reinsurance$Origin_year %in% first:last]` (`R/aggregate_large_claims_results.R:194`).

**Reproduktion**
```r
library(sicr)
sim <- array(0, dim = c(2L, 250L, 7L))
attr(sim, "ibnr_list") <- data.frame(Origin_year = integer(0), Dev_year_of_growing_large = integer(0))
sim[1, 1, 3] <- 100; sim[2, 1, 3] <- 200          # 2020: 100, 2021: 200, Zahlung 2022
lcl <- data.frame(Claim_id = c("C1", "C2"), Origin_year = c(2020L, 2021L))
ed <- data.frame(Claim_id = c("C1", "C2"), Origin_year = c(2020L, 2021L),
                 Calendar_year = c(2020L, 2021L), Dev_year_since_large = c(1L, 1L),
                 Cl_payment_cal = c(10, 20), Cl_reserve = c(100, 200),
                 An_payment_cal = 0, An_reserve = 0)
h <- matrix(c(10, 0, 0, 20), 2, dimnames = list(c("C1", "C2"), c("2020", "2021")))
re <- data.frame(Origin_year = c(2021L, 2020L), Priority = 0, Limit = 1e9, Base_year = 0L,
                 Margin_type = "none", Margin = 0, Quota_share = c(0.5, 0.1))
idx <- data.frame(Calendar_year = 2020:2271, Index_gross = 0, Index_re = 0)
attr(idx, "index_year") <- 2021
a <- suppressWarnings(aggregate_large_claims_results(sim, lcl, ed, h, re, idx, 2020L, 2021L))
a$large_ceded_quota_payments["2020", "2022"]   # 50, erwartet 10
a$large_ceded_quota_payments["2021", "2022"]   # 20, erwartet 100
```
**Datei:** `R/aggregate_large_claims_results.R:190-194`.
**Wirkung.** Dieselbe Zuordnung wie D-F03 (gemeinsame Messung, `wirkung_roh.txt`, Zeile
„D-F03/E-F02“): 19 von 35 Anfalljahren falsch, bis 50 Prozentpunkte; die Jahressumme kann gleich
bleiben.
**Vorschlag.** `match(first:last, reinsurance$Origin_year)`; fehlende Jahre abbrechen.
**Test.** 10/100 statt 50/20.

### F-F01 — Backtesting vergleicht nominale Prognose mit deflationiertem Ist-Wert

**Symptom.** Die Simulation liefert nominale Zahlungen; der Ist-Wert ist `Ind_cl_payment_cal`, also
auf das Indexjahr deflationiert. Die Prognose erscheint systematisch zu hoch.

**Reproduktion**
```r
library(sicr)
i <- add_transition_factor(expand_historic_indices(historic_indices_xmpl, 1989, 2023, 0.03, 0.02), 2022)
tf <- function(j) i$Transition_factor[match(j, i$Calendar_year)]
tf(c(2024, 2028))    # 1.0912 1.2282 -> +9,1 % bzw. +22,8 %
```
**Datei:** `R/plots.R:1239, 1466` (Ist-Wert) gegen `R/sicr.R:451` (nominale Prognose).
**Wirkung.** Die Verzerrung ist genau der Übergangsfaktor des Ist-Jahres. Auf den Beispieldaten
+9,1 % im ersten Folgejahr, +22,8 % nach fünf Jahren. Die im Audit genannten „~16 %“ treffen die
Beispieldaten nicht; sie gelten nur bei fünf Jahren Abstand und 3 % Inflation.
**Vorschlag.** Ist-Wert nominal vergleichen (`Cl_payment_cal` statt `Ind_cl_payment_cal`) oder die
Prognose auf das Indexjahr deflationieren — beides konsistent, nicht gemischt.
**Test.** Bei Indexjahr = Ist-Jahr muss die Abweichung 0 sein.

### C-F04 — Indexklausel ist ein Jahr zu früh verankert

**Symptom.** `cumprod((1 + Index_re)[B:N])` beginnt im Basisjahr B, im Basisjahr ist der Faktor damit
`1 + Index_re[B]` statt 1.

**Reproduktion**
```r
library(sicr)
re <- data.frame(Origin_year = 2014:2016, Priority = c(0, 1e5, 0), Limit = c(0, 1e6, 0),
                 Base_year = c(0L, 2015L, 0L), Margin_type = c("none", "FIC", "none"),
                 Margin = c(0, 0, 0), Quota_share = c(0, 0, 0))
mk_idx <- function(shock) {                # 20 % Schub in genau einem Kalenderjahr
  i <- data.frame(Calendar_year = 2014:2266, Index_gross = 0, Index_re = 0, Transition_factor = 1)
  i$Index_re[i$Calendar_year == shock] <- 0.2; i
}
h <- matrix(0, 1, 3, dimnames = list("C1", c("2014", "2015", "2016"))); h[1, 2] <- 2e5
cl <- data.frame(Claim_id = "C1", Origin_year = 2015L); f <- matrix(0, 1, 250)
s <- function(ind) sum(xl_cashflow(f, cl, h, re, ind, output = "total"))
round(c(ohne = s(mk_idx(2099)), schub2014 = s(mk_idx(2014)),
        schub2015 = s(mk_idx(2015)), schub2016 = s(mk_idx(2016))))
# 100000 100000 80000 100000 - nur der Schub im Basisjahr 2015 wirkt, erwartet 100000
```
**Datei:** `R/reinsurance.R:76-85`.
**Wirkung.** Ein Schub im Basisjahr senkt den XL-Anteil um 20 %, obwohl die Klausel dort noch nicht
greifen darf; die Priorität ist um ein Indexjahr zu hoch.
**Vorschlag.** Kumulation ab B+1 beginnen und den Vektor ab B ablegen.
**Test.** Schub im Basisjahr ändert nichts (100000), Schub danach schon.

### C-F05 — Das letzte Abwicklungsjahr fehlt im additiven Modell

**Symptom.** `max_dev_year <- max(1, NROW(orig_years) - 1)` lässt das Abwicklungsjahr N weg; dort
beobachtete Spätgroßschäden zählen nicht.

**Reproduktion**
```r
library(sicr)
ex <- data.frame(Origin_year = 2019:2023, Exposure = 1)
lcl <- data.frame(Claim_id = "C1", Origin_year = 2019, Large_since = 2023,
                  Dev_year_of_growing_large = 5)
m <- get_additive_ibnr_model(lcl, 2019, 2023, ex, 2019:2023)
nrow(m); sum(m$Ibnr_numbers)     # 4 und 0, erwartet 5 und 1
```
**Datei:** `R/ibnr.R:49`.
**Wirkung.** Erwartete Spätgroßschäden im letzten Abwicklungsjahr fehlen vollständig; Paper 2.4.5
(S. 16) verlangt „für jedes Abwicklungsjahr“.
**Vorschlag.** `max_dev_year <- max(1, NROW(orig_years))`.
**Test.** 5 Zeilen, ein gezählter Schaden.

### D-F01 — Sterbealter bekannter Renten um ein Jahr zu jung

**Symptom.** Die erste Zahlung (Jahr Cy+1) ist sicher; danach muss der Rentner die Jahre Cy+1, Cy+2 …
überleben, also q(x+1), q(x+2) … Das Paket rechnet mit q(x), q(x+1) …

**Reproduktion**
```r
library(sicr)
mort <- data.frame(Gender = rep(c("m","f"), each = 122), Age = rep(0:121, 2),
                   Probability = rep(ifelse(0:121 == 50, 1, 0), 2))   # q(50)=1
an <- data.frame(Claim_id="C1", Annuity_id="A1", Origin_year=2023L, Calendar_year=2023L,
                 Entering_year=2023L, Annuity_start=2023L, Annuity_end=0L,
                 Birth_year=1973L, Gender="m", Annual_payment=1000, Dynamic=0)
sh <- data.frame(Gender=c("m","f"), Birth_year=1973L, Age_shift=0L)
probs <- generate_annuity_probabilities(an, mort, sh)
roll_out_annuity(generate_annuity_payments(an, 2023), probs,
                 stop.at = "end_of_probs")[1, 1:2]      # 1000 0, erwartet 1000 1000
```
**Datei:** `R/annuity_functions.R:161, 172`.
**Wirkung.** Undiskontierte Zahlungen der Beispielrenten +1,86 % (9.239.437 statt 9.070.927), also
systematisch vorsichtig. Die Einstufung hängt an der Alterskonvention; der Pool-Pfad desselben Pakets
stützt q(x+1).
**Vorschlag.** Bei bekannten Renten das Bewertungsjahr um eins erhöhen (Wrapper in
`verbesserungen/D-F01.R`).
**Test.** Zahlung 2025 = 1000 statt 0.

---

## B) Robustheit und Eingabeprüfungen

### A-F02 — `start_of_tail <= 2` erzeugt Pretail-Pools für Jahr 1/0
**Symptom.** `2:(start_of_tail - 1)` läuft für `start_of_tail = 2` absteigend (`c(2,1)`); Jahr 2 liegt
doppelt im Pretail- und im Nachlaufpool.
**Reproduktion**
```r
library(sicr)
d <- data.frame(Ind_cl_payment_cal = 10, Exit_reserve_class = 0L,
                New_annuity_1 = 0, New_annuity_2 = 0, New_annuity_3 = 0, New_annuity_4 = 0,
                New_annuity_5 = 0, Dev_year_since_large = 2L, Entry_reserve_class = 0L,
                Calendar_year = 2020L, Ind_entry_cl_reserve = 0)
attr(d, "threshold") <- 400000; attr(d, "index_year") <- 2020
p <- generate_pools(d, c(1), 2020L, 2, 5, -Inf, Inf, NULL)
length(p[[1]][[1]])                       # 2, erwartet 0
sum(p[[2]][[1]]$Ind_cl_payment_cal == 10) # 1, die Beobachtung ist doppelt
```
**Datei:** `R/generate_pools.R:73`, `R/sampling_preparation.R:85`.
**Wirkung.** Doppelte Verwendung einer Zahlung und ein Zugriff auf `lengths_vector[0]`.
**Vorschlag.** `seq_len(max(0, start_of_tail - 2)) + 1` an beiden Stellen.
**Test.** 0 Pretail-Jahre, ein Nachlaufpool. (Die Korrektur ist auf A-F01.R und A-F02.R verteilt.)

### A-F03 — Zukunftsindexierung setzt `max(indices) == last_orig_year + 250` voraus
**Symptom.** `tail(indices$Transition_factor, 250)[year]` (`R/sicr.R:451`) nimmt die letzten 250 Zeilen;
liefert der Nutzer mehr Zukunftjahre (z. B. Indexdaten bis 2024 bei Bewertung 2023), verschiebt sich
die gesamte Indexierung.
**Reproduktion** (32 Zeilen, weil `sicr()` Objekte braucht; läuft wie abgedruckt)
```r
library(sicr)
mk <- function(extra) {                      # Indexreihe mit/ohne ein zusätzliches Jahr
  jahre <- 2015:(2020 + 250 + extra)
  i <- data.frame(Calendar_year = as.integer(jahre), Index_gross = 0.01, Index_re = 0)
  k <- cumprod(1 + i$Index_gross)
  i$Transition_factor <- k / k[i$Calendar_year == 2020]
  attr(i, "index_year") <- 2020L; i
}
d <- data.frame(Ind_cl_payment_cal = 1000, Exit_reserve_class = 0L,
                New_annuity_1 = 0, New_annuity_2 = 0, New_annuity_3 = 0, New_annuity_4 = 0,
                New_annuity_5 = 0, Dev_year_since_large = 3L, Entry_reserve_class = 0L,
                Calendar_year = 2020L, Ind_entry_cl_reserve = 0)
attr(d, "threshold") <- 1; attr(d, "index_year") <- 2020
pools <- list(list(list(d)), list(d), NULL)
attr(pools, "reserve_classes") <- 1; attr(pools, "years_for_pools") <- 2020
attr(pools, "start_of_tail") <- 3; attr(pools, "end_of_tail") <- 5
attr(pools, "lower_outlier_limit") <- -Inf; attr(pools, "upper_outlier_limit") <- Inf
attr(pools, "threshold") <- 1; attr(pools, "index_year") <- 2020
lcl <- data.frame(Claim_id = "C1", Origin_year = 2020L, Exit_reserve_class = 0L,
                  Dev_year_since_large = 1L, Dev_year_of_growing_large = 1L,
                  Large_since = 2020L, Cl_reserve = 0, Ind_cl_reserve = 0)
attr(lcl, "index_year") <- 2020; attr(lcl, "reserve_classes") <- 1
h <- matrix(0, 1, 1, dimnames = list(NULL, "2020"))
lauf <- function(ind) sicr(n = 1, large_claims_list = lcl, first_orig_year = 2020,
                           last_orig_year = 2020, pools = pools, indices = ind, history = h,
                           progress = FALSE, summary = FALSE, seed = 1)
lauf(mk(0))[1, 1, 1]   # 1010
lauf(mk(1))[1, 1, 1]   # 1020.1 - ein zusätzliches Indexjahr verschiebt alles, erwartet 1010
```
**Datei:** `R/sicr.R:451`.
**Wirkung.** Alle künftigen Zahlungen sind um ein Indexjahr verschoben, ohne Meldung.
**Vorschlag.** Zugriff über `match(last_orig_year + year, indices$Calendar_year)`.
**Test.** Beide Reihen liefern dieselbe Zahlung.

### B-F02 — Fehlendes `index_year` bricht mit `numeric(0)` ab
`sicr::add_transition_factor(data.frame(Calendar_year = 2015:2017, Index_gross = 0.02), 2020)`
→ „replacement has 0 rows, data has 3“. **Datei:** `R/data_functions.R:78-79`. **Vorschlag:** prüfen,
dass `index_year` genau ein Wert und in `Calendar_year` enthalten ist. **Test:** klare Meldung.

### B-F03 — `inc2cum()` stürzt bei leerer Matrix ab
`inc2cum(matrix(0, 0, 3))` → „subscript out of bounds“ (`for (i in 1:NROW(...))`, `R/basic.R:433-438`).
**Vorschlag:** `seq_len(NROW(...))`. **Test:** leere Matrix bleibt leer.

### B-F04 — `cum2inc(numeric(0))` liefert `NA`
`cum2inc(numeric(0))` → `NA` statt `numeric(0)` (`R/basic.R:450-453`). **Vorschlag:** leere Eingabe
früh zurückgeben. **Test:** `numeric(0)`.

### C-F01 — Ungültiger `Rollout_type` liefert still einen Null-Cashflow
`sicr::roll_out_single_claim(1000, 5, type = "quadratic")` → Summe 0, die Warnung verspricht „linear“
(`art <- "linear"` statt `type`, `R/special_claims.R:28-32`). **Vorschlag:** `type <- "linear"`.
**Test:** identisch zu `type = "linear"`.

### C-F02 — `output == "future"` statt Zuweisung
`sicr::xl_cashflow(..., output = "futur")` liefert 252 statt 250 Spalten (`R/reinsurance.R:310-313`).
**Vorschlag:** `output <- "future"`. **Test:** 250 Spalten.

### D-F02 — `!is.null("reinsurance")` ist immer wahr
`sicr::compute_small_claims(...)` ohne RV-Programm liefert für `small_ceded_quota_payments` einen
leeren Vektor statt der Nullmatrix (`R/small_claims.R:609`). **Vorschlag:** `!is.null(reinsurance)`.
**Test:** Nullmatrix.

### D-F04 — `generate_pattern()` stürzt bei einspaltigem Dreieck ab
`sicr::generate_pattern(matrix(1000, 1, 1))` → „dev_year must be integer greater 0“ (`1:0`,
`R/small_claims.R:81-82`). **Vorschlag:** nur über vorhandene Abwicklungsjahre iterieren.
**Test:** `numeric(0)`.

### D-F05 — `fill_up_triangle()` stürzt bei einspaltigem Dreieck ab
`sicr::fill_up_triangle(matrix(1000, 1, 1), pattern = 1.1)` → „subscript out of bounds“
(`R/small_claims.R:132-133`). **Vorschlag:** `seq_len`-Schleife. **Test:** 1×2-Matrix 1000/1100.

### D-F06 — Künftige Basisrenten brechen bei einem Anfalljahr ab
`sicr::generate_small_claims_future_annuities(params, matrix(1000,1,1,dimnames=list("2023","2023")), idx)`
→ „subscript out of bounds“ (`2:years_count`, `R/small_claims_future_annuities.R:307,320`).
**Vorschlag:** mit klarer Meldung abbrechen (so macht es die aktuelle Korrektur). **Test:** Meldung
statt Absturz.

### E-F03 — Leere Schadenliste bricht mit unklarem Fehler ab
`ind_known_claims <- 1:NROW(large_claims_list)` ist bei leerer Liste `c(1,0)`; die 1 selektiert die
IBNR-Zeile → „cashflow must have same number of rows“ (`R/aggregate_large_claims_results.R:93`).
**Vorschlag:** `seq_len(NROW(...))`. **Test:** Nullmatrizen.

### E-F04 — `indices_ok()` prüft die Struktur nicht
`indices_ok(data.frame(Calendar_year = 1989:2273, Index_gross = 0.02), 1989, 2023)` → `TRUE`, obwohl
`Index_re` und `Transition_factor` fehlen (`R/data_checks.R:477-501`; der Aufruf von
`check_dataframe_structure()` fehlt). **Vorschlag:** Struktur prüfen, `Transition_factor`
aufnehmen. **Test:** `FALSE` für den lückenhaften Datensatz.

### E-F05 — `indices_ok(NULL)` liefert den Character `"FALSE"`
`indices_ok(NULL, 1989, 2023)` → `"FALSE"` (character) statt logisch (`R/data_checks.R:494`).
**Vorschlag:** `FALSE` zurückgeben. **Test:** `isFALSE()`.

### E-F06 — Tippfehler legt die Wertebereichsprüfung der Sterbetafel lahm
`mortality_ok()` liest `df$Probabilty` (`R/data_checks.R:685`); q = −5 wird akzeptiert (`TRUE`).
**Vorschlag:** `df$Probability`. **Test:** `FALSE` für q = −5.

### E-F07 — `reinsurance_ok()` verlangt `Limit` nicht
Ein RV-Datensatz ohne `Limit` gilt als gültig, obwohl `xl_cashflow()` die Spalte braucht
(`R/data_checks.R:551-558`). **Vorschlag:** Spalte in `structure_list` aufnehmen (Typ prüfen, `NA`
nur zulassen, wenn kein XL verwendet wird). **Test:** `FALSE` ohne `Limit`.

### E-F08 — `add_sicr_worksheet()` lässt eine globale Option stehen
`options(openxlsx2.string_nums = TRUE)` (`R/Excel_Output.R:95`) wird nie zurückgesetzt; nach dem
Aufruf ist die Option der Session `TRUE`. **Vorschlag:** `on.exit(options(...))`. **Test:** alter Wert
wiederhergestellt.

### F-F02 — Quantilslegende passt nicht zu den Balken
Die Balken sind Inkremente (Q75 = q25…q75, Q90 = q75…q90, Q99 = q90…q99); beschriftet werden sie als
„1%-99%“, „10%-90%“, „25%-75%“ in der Reihenfolge Q99/Q90/Q75 (`R/plots.R:1309-1315`).
**Reproduktion:** Legende im Plot `backtesting_1y_single_per_dev_year()` ansehen; Q99 trägt
„25% - 75%“. **Vorschlag:** Labels an die Faktorstufen binden (benannte Vektoren) und die
Segment- oder Bandkonvention einheitlich wählen. **Test:** Labels je Stufe prüfen.

### F-F03 — Mehrjahres-Backtesting erfindet ohne Folgejahr ein Jahr
Bei `n_years = 0` läuft `1:0`, `Year` wird `c(reserving_year + 1, reserving_year)`
(`R/plots.R:1983-2005`). **Vorschlag:** bei `n_years < 1` mit Meldung abbrechen. **Test:** ein Jahr
bzw. Meldung.

---

## C) Fehlende Paper-Punkte

**Keine.** Die drei im Audit als „fehlt“ geführten Punkte sind keine Anforderungen des Berichts an ein
Paket (siehe unten). Von den 10 als „konform, aber durch einen Fehler beeinträchtigt“ geführten
Punkten bleibt jeder gültig, weil der jeweilige Fehler oben bestätigt ist; die Zuordnung ist
nachvollziehbar und wird nicht beanstandet.

## D) Optionale Hinweise (keine Fehler)

1. **Großschadengrenze prüfen.** Das Paper empfiehlt, G deutlich unter die kleinste RV-Priorität zu
   legen („sollte“, S. 11). Eine Warnung in `prepare_data()`, wenn `threshold >= min(Priority)`, wäre
   hilfreich.
2. **Ultimate-Backtesting.** Der Bericht zeigt es als Anwendung (S. 22, 43, 49); das Paket hat nur das
   Cashflow-Backtesting. Eine optionale Funktion wäre eine Ergänzung, keine Lücke.
3. **Drei Fassungen von `indices_ok_v()`.** E-F04, E-F05 und E-V01 definieren dieselbe Funktion
   unterschiedlich (E-F04 ohne Rückgabetyp-Fix, E-V01 ohne Strukturprüfung). Wer eine übernimmt,
   verliert die anderen; eine zusammengeführte Fassung wäre besser.
4. **Segment- oder Bandkonvention der Quantilslegende.** Auch nach F-F02 bleibt offen, ob die Legende
   Bänder (25–75 %) oder Segmente (75–90 %) beschriftet; eine Entscheidung im Code wäre gut.
5. **Reserveklasse 0 in `plot_pools_overview()`.** Die Funktion zeigt `RC1..RCn`, legt aber auch
   Klasse 0 an (`R/plots.R:738-789`); die Auslassung ist nicht dokumentiert.
6. **`check_dataframe_structure()` mit leerer Strukturliste.** `for (column in 1:NROW(structure))`
   läuft über 1 und 0 und bricht mit „argument is of length zero“ ab; aus der öffentlichen API nicht
   erreichbar, deshalb nur ein Hinweis.
