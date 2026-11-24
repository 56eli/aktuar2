# Gruppe F: plots_backtesting

Dateien: `R/plots.R` (2120 Zeilen) · Funktionen: 9

## Überblick

`R/plots.R` enthält vier Diagnosegrafiken (Sonderschäden, Best Estimate vs. Reserve, Pools), den Serien-Helfer `sicr_series()` und vier Backtesting-Grafiken. Das Papier verlangt ein Cashflow-Backtesting der Zahlungen des ersten Folgejahres (S. 22) und beschreibt ein Ultimate-Backtesting mit \((Ultimate_t-Ultimate_{t-1})/BE_{t-1}\) gegen die Benchmarks 9 % bzw. 10 % (S. 22, 43, 49); das ist eine Anwendung der UAG, keine Paketpflicht. Das Cashflow-Backtesting ist der Struktur nach vorhanden, eine Ultimate-Auswertung ist nicht implementiert. Zwei der drei 1-Jahres-Funktionen vergleichen zudem nominale Erwartungswerte mit auf das Indexjahr deflationierten Ist-Werten; im Einzelschaden-Plot ist die Quantilslegende vertauscht, und das Mehrjahres-Backtesting erfindet ohne Folgejahr ein zusätzliches Jahr. Der Code ist stark dupliziert: 613 der 2120 Zeilen sind Roxygen (29 %), von 1301 Codezeilen beträgt der Duplikatanteil 0,39; die beiden 1-Jahres-Funktionen sind zu 89 % identisch. Gesamturteil: Cashflow-Backtesting eingeschränkt paperkonform, optionale Ultimate-Auswertung nicht implementiert, Grafiken konzeptionell sinnvoll, aber fehleranfällig und stark redundant.

## Funktionen

### `plot_identify_special_claims()` — `R/plots.R:47-154`
- **Zweck:** Stellt die Eintrittsreserven der Poolbeobachtungen den Reserven der zu simulierenden Schäden je Abwicklungsjahr und Reserveklasse gegenüber, optional mit markierten Sonderschäden.
- **Paperbezug:** 2.5.1 Identifikation von Sonderschäden, S. 18 (grafische Methoden und quantilbasierte Grenzwerte) · konform/Erweiterung · Die Grafik setzt die dort genannte grafische Identifikation um; eine automatische Quantilsgrenze ist nicht implementiert, das Papier nennt sie nur als denkbare Variante.
- **Fehler:** keine gefunden. Der dokumentierte Default `special_claims = NULL` funktioniert, weil `%in% NULL` einen logischen Vektor liefert und `generate_claims_list()` auch auf einem leeren Datenframe ein leeres Schema zurückgibt.
- **Verdacht (unbelegt):** `start_of_tail <- max(pools_as_df$Dev_year_since_large)` (Z. 57) statt `attr(pools, "start_of_tail")`; das ist nur korrekt, solange `pools2dataframe()` immer eine Tail-Zeile anlegt. Bei `selected_reserve_classes` ohne Treffer ist `range(data$Reserve)` leer (Z. 136); in ggplot2 4.0.3 baut die Grafik mit Warnungen, das Verhalten ist aber versionsabhängig.
- **Verbesserungen:** keine umgesetzt; die doppelte Konstruktion von `Dev_year_new` (Z. 74-75) und die wiederholten `rbind`-Blöcke (Z. 88-104) ließen sich zusammenfassen.
- **Hinweise:** Die Klassenbeschriftung (Z. 146-150) markiert die Untergrenzen `reserve_classes` als „class 1..K“; Klasse 0 bleibt unbeschriftet.

### `plot_reserve_vs_be()` — `R/plots.R:213-348`
- **Zweck:** Vergleicht den simulierten Best Estimate je Reserveklasse und je Abwicklungsjahr mit der HGB-Reserve.
- **Paperbezug:** Best Estimate als Erwartungswert der zukünftigen Zahlungen, S. 7; Analyse von Best Estimate und Schadenreserven, S. 54 · Erweiterung · Die Grafik ist eine Auswertungshilfe, keine im Papier definierte Pflichtgrafik.
- **Fehler:** keine belegten.
- **Verdacht (unbelegt):** `Best_Estimate` summiert nur `Claim_payments` und `Future_annuities_payments` (Z. 219-222), nicht `Active_annuities_payments`. Verglichen wird mit `Cl_reserve`; ob die Nichtberücksichtigung aktiver Renten fachlich gewollt ist, ist nicht dokumentiert.
- **Verbesserungen:** `F-V02` (kürzer/lesbarer) beseitigt die fast identischen Plotblöcke `plot_rc` (Z. 258-300) und `plot_dy` (Z. 302-345); Test `tests/verbesserungen/test-F-V02.R`, Code `verbesserungen/F-V02.R`.
- **Hinweise:** `scale_x_continuous` erzeugt für Reserveklassen und Abwicklungsjahre jeweils eine zusätzliche, nicht vorhandene Achsenmarke `max + 1` (Z. 279-282, 327-330); harmlos, aber unsauber.

### `plot_reserve_vs_be_per_claim()` — `R/plots.R:407-655`
- **Zweck:** Stellt je Einzelschaden Best Estimates und Reserven getrennt für Vorlauf und Nachlauf dar; die Best Estimates kommen aus `sicr_single()`.
- **Paperbezug:** Nachlaufdefinition 2.4.4, S. 15; Einzelschadenanalyse S. 9 und S. 54 · Erweiterung · Nutzt die Einzelschadensicht, ist aber keine Pflichtgrafik des Berichts.
- **Fehler:** keine belegten.
- **Verdacht (unbelegt):** `x_dist_pretail <- max(large_claims_list_pretail$Cl_reserve) / 1000` (Z. 466-467) liefert bei leerer Vorlauf- oder Nachlaufgruppe `-Inf` mit Warnung; außerdem werden die Klassenobergrenzen `reserve_classes` (indexiert) mit nominalen `Cl_reserve` verglichen (Z. 488-491), obwohl die Klassenzuordnung sonst über `Ind_cl_reserve` erfolgt.
- **Verbesserungen:** keine umgesetzt; die Plotblöcke `plot_pretail` (Z. 522-587) und `plot_tail` (Z. 588-655) sind nahezu identisch, ebenso die Palette (Z. 421-431) mit der in `plot_pools_overview()` (Z. 713-723).
- **Hinweise:** Der Aufruf `sicr_single(dev_year = 1:end_of_tail, reserve_class = 0:(n_rc-1), n = n)` (Z. 442-449) ist teuer; für jeden Plotaufruf werden alle Klassen und Abwicklungsjahre neu simuliert.

### `plot_pools_overview()` — `R/plots.R:706-943`
- **Zweck:** Vier Grafiken zu Poolgrößen, Reserveklassenbreiten sowie Verteilung der Reserven und der offenen Schäden auf die Reserveklassen.
- **Paperbezug:** Poolbildung 2.4.2/2.4.3, S. 14; Poolgrößen und Reserveklassen S. 8, 14 · Erweiterung · Sinnvolle Diagnose der Poolbesetzung, im Bericht nur als tabellarische/grafische Auswertung angedeutet.
- **Fehler:** keine belegten.
- **Verdacht (unbelegt):** `n_rc <- length(reserve_classes)` und `for (rc in n_rc:1)` (Z. 731-738) lassen die Reserveklasse 0 in `plot_obs_numbers` weg; auch `plot_stack` verwendet nur `RC1..RCK` (Z. 780-783). Klasse 0 ist im Paket eine echte Poolklasse (`generate_pools()` legt sie an), die Auslassung ist nicht dokumentiert und unterschätzt die Zahl der Poolbeobachtungen.
- **Verbesserungen:** `F-V01` (effizienter) ersetzt die verschachtelte `rbind`-Schleife (Z. 735-744) durch einen vektoriellen Aufbau; Test `tests/verbesserungen/test-F-V01.R`, Bench `bench/F-V01.R`, Code `verbesserungen/F-V01.R`.
- **Hinweise:** Die Palette hat nur 11 Farben (Z. 713-723); bei mehr als 11 Reserveklassen ist die manuelle Skala nicht mehr ausreichend.

### `sicr_series()` — `R/plots.R:1025-1125`
- **Zweck:** Führt `sicr()` n-mal mit je einer Realisation aus und legt die gewählten Ergebnis-Matrizen als Array mit Backtesting-Attributen ab.
- **Paperbezug:** Hilfsfunktion für das Cashflow-Backtesting nach S. 22 · nicht im Paper (Hilfsfunktion) · Das Papier beschreibt keine Serienfunktion, sondern nur die Backtesting-Auswertung.
- **Fehler:** keine belegten. `n = 1` ist korrekt, weil `simplify2array()` für eine Matrix ein Array mit dritter Dimension 1 erzeugt; der Seed je Realisation (`seed - 1 + realisation`) passt zu `dimnames(result)[[3]] <- seed:(seed + n - 1)` (Z. 1099, 1123).
- **Verdacht (unbelegt):** `n` wird nicht validiert; `n < 1` ist nicht definiert und führt zu einem Lauf über `1:0`. Die Fortschrittszeile teilt in der ersten Iteration durch `realisation - 1` (Z. 1080) und zeigt „NaN“.
- **Verbesserungen:** keine umgesetzt; der wiederholte Aufruf von `sicr(n = 1)` (Z. 1086-1102) ist deutlich teurer als ein Aufruf `sicr(n = n)`, liefert aber einzelne Realisationen und ist deshalb nicht ohne Umbau der Seed-Logik ersetzbar.
- **Hinweise:** `progress = TRUE` ist Default; die irreführende erste Restzeitschätzung ist rein kosmetisch.

### `backtesting_1y_per_reserve_class()` — `R/plots.R:1209-1350`
- **Zweck:** Vergleicht je Reserveklasse die erwarteten Zahlungen des ersten Folgejahres (Mittelwert und Quantile) mit den tatsächlichen Zahlungen.
- **Paperbezug:** Cashflow-Backtesting, prognostizierte vs. tatsächliche Zahlungen im ersten Folgejahr, S. 22 (identisch S. 27, 35, 39, 43, 49) · abweichend · Die Struktur entspricht dem Papier, aber Erwartung und Ist liegen auf unterschiedlichen Preisbasen.
- **Fehler:** `F-F01` (hoch) Die Simulationswerte `series_sum` (Z. 1230) sind nominal, weil `sicr()` die auf das Indexjahr deflationierten Poolzahlungen mit dem `Transition_factor` des Zahlungsjahres multipliziert; der Ist-Wert wird dagegen mit `sum(Ind_cl_payment_cal)` (Z. 1239) auf das Indexjahr deflationiert. Der Bias-Faktor ist der `Transition_factor` des backgetesteten Kalenderjahres relativ zum Indexjahr, also die kumulierte Ist-Inflation seit dem Indexjahr; er ist 1, wenn beide übereinstimmen, und kleiner als 1 für Jahre vor dem Indexjahr. Auf dem Vignetten-Backtesting (Reservierung 2022, Indexjahr 2022, Backtest 2023) hebt die Korrektur den Ist-Wert in jeder Reserveklasse um den Faktor 1,0595 an, also +5,95 %. Die frühere Angabe „rund 16 %“ gilt für diesen Fall nicht; sie wären fünf Jahre Abstand bei 3 %. Beleg: `befunde/test-F-F01.R`; Korrektur: `verbesserungen/F-F01.R`.
- **Verdacht (unbelegt):** `n_rc <- max(large_claims_list$Exit_reserve_class)` (Z. 1223) nimmt die größte beobachtete Klasse statt `attr(pools, "reserve_classes")`; fehlt die höchste Klasse im aktuellen Bestand, wird sie stillschweigend nicht gezeigt.
- **Verbesserungen:** Die Funktion ist zu 89 % mit `backtesting_1y_per_origin_year()` identisch (132 bzw. 133 Codezeilen); eine gemeinsame Hilfsfunktion würde beide halbieren (nicht umgesetzt, siehe `F-H02`).
- **Hinweise:** Die Legendenbeschriftung (Z. 1306-1313) ist positionsabhängig; sie ist nur deshalb sichtbar richtig, weil `override.aes` die Farben in derselben Reihenfolge überschreibt.

### `backtesting_1y_per_origin_year()` — `R/plots.R:1434-1577`
- **Zweck:** Wie zuvor, aber gruppiert nach Anfalljahr statt nach Reserveklasse.
- **Paperbezug:** Cashflow-Backtesting S. 22; im Sach-Bestand zusätzlich Vergleich je Anfalljahr über drei Jahre, S. 52 · abweichend (wegen `F-F01`) · Die Gruppierung ist eine zulässige Variante, der Preisbasenfehler bleibt.
- **Fehler:** `F-F01` (hoch) `sum(Ind_cl_payment_cal)` (Z. 1466) gegen nominale Erwartung (Z. 1457, 1474); gleiche Ursache und gleicher Beleg `befunde/test-F-F01.R`; Korrektur `backtesting_1y_per_origin_year_v()` in `verbesserungen/F-F01.R`.
- **Verdacht (unbelegt):** `orig_years <- min(...):max(...)` (Z. 1450-1451) erzeugt für Anfalljahre ohne Schäden leere Gruppen mit Erwartung und Ist 0, die als Balken erscheinen.
- **Verbesserungen:** siehe `F-H02` (Duplikat mit `backtesting_1y_per_reserve_class()`).
- **Hinweise:** Die x-Positionen der Erwartungs-/Ist-Linien (Z. 1519-1521) sind korrekt, weil `orig_years` eine lückenlose Folge ist.

### `backtesting_1y_single_per_dev_year()` — `R/plots.R:1667-1871`
- **Zweck:** Zoom auf einzelne Schäden einer Reserveklasse: erwartete Zahlungen und Quantile je Abwicklungsjahr, darüber die tatsächlichen Einzelzahlungen.
- **Paperbezug:** Cashflow-Backtesting S. 22, dort aggregiert; Einzelschaden-Zoom ist eine Erweiterung · Erweiterung · Die Funktion nutzt als einzige der drei 1-Jahres-Funktionen `Cl_payment_cal` (Z. 1788, 1803) und vergleicht damit nominal mit nominal.
- **Fehler:** `F-F02` (mittel) Die Beschriftungen von `Q75` und `Q99` sind vertauscht (`Q90` ist richtig): `Q75` ist das breite 25 %-75 %-Band, wird aber als „1% - 99% Quantil“ beschriftet; `Q99` (90 %-99 %) erhält „25% - 75% Quantil“ (Z. 1819-1826). Beleg: `befunde/test-F-F02.R`; Korrektur: `verbesserungen/F-F02.R`.
- **Verdacht (unbelegt):** `label` wird nicht validiert; jeder andere Wert als `"Claim_id"`/`"Origin_year"` wird als Spaltenname interpretiert und führt erst beim Plotbau zum Fehler.
- **Verbesserungen:** keine umgesetzt; die Funktion wiederholt den Quantils-/`tibble`-Aufbau der beiden anderen 1-Jahres-Funktionen.
- **Hinweise:** Das Roxygen-Beispiel verwendet `dev_year = 2:16` (Z. 1661), die Funktion heißt aber `dev_years` (Z. 1670); das Beispiel läuft trotzdem, weil R `dev_year` eindeutig als Präfix von `dev_years` zuordnet; die uneinheitliche Benennung ist nur ein Stilhinweis (siehe `F-H04`).

### `backtesting_multiyears()` — `R/plots.R:1958-2120`
- **Zweck:** Kumulierte erwartete und tatsächliche Zahlungen über mehrere Folgejahre für gewählte Reserveklassen und Abwicklungsjahre.
- **Paperbezug:** Cashflow-Backtesting des ersten Folgejahres S. 22; für den Sach-Bestand zusätzlich Abweichungen je Anfalljahr über drei Jahre, S. 52 · Erweiterung · Die kumulierte Mehrjahressicht geht über die 1-Jahres-Definition hinaus, ersetzt aber kein Ultimate-Backtesting.
- **Fehler:** `F-F03` (mittel) Bei `n_years < 1` (kein Kalenderjahr nach dem Reservierungsjahr) läuft `for (year in 1:n_years)` als `1:0` zweimal (Z. 1983, 1988), und `Year` wird zu `c(reserving_year + 1, reserving_year)` (Z. 2005); die Grafik zeigt ein erfundenes Jahr, ohne zu warnen. Beleg: `befunde/test-F-F03.R`; Korrektur: `verbesserungen/F-F03.R`.
- **Verdacht (unbelegt):** `n_years <- max(Calendar_year) - reserving_year` (Z. 1983) unterstellt lückenlose Kalenderjahre; fehlende Jahre verzerren die kumulierten Fenster.
- **Verbesserungen:** keine umgesetzt; die Funktion ist die kürzeste der Backtesting-Funktionen, dupliziert aber Farben, Theme und Achsenformatierung.
- **Hinweise:** Das Roxygen-Beispiel verwendet `dev_year = 2:16` (Z. 1952), die Funktion `dev_years` (Z. 1961); auch das Vignettenbeispiel (Z. 1106) nutzt die Kurzform; lauffähig ist es über partielle Argumentzuordnung, aber nicht robust (`F-H04`).

### Nicht implementiert: Ultimate-Backtesting — S. 22, 43, 49
- **Paperbezug:** optional · Das Papier definiert das Ultimate-Backtesting als \((Ultimate_t-Ultimate_{t-1})/BE_{t-1}\) mit Benchmark 9 % (KH-Bestände) bzw. 10 % (Feuer, Sach), S. 22, 43, 49. Das ist eine Anwendung der UAG (Kap. 3), keine Paketanforderung. In `R/plots.R` und im übrigen Paket gibt es keine Funktion, die diese Kennzahl berechnet oder grafisch gegen die Benchmark stellt; `backtesting_multiyears()` ist kumuliertes Cashflow-Backtesting und keine Umsetzung davon.
- **Fehler:** `F-H01` (Hinweis, mittel) optionale Auswertung nicht implementiert, kein Test möglich, weil die Funktion nicht existiert.

## Befundliste

| ID | Funktion | Art | Schwere/Ziel | Kurzbeschreibung | Beleg |
|---|---|---|---|---|---|
| F-F01 | `backtesting_1y_per_reserve_class()`, `backtesting_1y_per_origin_year()` | Fehler | hoch | Nominale Erwartung vs. auf das Indexjahr deflationierter Ist-Wert (`Ind_cl_payment_cal`); Bias-Faktor = `Transition_factor` des Backtestjahres relativ zum Indexjahr. Im Vignettenfall 2022/2022/2023 Faktor 1,0595 (+5,95 %). | `befunde/test-F-F01.R`, `verbesserungen/F-F01.R` |
| F-F02 | `backtesting_1y_single_per_dev_year()` | Fehler | mittel | Quantilslegende vertauscht: 25 %-75 %-Band als „1% - 99%“, 90 %-99 %-Band als „25% - 75%“. | `befunde/test-F-F02.R`, `verbesserungen/F-F02.R` |
| F-F03 | `backtesting_multiyears()` | Fehler | mittel | Bei fehlendem Folgejahr (`n_years = 0`) läuft `1:0`, und die Grafik zeigt ein zusätzliches, erfundenes Jahr. | `befunde/test-F-F03.R`, `verbesserungen/F-F03.R` |
| F-V01 | `plot_pools_overview()` | Verbesserung | effizienter | Vektorieller Aufbau von `df_pool_sizes` statt verschachtelter `rbind`-Schleife; gleiche vier Grafiken. | `tests/verbesserungen/test-F-V01.R`, `bench/F-V01.R` |
| F-V02 | `plot_reserve_vs_be()` | Verbesserung | kürzer/lesbarer | Gemeinsame Hilfsfunktion für die beiden nahezu identischen Balkendiagramme; gleiche Grafiken. | `tests/verbesserungen/test-F-V02.R` |
| F-H01 | — | Hinweis (fehlt im Paket) | mittel | Ultimate-Backtesting nach S. 22, 43, 49 ist nicht implementiert. | — |
| F-H02 | `R/plots.R` | Hinweis | Codequalität | 613/2120 Zeilen Roxygen; 1301 Codezeilen, Duplikatanteil 0,39; die beiden 1-Jahres-Funktionen sind zu 89 % identisch; Beispiel-Pipeline neunmal kopiert. | siehe Text |
| F-H03 | `plot_pools_overview()` | Hinweis | niedrig | Reserveklasse 0 fehlt in `plot_obs_numbers` und `plot_stack`; Absicht nicht dokumentiert. | Z. 731-738, 780-783 |
| F-H04 | `backtesting_1y_single_per_dev_year()`, `backtesting_multiyears()` | Hinweis | niedrig | Beispiele nutzen `dev_year` statt `dev_years`; läuft nur über partielle Argumentzuordnung (Stil) | Z. 1661, 1952; `vignettes/sicr.Rmd:1106` |
| F-H05 | `sicr_series()` | Hinweis | niedrig | Erste Fortschrittszeile zeigt „NaN“ (`realisation - 1`); `n < 1` wird nicht abgefangen. | Z. 1080, 1115-1123 |
| F-H06 | `plot_reserve_vs_be_per_claim()` | Hinweis | niedrig | `max()` auf leeren Vorlauf-/Nachlaufgruppen ergibt `-Inf`; nominale `Cl_reserve` werden mit indexierten Klassengrenzen verglichen. | Z. 466-467, 488-491 |
