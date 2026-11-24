# Gruppe E: Ausgabe und Prüfungen

Dateien: `R/aggregate_large_claims_results.R` (207 Zeilen), `R/Excel_Output.R` (308), `R/data_checks.R` (760), `R/data.R` (313, nur Datendokumentation) · Funktionen: 14

## Überblick

Die Gruppe umfasst die Schnittstelle zwischen Simulation und Ergebnisaufbereitung: `aggregate_large_claims_results()` summiert die Einzelschadenergebnisse aus `sicr()` zu Anfalljahres-Cashflows und leitet die gedeckten Rückversicherungsanteile ab, die beiden `add_*_worksheet()`-Funktionen schreiben diese Matrizen als formatierte Excel-Blätter bzw. addieren/subtrahieren Blätter zu Brutto-/Netto-Sichten, und die elf `*_ok()`-Funktionen prüfen die Eingabedatensätze vor der Simulation. `R/data.R` dokumentiert ausschließlich die Beispieldatensätze.

Die Aggregation ist in der Grundidee paperkonform: `sicr()` mittelt die Realisationen (`R/sicr.R:535-540`), sodass die hier summierten Matrizen bereits Erwartungswerte sind (Best Estimate = Erwartungswert der zukünftigen Zahlungen, Paper S. 7); die Quoten- und XL-Anteile werden je Schaden berechnet (Paper S. 55). Zwei Abweichungen sind aber gravierend: der XL-Anteil der Spätgroßschäden fehlt in der gedeckten Sicht (`E-F01`), und die Quote wird über die Zeilenposition statt über das Anfalljahr zugeordnet (`E-F02`). Eine Verteilung/Quantile der simulierten Ergebnisse wird – anders als in Paper S. 55 als Möglichkeit beschrieben – nirgends ausgegeben (Hinweis).

Die Eingabeprüfungen sind systematisch aufgebaut (Struktur-, Dubletten-, Wertebereichs-, Vollständigkeitsprüfungen), aber an mehreren Stellen lückenhaft: eine definierte Struktur wird nicht abgefragt (`E-F04`), ein Rückgabewert hat den falschen Typ (`E-F05`), ein Tippfehler legt eine Wertebereichsprüfung lahm (`E-F06`), und eine von `xl_cashflow()` zwingend benötigte Spalte wird nicht verlangt (`E-F07`). Alle Prüfungen sind Hilfsfunktionen ohne Paperbezug (Erweiterung gegenüber dem Bericht, der nur Datenanforderungen auf S. 9 nennt).

`R/data.R` passt in den Spaltenlisten zu den Funktionen und zur Vignette; zwei Formulierungen sind falsch (`Cl_reserve` als „Claim payments“) und die Zeilenzahl von `indices_xmpl` ist mit dem eigenen Generierungscode nicht vereinbar (Verdacht, unbelegt, da die Datenobjekte nicht Teil des Quellcodes sind).

## Funktionen

### `aggregate_large_claims_results()` — `R/aggregate_large_claims_results.R:84-207`
- **Zweck:** Wandelt die Einzelschaden-Simulationsmatrizen und die historischen Daten in acht Anfalljahres-Matrizen (Zahlungen, Reserven, Renten, IBNR, gedeckte Quote, gedeckter XL) um.
- **Paperbezug:** 1.3 Methodenüberblick, S. 7 (Best Estimate = Erwartungswert der zukünftigen Zahlungen) und 3.2.1 Abbildung des RV-Programms, S. 55 (RV-Programm je Schaden, Netto = Brutto − RV-Anteil) · **konform in der Grundidee, abweichend bei der RV-Abgrenzung** · Die Summation der bereits gemittelten Matrizen (`R/sicr.R:535-540`) ergibt korrekt den Best Estimate; die historische Quotenabgabe (`:190-194`) und der XL-Anteil der bekannten Schäden (`:181-186`) folgen S. 55. Der XL-Anteil der Spätgroßschäden wird jedoch nicht abgezogen (`E-F01`), sodass die Netto-Sicht zu hoch ist; eine Verteilung/Quantile der Realisationen wird nicht ausgegeben (S. 55 nennt VaR/Quantile als Nutzungsmöglichkeit).
- **Fehler:**
  - `E-F01` (hoch) Der XL-Anteil der IBNR-Zeilen fehlt in `large_ceded_xl_payments`: Zeile 157-163 verarbeitet für IBNR nur `sim_result[ind_ibnr,,1]` (Brutto), obwohl `sim_result[,,6]` die XL-Anteile auch für IBNR-Zeilen enthält (`R/sicr.R:591-592`) und Zeile 193 die Quote der IBNR-Zeilen mitnimmt. Netto = Brutto − gedeckt ist im Standardfall (IBNR und XL aktiv) zu hoch. Auf den Beispieldaten ist die Wirkung 0,0 %, weil kein IBNR-Schaden die Beispielprioritäten (1,0–1,5 Mio.) übersteigt. Mit Priorität 500.000 ändert die Korrektur das zedierte XL um −7,04 % und die Nettoreserve um +2,91 % (Runde 3, n = 1, Seed 12345; Runde 2 unabhängig −7,07 % / +2,85 %). Deshalb hoch, nicht kritisch. Beleg: `befunde/test-E-F01.R`.
  - `E-F02` (hoch) Die Quotenabgabe wird über die Zeilenposition zugeordnet: `reinsurance$Quota_share[reinsurance$Origin_year %in% first_orig_year:last_orig_year]` (Zeile 194). Da die Matrixzeilen Anfalljahre sind, wirkt bei nicht nach `Origin_year` sortiertem Dataframe die Quote des falschen Jahres. Zusätzliche Anfalljahre außerhalb des Bereichs filtert `%in%` heraus; nur fehlende Jahre verkürzen den Vektor, was `reinsurance_ok()` im `sicr()`-Pfad abfängt (Gegenprüfung). `xl_cashflow()` löst dasselbe Problem korrekt per `match()` (`R/reinsurance.R:296`). Beleg: `befunde/test-E-F02.R`.
  - `E-F03` (mittel) `ind_known_claims <- 1:NROW(large_claims_list)` (Zeile 93) ergibt bei leerer Schadenliste (nur Spätgroßschäden) `c(1, 0)` statt `integer(0)`; die 0 selektiert nichts, die 1 aber die erste (IBNR-)Zeile von `sim_result`. `convert_single2dev_year_prediction()` erhält damit Zahlungszeilen bei leerem `claims_orig_years` und bricht mit „cashflow must have same number of rows…“ ab, statt Nullmatrizen zu liefern. Beleg: `befunde/test-E-F03.R`.
- **Verdacht (unbelegt):** Der Parameter `history` wird nur im RV-Zweig verwendet (Zeile 168-173); bei `reinsurance = NULL` bleibt er ungeprüft. Es gibt keine einzige Eingabeprüfung: weder `NROW(large_claims_list) == dim(sim_result)[1] - NROW(ibnr_list)` noch `ncol(history) == last_orig_year - first_orig_year + 1` noch die Existenz von `attr(sim_result, "ibnr_list")` werden verifiziert (fehlt das Attribut, werden vorhandene IBNR-Zeilen still ignoriert, da `NROW(NULL) == 0`). Die Doku (Zeile 18-22) nennt die Zeilen „development year“, tatsächlich sind es Anfalljahre; Punkt 6 der Rückgabeliste (Zeile 28) spricht bei `large_ibnr_payments` von „future annuities“ (Copy-Paste aus Punkt 5).
- **Verbesserungen:** (ohne eigene ID, nicht umgesetzt) Die fünf nahezu identischen `convert_single2dev_year_prediction()`-Blöcke (Zeile 116-119, 135-138, 144-147, 159-162, 181-184) ließen sich durch eine Schleife über (Matrixindex, Anfalljahre) ersetzen; das verkürzt die Funktion um rund 15 Zeilen und verhindert, dass ein Block wie in `E-F01` vergessen wird. Als `_v`-Datei nicht abgelegt, weil dafür die komplette 124-zeilige Funktion kopiert werden müsste und das Vergessen eines Blocks gerade der behobene Fehler ist.
- **Hinweise:** Doku Zeile 20-22: „one column for each historic calendar year between first_orig_year and last_orig_year“ gilt nur, weil das Dreieck quadratisch ist. `sample()`/Zufall kommt hier nicht vor, die Reihenfolge der Ziehungen ist unkritisch.

### `add_sicr_worksheet()` — `R/Excel_Output.R:34-210`
- **Zweck:** Schreibt eine Zahlungs-/Reservenmatrix als formatiertes Arbeitsblatt mit den Zusatzspalten Cum. payments, Reserve, Ultimate und Best Estimate in eine `openxlsx2`-Arbeitsmappe.
- **Paperbezug:** nicht im Paper (Hilfsfunktion zur Aufbereitung) · **Erweiterung** · Die ausgewiesenen Größen sind paperkonform interpretierbar: „Best Estimate“ = Summe der prognostizierten Zahlungen (S. 7), „Reserve“ = HGB-Reserve des letzten Kalenderjahres (S. 20), „Ultimate“ = Summe aller Zahlungen. Quantile/Verteilungsmaße (S. 55) werden nicht angeboten.
- **Fehler:** `E-F08` (niedrig) `options("openxlsx2.string_nums" = TRUE)` (Zeile 95) verändert eine globale Option der Session und wird nie zurückgesetzt; alle späteren `openxlsx2`-Aufrufe des Nutzers laufen mit geändertem Verhalten. Beleg: `befunde/test-E-F08.R`.
- **Verdacht (unbelegt):** `years_count <- NROW(payments)` (Zeile 63) setzt voraus, dass die Zahl der historischen Spalten gleich der Zeilenzahl ist und genau 250 Zukunftsspalten folgen; geprüft wird das nicht. Bei `ncol(payments) > years_count + 250` werden die überzähligen Zukunftsspalten in Zeile 70-71 still ignoriert (Ultimate und Best Estimate zu klein), bei weniger Spalten bricht der Zugriff mit „subscript out of bounds“ ab. Ebenso ungeprüft: `reserved[, years_count]` (Zeile 66) verlangt, dass `reserved` mindestens `years_count` Spalten und dieselbe Zeilenreihenfolge wie `payments` hat. Die Parameterdoku von `reserved` (Zeile 11) spricht fälschlich von „historic payments“. Der Zeilenkopf wird als „Dev. years“ beschriftet (Zeile 78), obwohl die Zeilen Anfalljahre sind.
- **Verbesserungen:** Die Doppelberechnung `rowSums(payments[, 1:(years_count + 250)])` (Zeile 70) ließe sich als `cum_payments + best_estimates` aus den ohnehin berechneten Spalten ableiten (eine vollständige Kopie der Matrix weniger); wegen des Fehlerrisikos in der langen `openxlsx2`-Kette hier nicht als `_v`-Datei umgesetzt.
- **Hinweise:** `cols_history`/`cols_future` (Zeile 89-90) sind korrekt aus `years_count` abgeleitet; die Summenzeile (Zeile 75) summiert auch die abgeleiteten Spalten, was für Ultimate und Best Estimate beabsichtigt ist.

### `add_sicr_aggr_worksheet()` — `R/Excel_Output.R:257-308`
- **Zweck:** Erzeugt ein neues Blatt als Summe bzw. Differenz bestehender `sicr`-Blätter (z. B. Brutto minus gedeckt = Netto).
- **Paperbezug:** 3.2.1, S. 55 (Netto = Brutto nach RV-Programm, RV-Anteil = Brutto − Netto) · **konform als Hilfsfunktion** · Die Addition/Subtraktion der Blätter über alle Spalten ab Spalte 5 (inkl. Reserve, Ultimate, Best Estimate) setzt die geforderte Brutto-/Netto-Sicht um; das Papier verlangt keine bestimmte Softwareumsetzung.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** Es wird nicht geprüft, ob die zu verrechnenden Blätter dieselben Dimensionen haben (Zeile 280/287 lesen bis zum Blattende); bei unterschiedlich vielen Zeilen/Spalten scheitert `Reduce("+", …)` (Zeile 282/289) mit einer unspezifischen Meldung. `is.null(sheets_to_add) & is.null(sheets_to_subtract)` (Zeile 259) nutzt den vektorisierten Operator `&` statt `&&`; bei Vektoren entsteht eine Warnung. Die Reihenfolge „erst Quote, dann XL“ wird nur durch die Reihenfolge der Blätter im Arbeitsbuch bestimmt, nicht geprüft.
- **Verbesserungen:** keine (die Duplizierung in Zeile 278-290 ließe sich mit einer Hilfsfunktion `read_sheets(names)` halbieren).
- **Hinweise:** `wb_read(…, start_row = 4, start_col = 5, col_names = FALSE)` (Zeile 280/287) überspringt Kopf- und Summenzeile nicht – die Summenzeile wird bewusst mitaggregiert, was für die Summenzeile des neuen Blattes richtig ist.

### `check_column_type()` — `R/data_checks.R:17-25`
- **Zweck:** Prüft, ob ein Vektor dem gewünschten Typ entspricht; Hilfsfunktion für `check_dataframe_structure()`.
- **Paperbezug:** nicht im Paper (Hilfsfunktion) · **nicht im Paper** · Reine Implementierungshilfe.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** Für `type = "integer"` liefert `all(as.integer(column) == column)` (Zeile 21) bei Werten außerhalb des Integer-Bereichs `NA` (mit Warnung) statt `FALSE`; der Aufrufer `check_dataframe_structure()` prüft `if (nonempty & !check_column_type(...))` (Zeile 57) und bricht dann mit „missing value where TRUE/FALSE needed“ ab. `any(is.na(column))` (Zeile 18) macht NA grundsätzlich unzulässig, unabhängig vom Typ.
- **Verbesserungen:** keine.
- **Hinweise:** `switch()` gibt bei unbekanntem `type` sauber `FALSE` zurück (Zeile 24).

### `check_dataframe_structure()` — `R/data_checks.R:46-63`
- **Zweck:** Prüft, ob ein Dataframe alle in einer Strukturliste genannten Spalten in den erwarteten Typen enthält, und meldet fehlende/falsch typisierte Spalten per `cat()`.
- **Paperbezug:** nicht im Paper (Hilfsfunktion) · **nicht im Paper** · Umsetzungshilfe für die Datenanforderungen aus S. 9.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** `for (column in 1:NROW(structure))` (Zeile 49) läuft bei einer Struktur mit 0 Zeilen über die Indizes 1 und 0, meldet „Column NA is missing“ und gibt `FALSE` zurück. Die Typprüfung wird für leere Dataframes übersprungen (Zeile 48/57), d. h. ein leerer Dataframe mit falschen Spaltentypen gilt als strukturell gültig – das ist beabsichtigt, aber nirgends dokumentiert. Zusätzliche Spalten werden nicht beanstandet.
- **Verbesserungen:** Die Meldungen per `cat()` (Zeile 53/58) lassen sich in `message()`/`warning()` überführen, damit sie unterdrückbar und testbar sind; die Schleife durch `vapply` ersetzbar.
- **Hinweise:** Der Rückgabewert ist immer logisch (TRUE/FALSE), was die anderen `*_ok()`-Funktionen voraussetzen (Ausnahme: `indices_ok()`, siehe `E-F05`).

### `active_annuities_ok()` — `R/data_checks.R:80-168`
- **Zweck:** Prüft den Dataframe der laufenden anerkannten Renten (Struktur, Aktivität, Jahresangaben, Geschlecht, Dubletten, Zahlungshöhe, Dynamik).
- **Paperbezug:** 2.4.6 Berücksichtigung von anerkannten Renten, S. 16-17 · **Erweiterung** · Das Paper fordert die Daten (Alter, Geschlecht, Zahlhöhe, -zeitpunkte), aber keine Prüfroutinen; die Prüfung setzt die dort genannten Anforderungen („Annuity_end must be a future year as it is an active annuity“) in Code um.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** `Annuity_end <= Calendar_year & Annuity_end != 0` (Zeile 113) akzeptiert `Annuity_end == 0` (offenes Ende) nur, wenn `Annuity_start` ebenfalls plausibel ist; ein Datensatz mit `Annuity_end < Annuity_start` und `Annuity_end == 0` wird geprüft, ein `Annuity_start == 0` aber nicht abgefangen. Es fehlt außerdem die Prüfung, dass alle `Claim_id` im Schadendatensatz existieren und dass `Birth_year`/`Entering_year` nicht in der Zukunft liegen – beides würde Fehler früher zeigen, ist aber ohne Übergabe der Schadendaten nicht prüfbar.
- **Verbesserungen:** Die neun Prüfblöcke (Zeile 113-164) sind bis auf die Bedingung identisch aufgebaut und ließen sich als Liste (Bedingung, Meldung) in einer Schleife abarbeiten; das halbiert die Funktion.
- **Hinweise:** `NROW(df) < 1` (Zeile 110) gibt bei leerem Dataframe `TRUE` zurück; das ist sinnvoll, weil `sicr()` den Datensatz dann ignoriert (`R/sicr.R:386`).

### `pool_of_annuities_ok()` — `R/data_checks.R:184-259`
- **Zweck:** Prüft den Dataframe aller historischen Rentenanerkennungen; gleiche Prüfungen wie `active_annuities_ok()` ohne die Aktivitäts- und Kalenderjahrbedingungen.
- **Paperbezug:** 2.4.7 Berücksichtigung von zukünftigen Verrentungen, S. 17 · **Erweiterung** · Das Paper beschreibt die Pools der historischen Anerkennungen; die Funktion prüft deren Datenqualität, was über das Paper hinausgeht.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** `Annuity_end != 0` (Zeile 217) ist hier die einzige Stelle, an der ein offenes Ende behandelt wird; ein `Annuity_end` vor `first_orig_year` wird nicht beanstandet. Wie bei `active_annuities_ok()` fehlt der Abgleich mit dem Schadenbestand.
- **Verbesserungen:** Der Dataframe ist bis auf zwei Blöcke identisch zu `active_annuities_ok()` (Zeile 185-197 = 81-93, Zeile 217-256 = 125-164): ein gemeinsamer Helfer `annuities_ok(df, check_active)` würde rund 70 Zeilen Duplikat entfernen.
- **Hinweise:** keine.

### `claims_data_ok()` — `R/data_checks.R:275-335`
- **Zweck:** Prüft den Schadendatensatz (7 Spalten, keine Dubletten je Schaden/Kalenderjahr, Anfalljahr und Kalenderjahr im gültigen Bereich).
- **Paperbezug:** 1.4 Datenanforderungen, S. 9 und 2.2 Trennung Basis-/Großschäden, S. 11-13 · **Erweiterung** · Das Paper verlangt Einzelschadendaten mit Zahlungen und HGB-Reserven je Jahr; die Prüfung stellt deren Konsistenz sicher, ohne dass das Paper Prüfregeln vorgibt.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** Es fehlen Plausibilitätsprüfungen, die Fehler früh zeigen würden: negative `Cl_reserve`/`An_reserve` (Reserven sollten ≥ 0 sein, negative Zahlungen sind dagegen zulässig), `An_payment_cal`/`An_reserve` ungleich 0 bei Schäden ohne Rente, Lücken in der Zeitreihe eines Schadens (ein Schaden darf Jahre ohne Zeile haben, dann ist die Historie aber unvollständig) und `Origin_year < first_orig_year` (Parameter wird nicht übergeben, Zeile 275). Die Meldung in Zeile 294 („must not be NULL“) enthält kein abschließendes `\n`.
- **Verbesserungen:** Die drei Bereichsprüfungen (Zeile 311-332) ließen sich mit `stopifnot`-artigen Kurzformen zusammenfassen; der Nutzen ist gering.
- **Hinweise:** `last_orig_year` wird konsequent als letztes beobachtetes Kalenderjahr interpretiert (Zeile 329) – konsistent zu `generate_triangle()`.

### `exposure_ok()` — `R/data_checks.R:353-389`
- **Zweck:** Prüft den Exposure-Dataframe (zwei Spalten, ein Eintrag je Anfalljahr, keine fehlenden Jahre).
- **Paperbezug:** 2.4.5 Ansatz für Spätgroßschäden, S. 16 (Bestandsgröße je Anfalljahr) · **Erweiterung** · Das Paper verlangt Exposuregrößen als optionale Daten (S. 9) und nutzt sie für die erwartete Anzahl später Großschäden; die Prüfung ist Umsetzungshilfe.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** Es fehlt die Prüfung `Exposure > 0`. Negative oder Nullwerte laufen bis in `get_expected_ibnr_numbers()` (`R/ibnr.R:104-112`) und erzeugen negative bzw. verschwindende erwartete IBNR-Anzahlen. Zusätzliche Anfalljahre außerhalb `first_orig_year:last_orig_year` werden nicht beanstandet, obwohl `get_expected_ibnr_numbers()` die Zeilenzahl von `exposure` als Matrixdimension verwendet (`R/ibnr.R:104-106`) und damit bei abweichender Länge falsch zuordnet.
- **Verbesserungen:** `E-V02` (kürzer/lesbarer) – frühzeitige Rückgaben statt `p`-Flag; Rückgabewert identisch, Code: `verbesserungen/E-V02.R`, Gleichheitstest: `tests/verbesserungen/test-E-V02.R`.
- **Hinweise:** `exposure = NULL` ist ausdrücklich erlaubt (Zeile 365) und wird in `sicr()` durch konstantes Exposure ersetzt (`R/ibnr.R:371-372`).

### `historic_indices_ok()` — `R/data_checks.R:406-459`
- **Zweck:** Prüft die historische Indexreihe (zwei Pflichtspalten, keine doppelten Jahre, vollständige Jahre, Indexwerte im Wertebereich, optional `Index_re`).
- **Paperbezug:** 2.1 Indexierung, S. 10 · **Erweiterung** · Das Paper verlangt eine dokumentierte Indexreihe und die Indexierung von Zahlungen und Reserven; die Prüfung ist Umsetzungshilfe ohne eigene Paperanforderung.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** Die Wertebereiche sind inkonsistent zu `indices_ok()`: hier `<= -1 | >= 1` (Zeile 444/451), dort `< -1 | > 1` (Zeile 520). Ein Index von genau 1 (Verdopplung) wird von der historischen Prüfung abgelehnt, nach `expand_historic_indices()` von `indices_ok()` aber akzeptiert. `expand_historic_indices()` erlaubt fehlendes `Index_re` und setzt es auf 0 (`R/data_functions.R:44`), `indices_ok()` verlangt die Spalte danach zwingend (Zeile 482) – das ist beabsichtigt, aber nirgends erläutert.
- **Verbesserungen:** Die beiden Indexprüfungen (Zeile 444-455) ließen sich über eine gemeinsame Schleife über `c("Index_gross", "Index_re")` zusammenfassen.
- **Hinweise:** Die Prüfung der 250 Zukunftshahre fehlt hier bewusst; sie erfolgt in `indices_ok()` (Zeile 508).

### `indices_ok()` — `R/data_checks.R:477-532`
- **Zweck:** Prüft die vollständige Indexreihe (inkl. 250 Zukunftshahre) für die Indexierung und die RV-Indexklausel.
- **Paperbezug:** 2.1 Indexierung, S. 10 (einheitliches Indexierungsjahr, Indexierung von Zahlungen und Reserven) · **Erweiterung** · Die Funktion sichert die Datenbasis für die Indexierung ab; das Paper fordert die Indexierung, nicht die Prüfung.
- **Fehler:**
  - `E-F04` (mittel; betrifft nur fehlerhafte Eingaben) Die Struktur `Calendar_year`/`Index_gross`/`Index_re` wird in Zeile 479-485 definiert, `check_dataframe_structure()` aber nie aufgerufen (der Block fehlt zwischen Zeile 499 und 501). Datensätze ohne `Index_re` oder mit falschen Spaltentypen gelten als gültig; `sicr()` (Zeile 331) lässt sie durch, und `xl_cashflow()` rechnet danach mit `NULL`-Indizes (`R/reinsurance.R:76`). Beleg: `befunde/test-E-F04.R`.
  - `E-F05` (niedrig) Für `indices = NULL` gibt Zeile 494 den Character-Wert `"FALSE"` statt des logischen `FALSE` zurück und verletzt damit den dokumentierten Rückgabevertrag („TRUE if every check is passed, else FALSE“). Im Aufrufer `sicr()` (Zeile 331) wirkt das nur zufällig richtig, weil `!"FALSE"` zu `TRUE` evaluiert und der Abbruch damit erfolgt; jede Prüfung des Rückgabewerts (`isFALSE()`, `expect_false()`) schlägt dagegen fehl. Beleg: `befunde/test-E-F05.R`.
- **Verdacht (unbelegt):** Die Sortierprüfung (Zeile 514) ist korrekt, aber umständlich (siehe `E-V01`). `Index_re`/`Index_gross` werden nur auf den Wertebereich, nicht auf `NA` geprüft – `check_column_type()` lehnt NA ab, wird hier aber nicht aufgerufen (`E-F04`); nach der Korrektur ist das erledigt. Fehlt das Attribut `index_year`, wird nur eine Meldung ohne Zeilenumbruch ausgegeben (Zeile 527).
- **Hinweis zur Korrektur:** Auch mit E-F04 fehlt `Transition_factor` in der Strukturliste, obwohl `apply_index()` die Spalte nutzt (`R/basic.R:336`). E-F04, E-F05 und E-V01 liefern je eine eigene `indices_ok_v()`; sie zeigen jeweils nur ihren Punkt und sind nicht zum gemeinsamen Laden gedacht (Gegenprüfung).
- **Verbesserungen:** `E-V01` (kürzer, effizienter) – `is.unsorted(df$Calendar_year)` statt `any(!df$Calendar_year == df$Calendar_year[order(df$Calendar_year)])`; Code: `verbesserungen/E-V01.R`, Gleichheitstest: `tests/verbesserungen/test-E-V01.R`, Benchmark: `bench/E-V01.R`.
- **Hinweise:** Die Prüfung der 250 Zukunftshahre (Zeile 508) ist die einzige Stelle im Paket, die den Prognosehorizont erzwingt; sie ist mit der RV-Indexklausel verzahnt (Base_year kann vor `first_orig_year` liegen, `R/data_checks.R:612-620`).

### `reinsurance_ok()` — `R/data_checks.R:549-623`
- **Zweck:** Prüft den Rückversicherungsdatensatz (Spalten, ein Eintrag je Anfalljahr, Margin-Typ, Margin, Quote, Base_year in den Indizes).
- **Paperbezug:** 2.6 Rückversicherung, S. 18-19 (Priorität, Limit, Quote, Indexklausel) · **Erweiterung** · Das Paper beschreibt die RV-Konstrukte, die hier geprüften Spalten (inkl. `Margin_type`) entsprechen der Umsetzung in `xl_cashflow()`; eine Prüfroutine fordert das Paper nicht.
- **Fehler:** `E-F07` (mittel; betrifft nur unvollständige Eingaben) Die von `xl_cashflow()` zwingend verwendete Spalte `Limit` (`R/reinsurance.R:300`, dokumentiert in `R/data.R:233`) fehlt in `structure_list` (Zeile 551-558). Ein Datensatz ohne `Limit` gilt als gültig; in `xl_cashflow()` wird daraus `NULL * adj_factor`, d. h. ein leerer Limitvektor und damit ein falsches oder gar kein XL-Ergebnis. Beleg: `befunde/test-E-F07.R`.
- **Verdacht (unbelegt):** `Priority` und `Limit` werden nicht auf ≥ 0 geprüft (`Limit = 0` ist für Jahre ohne XL sinnvoll, negative Werte nicht). `Margin_type == "FIC"` erzwingt in `xl_cashflow()` Margin 0 (`R/reinsurance.R:67-68`), `reinsurance_ok()` verlangt das nicht. Die Prüfung „Base_year in den Indizes“ (Zeile 615-620) bildet nur `min(Base_year > 0, first_orig_year):last_orig_year`; ein einzelnes fehlendes Jahr zwischen zwei vorhandenen Base_years wird nicht erkannt.
- **Verbesserungen:** Die Strukturprüfung könnte Spalten mit `required = TRUE/FALSE` unterscheiden (z. B. `Limit` nur nötig, wenn ein XL verwendet wird) – das würde `E-F07` entschärfen, ohne Nutzer ohne XL zu blockieren.
- **Hinweise:** Mit der Korrektur `E-F07` bleibt `reinsurance_ok(reinsurance_xmpl, indices_xmpl, 1989, 2023)` weiterhin `TRUE` (im Test mitgeprüft).

### `mortality_ok()` — `R/data_checks.R:638-697`
- **Zweck:** Prüft die Sterbetafel (Gender/Age/Probability, keine Dubletten, lückenlose Altersbereiche, Wahrscheinlichkeiten im Wertebereich, Maximum 1 je Geschlecht).
- **Paperbezug:** 2.4.6/2.4.7, S. 16-17 und 3.2.3, S. 56 (Sterbetafel-Annahmen, Lebenserwartung) · **Erweiterung** · Das Paper setzt eine Sterbetafel voraus, fordert aber keine Prüfung; die Plausibilisierung ist Umsetzungshilfe.
- **Fehler:** `E-F06` (mittel; betrifft nur fehlerhafte Sterbetafeln) In Zeile 685 steht `df$Probabilty` statt `df$Probability`. `"Probabilty"` ist kein Präfix der Spalte `"Probability"`, `df$Probabilty` ist daher `NULL`, `any(NULL < 0 | NULL > 1)` ist `FALSE` – die Wertebereichsprüfung läuft nie. Sterbewahrscheinlichkeiten < 0 oder > 1 werden akzeptiert, solange das Maximum je Geschlecht 1 ist, und laufen bis in `roll_out_annuity()` (negative/übergroße Überlebenswahrscheinlichkeiten). Beleg: `befunde/test-E-F06.R`.
- **Verdacht (unbelegt):** Die Maximum-Prüfung `max(f) * max(m) == 1` (Zeile 691) ist ein Fließkommavergleich und prüft nur das Produkt, nicht dass beide Maxima 1 sind (z. B. 0.5 · 2 = 1). Sie sagt außerdem nichts über Monotonie oder darüber, dass das Maximum am höchsten Alter steht. Bei einem Dataframe ohne eines der beiden Geschlechter liefert `min(integer(0))` `Inf` (Zeile 674-677) und die Bereichsprüfung erzeugt eine Warnung bzw. einen Fehler.
- **Verbesserungen:** Die Bereichsprüfung ließe sich für beide Geschlechter gemeinsam formulieren (Muster wie beim Verbesserungsvorschlag zu `age_shift_ok()`); der Fließkommavergleich sollte durch `isTRUE(all.equal(...))` bzw. `max(...) == 1` je Geschlecht ersetzt werden.
- **Hinweise:** Die Prüfung der lückenlosen Altersbereiche (Zeile 678-682) ist korrekt und deckt den in `R/data.R:194` genannten Bereich -10 bis 121 ab.

### `age_shift_ok()` — `R/data_checks.R:712-760`
- **Zweck:** Prüft den Altersverschiebungs-Dataframe (Gender/Birth_year/Age_shift, keine Dubletten, lückenlose Geburtsjahrgänge, Geschlechter).
- **Paperbezug:** 2.4.6, S. 16-17 und 3.2.3, S. 56 · **Erweiterung** · Wie `mortality_ok()`: Das Paper verlangt biometrische Annahmen, keine Prüfroutine.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** `Age_shift` wird nicht auf Plausibilität geprüft (die Doku in `R/data.R:188` und `R/data.R:204-206` erlaubt negative technische Alter, ein Verschiebungswert außerhalb des Sterbetafelbereichs wird aber nicht abgefangen). Bei fehlendem Geschlecht gilt dieselbe `Inf`-Problematik wie in `mortality_ok()` (Zeile 748-751). Es wird nicht geprüft, ob für alle in `active_annuities`/`pool_of_annuities` vorkommenden Geburtsjahrgänge ein Eintrag existiert – das wäre nur mit Übergabe dieser Dataframes möglich und ist derzeit Aufgabe des Nutzers.
- **Verbesserungen:** Die vier `min`/`max`-Zeilen und der Doppelblock (Zeile 748-757) sind ein Duplikat-Muster aus `mortality_ok()`; eine gemeinsame Hilfsfunktion `gaps_ok(values, gender)` würde beide Funktionen verkürzen.
- **Hinweise:** Die Struktur- und Dublettenprüfung ist identisch aufgebaut wie in `mortality_ok()`.

### Datendokumentation — `R/data.R:1-313`
- **Zweck:** Roxygen-Dokumentation der 16 Beispieldatensätze (Schadendaten, Renten, Indizes, Sterbetafel, Altersverschiebung, Rückversicherung, Ergebnismatrizen, Exposure).
- **Paperbezug:** nicht im Paper · **nicht im Paper** · Die Datensätze illustrieren das Verfahren; das Paper nennt nur die Datenarten (S. 9).
- **Fehler:** keine belegbaren (Dokumentationstext ist nicht testbar).
- **Verdacht (unbelegt):**
  - Zeile 14 und Zeile 36 beschreiben `Cl_reserve` als „Claim payments without annuities“; es sind die HGB-Reserven (`claims_data_ok()` und `generate_triangle()` verwenden die Spalte als Reserve, `R/aggregate_large_claims_results.R:111-114`).
  - Zeile 160 nennt für `indices_xmpl` 286 Zeilen und 4 Spalten. Der in Zeile 169-180 dokumentierte Erzeugungscode (`expand_historic_indices()` ab dem Minimum der historischen Reihe plus 250 Zukunftshahre, `R/data_functions.R:47`) ergibt mit den in Zeile 307 dokumentierten 64 Zeilen (1960-2023) 314 Zeilen; 286 passt zu keiner der beiden Angaben. Entweder ist die Zeilenzahl oder der Erzeugungscode falsch.
  - Zeile 111 und Zeile 310 schließen den `\item{Index_re}{…}`-Block mit einer zusätzlichen Klammer (`programs.}}`), was die Rd-Struktur von `\describe{}` verletzt.
- **Verdacht (unbelegt, Konsistenz):** Die Spaltenlisten stimmen mit den Funktionen überein: `claims_data_ok()` (Zeile 277-285) = 7 Spalten der Schadendaten (Zeile 9-17/31-39), `active_annuities_ok()`/`pool_of_annuities_ok()` = 11 Spalten der Renten (Zeile 54-66/108-120), `mortality_ok()` = 3 (Zeile 192-196), `age_shift_ok()` = 3 (Zeile 211-215), `reinsurance_ok()` + `xl_cashflow()` = 7 inkl. `Limit` (Zeile 230-238), `exposure_ok()` = 2 (Zeile 291-294), `indices_ok()` + `add_transition_factor()` = 4 inkl. `Transition_factor` (Zeile 162-167). Die Matrixdimensionen 35 × 35 (Zeile 248/258/268/278) passen zum Beispiel in der Funktionsdoku von `add_sicr_worksheet()` (`R/Excel_Output.R:17-21`: `cbind(all_claims_paid_xmpl, matrix(0, 35, 250))`), und die Vignette übergibt diese Matrizen unverändert an die Excel-Funktionen (`vignettes/sicr.Rmd:736-762`). `mortality_xmpl` mit 264 Zeilen = 2 × 132 Altersstufen (-10 bis 121, Zeile 194) ist in sich konsistent; `age_shift_xmpl` mit 228 Zeilen = 2 × 114 Geburtsjahrgänge ist plausibel, aber nicht nachrechenbar. Die Zeilenzahlen 995 (Zeile 8) und 49000 (Zeile 30) lassen sich ohne die Datenobjekte (nicht Teil des Quellcodes) nicht prüfen.
- **Verbesserungen:** `indices_xmpl` sollte entweder mit `@source`-Code erzeugt werden, der die dokumentierte Zeilenzahl reproduziert, oder die Zeilenzahl sollte aus dem Datensatz aktualisiert werden; die beiden `Cl_reserve`-Beschreibungen und die überzähligen Klammern sind zu korrigieren.
- **Hinweise:** `minimal_claims_data_xmpl` (Zeile 8) und `claims_data_xmpl` (Zeile 30) dokumentieren 7 Spalten, obwohl `prepare_data()` zusätzlich die abgeleitete Spalte `Dev_year_since_large` erzeugt – das ist korrekt, weil die Beispieldaten diese Spalte nicht enthalten (`vignettes/sicr.Rmd:388-400`).

## Befundliste

| ID | Funktion | Art | Schwere/Ziel | Kurzbeschreibung | Beleg |
|---|---|---|---|---|---|
| E-F01 | `aggregate_large_claims_results()` | Fehler | hoch | XL-Anteil der IBNR-Zeilen fehlt in `large_ceded_xl_payments`; Netto zu hoch (S. 55). Auf den Beispieldaten 0,0 %; mit Priorität 500.000 zediertes XL −7,04 %, Netto +2,91 % (n = 1) | `befunde/test-E-F01.R` |
| E-F02 | `aggregate_large_claims_results()` | Fehler | hoch | Quotenabgabe über Zeilenposition statt `match(Origin_year)`; unsortierte RV-Jahre ergeben falsche Quoten | `befunde/test-E-F02.R` |
| E-F03 | `aggregate_large_claims_results()` | Fehler | mittel | `1:NROW()` bei leerer Schadenliste → abstrakter Abbruch statt Nullmatrizen | `befunde/test-E-F03.R` |
| E-F04 | `indices_ok()` | Fehler | mittel | Struktur (`Index_re`, Typen) wird nie geprüft, `check_dataframe_structure()` fehlt | `befunde/test-E-F04.R` |
| E-F05 | `indices_ok()` | Fehler | niedrig | `NULL` → Rückgabe `"FALSE"` (Character) statt logischem `FALSE`; Rückgabevertrag verletzt | `befunde/test-E-F05.R` |
| E-F06 | `mortality_ok()` | Fehler | mittel | Tippfehler `df$Probabilty` legt die Wertebereichsprüfung der Sterbewahrscheinlichkeiten lahm | `befunde/test-E-F06.R` |
| E-F07 | `reinsurance_ok()` | Fehler | mittel | Spalte `Limit` fehlt in `structure_list`, obwohl `xl_cashflow()` sie zwingend braucht | `befunde/test-E-F07.R` |
| E-F08 | `add_sicr_worksheet()` | Fehler | niedrig | globale Option `openxlsx2.string_nums` wird gesetzt und nicht zurückgesetzt | `befunde/test-E-F08.R` |
| E-V01 | `indices_ok()` | Verbesserung | kürzer/effizienter | `is.unsorted()` statt Sortieren + elementweiser Vergleich | `verbesserungen/E-V01.R`, `tests/verbesserungen/test-E-V01.R`, `bench/E-V01.R` |
| E-V02 | `exposure_ok()` | Verbesserung | kürzer/lesbarer | frühe Rückgaben statt `p`-Flag | `verbesserungen/E-V02.R`, `tests/verbesserungen/test-E-V02.R` |
