# Gruppe D: renten_basisschaeden

Dateien: `R/annuity_functions.R` (367 Zeilen), `R/small_claims.R` (626 Zeilen), `R/small_claims_future_annuities.R` (342 Zeilen) · Funktionen: 16

## Überblick
R/annuity_functions.R setzt die anerkannten Renten (2.4.6) und die zukünftigen Verrentungen aus Pools (2.4.7) um: getrennte Matrizen für vereinbarte Zahlungen und Sterblichkeit, danach deterministische oder stochastische Abwicklung mit zufälligem Sterbejahr. R/small_claims.R enthält die deterministische Basisschadenreservierung (Chain-Ladder, Pattern, Tail, Best Estimate, Cashflow) sowie die Zusammenführung in `compute_small_claims()` (2.3.1). R/small_claims_future_annuities.R schätzt den künftigen Rentenanteil der Basisschäden additiv über historische Anerkennungen und eine Durchschnittsrente (2.3.2). Die Rentenlogik ist im Kern paperkonform; gefunden wurden ein um ein Lebensjahr zu junges Sterbealter bei bekannten Renten (D-F01), zwei Fehler im Rückversicherungszweig von `compute_small_claims()` (D-F02, D-F03), drei Ein-Jahres-/Randfallabstürze (D-F04, D-F05, D-F06) und eine Indexjahrabhängigkeit der künftigen Basisrenten (D-F07). Die Basisschadenmethodik selbst ist sauber umgesetzt; die wichtigsten Verbesserungen betreffen Vektorisierung (D-V01, D-V02).

## Funktionen

### `generate_annuity_payments()` — `R/annuity_functions.R:45-85`
- **Zweck:** Baut je Rente eine 130-Spalten-Matrix der vereinbarten (optional indexierten) Zahlungen ohne Sterblichkeit.
- **Paperbezug:** 2.4.6 S. 16–17 (vereinbarte Zahlungen), 2.4.7 S. 17 (fiktiver Rentencashflow), 2.1 S. 10 (Indexierung) · konform · Zahlungsbeginn/-ende und Dynamik werden vertragsgemäß abgebildet; die Besonderheit `future_annuities` (Eintrittsjahr mitzählen) ist eine dokumentierte Erweiterung für Poolziehungen.
- **Fehler:** keine gefunden. Die Zahlungsmatrix ist richtig ausgerichtet; der Altersversatz bei bekannten Renten liegt in `generate_annuity_probabilities()` (siehe D-F01).
- **Verdacht (unbelegt):** Bei `Dynamic <= -1` oder `Annuity_end < Annuity_start` entstehen negative/ungültige Exponenten; die Datenchecks verbieten dies, die Funktion selbst prüft nicht.
- **Verbesserungen:** `D-V01` (effizienter) ersetzt die Zeilenschleife mit `tail()`/`length<-` durch eine Matrixkonstruktion über `outer()`; Code: `verbesserungen/D-V01.R`, Test: `tests/verbesserungen/test-D-V01.R`, Benchmark: `bench/D-V01.R` (Median 1,1 ms statt 4,8 ms). Gleichheit gilt für `cut_first >= 0`; für `Entering_year > Calendar_year` (von `active_annuities_ok()` nicht ausgeschlossen, `R/data_checks.R:117-127`) weichen Original und Fassung ab. Dieser Fall ist fachlich unzulässig und sollte in der Prüfung abgelehnt werden (Gegenprüfung).
- **Hinweise:** Der `@return`-Text sagt „dataframe“, tatsächlich wird eine Matrix zurückgegeben.

### `generate_annuity_probabilities()` — `R/annuity_functions.R:115-174`
- **Zweck:** Erzeugt je Rente die kumulierten Sterbewahrscheinlichkeiten aus Sterbetafel und Altersshift.
- **Paperbezug:** 2.4.6 S. 16–17 (Überlebenswahrscheinlichkeiten), 2.3.2 S. 13 (fiktiver Cashflow Mann/Frau) · konform · die erste Spalte ist 0, weil am Jahresanfang in Vorauszahlung geleistet wird (Kommentar Z. 162–172).
- **Fehler:** `D-F01` (mittel) Für bekannte Renten ist die Sterbetafel um ein Lebensjahr zu jung angesetzt. `generate_annuity_payments()` legt Spalte 1 auf `Calendar_year + 1` (Z. 57). Die vorschüssige Zahlung zu Beginn von Cy+1 wird richtig mit Überlebenswahrscheinlichkeit 1 bewertet, denn die Rente ist zum Stichtag aktiv. Für jede weitere Zahlung muss der Rentner ein Kalenderjahr Cy+k überleben, in dem er das Alter x+k erreicht (x = Cy − Birth_year); `generate_annuity_probabilities()` kumuliert aber ab q(x) (Z. 161, Alter aus Z. 172) statt ab q(x+1). Für künftige Renten aus dem Pool (Spalte 1 = Eintrittsjahr) ist dieselbe Ausrichtung richtig, die beiden Zweige sind also untereinander inkonsistent. Wirkung auf `active_annuities_xmpl` mit `mortality_xmpl`/`age_shift_xmpl`: undiskontierte Best-Estimate-Zahlungen +1,86 % (9 239 437 statt 9 070 927), also systematisch und vorsichtig. Die Einstufung hängt an der Alterskonvention: Liest man `Calendar_year - Birth_year` als Alter am Stichtag (vollendete Jahre), ist q(x) für das Folgejahr vertretbar. Unter der Jahrgangsmethode der DAV-Tafeln (Alter = Kalenderjahr − Geburtsjahr) und nach der Konvention des Pool-Pfads im selben Paket ist q(x+1) richtig. Deshalb mittel statt hoch. Betroffen sind `roll_out_annuity(..., "end_of_probs")` (kleine bekannte Renten, Sonderschäden) und `roll_out_annuity(..., "random_death_year")` über `roll_out_active_annuities()` (Großschäden). Beleg: `befunde/test-D-F01.R` (q50 = 1, sonst 0: sicr bewertet die Zahlung 2025 mit 0, richtig wären 1000); Korrektur: `generate_annuity_probabilities_v()` in `verbesserungen/D-F01.R`.
- **Verdacht (unbelegt):** Für technische Alter > 121 wird `Age %in% (age:121)` zu einer absteigenden Sequenz und liefert nur Alter 121; für sehr junge versicherte Alter kann die 130-Jahres-Kappung die Überlebenswahrscheinlichkeit unterschätzen.
- **Verbesserungen:** keine separate Datei (Korrektur ist D-F01).
- **Hinweise:** Der `@return`-Text sagt „dataframe“, zurückgegeben wird eine Matrix.

### `roll_out_annuity()` — `R/annuity_functions.R:209-230`
- **Zweck:** Wickelt eine Rentenmatrix stochastisch (zufälliges Sterbejahr) oder deterministisch (Multiplikation mit Überlebenswahrscheinlichkeiten) ab.
- **Paperbezug:** 2.4.6 S. 17 („jedem Rentenempfänger … ein zufälliges Sterbejahr“; volle Zahlung bis dahin, danach 0) · konform für die stochastische Variante; die deterministische Variante ist die für Basisschäden in 2.3.2 S. 13 vorgesehene Form (Erweiterung).
- **Fehler:** `D-F01` wirkt hier (die Sterbewahrscheinlichkeiten bekannter Renten sind um ein Lebensjahr zu jung); die Abwicklungslogik selbst (`max.col(..., ties.method = "first")`, Z. 215–217) ist korrekt, weil `probs` kumulierte Sterbewahrscheinlichkeiten sind.
- **Verdacht (unbelegt):** Erreicht `probs` in 130 Jahren nie 1 (sehr junge technische Alter), liefert der Matrix-Zweig `max.col` = 1 und damit keine Zahlung; der Vektor-Zweig liefert wegen `which.max(...) == integer(0)` sogar `numeric(0)` (Z. 219). Der Vektor-Zweig ist zudem ungeschützt, wenn `payments`/`probs` keine 130 Elemente haben.
- **Verbesserungen:** keine separate Datei.
- **Hinweise:** Bei `stop.at = NULL` oder Vektor der Länge > 1 ist die Fehlermeldung aus `if (stop.at == ...)` irreführend; die Prüfung Z. 227 kommt zu spät.

### `roll_out_active_annuities()` — `R/annuity_functions.R:277-302`
- **Zweck:** Summiert die abgewickelten aktiven Renten je Schaden und ordnet sie der Großschadenliste zu.
- **Paperbezug:** 2.4.6 S. 16–17 · konform · Aggregation mehrerer Renten je Schaden über `rowsum()` und Zuordnung über `match()` (Z. 288–293).
- **Fehler:** keine eigenen gefunden; über D-F01 sind die Überlebenswahrscheinlichkeiten bekannter Renten leicht zu hoch, weil sie aus `generate_annuity_probabilities()` stammen.
- **Verbesserungen:** keine.
- **Hinweise:** Ist genau eine der beiden Matrizen `NULL`, wird stillschweigend eine Nullmatrix geliefert (Z. 283–285); das kann einen Aufruffehler verdecken.

### `generate_annuities_prediction()` — `R/annuity_functions.R:341-366`
- **Zweck:** Aggregiert abgewickelte Einzelrenten je Anfalljahr zu einer Prognosematrix.
- **Paperbezug:** 2.3.1/2.3.2 S. 13 · nicht im Paper (Hilfsfunktion zur Aggregation).
- **Fehler:** keine gefunden. Die Addition `c(annuities_rolled_out[i, ], rep(0, 120))` (Z. 359) passt zu 130 Zahlungsspalten und 250 Prognosespalten.
- **Verdacht (unbelegt):** Bei einem Vektor (nicht Matrix) als `annuities_rolled_out` würde `[i, ]` falsch indizieren; im Paketpfad liefert `generate_annuity_payments()` immer eine Matrix, daher nur bei direktem Aufruf relevant. Bei mehreren Zeilen je `Claim_id` wird für alle Zeilen das erste Anfalljahr verwendet (Z. 353).
- **Verbesserungen:** keine.

### `cl_factor()` — `R/small_claims.R:17-46`
- **Zweck:** Chain-Ladder-Faktor eines Abwicklungsjahres, optional nur über die neuesten Anfalljahre.
- **Paperbezug:** 2.3.1 S. 13 („übliche Verfahren der Schadenreservierung“), eigener Prüfpunkt D.7 · konform · die Zeilenauswahl `last_row <- rows_count - dev_year`, `first_row <- max(1, last_row - volume + 1)` (Z. 39–40) entspricht dem oberen linken Dreieck und „neueste Kalenderjahre“.
- **Fehler:** keine gefunden. `dev_year >= n` bzw. `colsum_before == 0` werden mit Warnung und Faktor 1 abgefangen (Z. 22–25, 44–46).
- **Verdacht (unbelegt):** Die Prüfung `rows_count < columns_count` (Z. 28) kommt erst nach der `dev_year >= n`-Warnung; bei `dev_year >= nrow` und mehr Spalten als Zeilen wird deshalb nicht der vorgesehene `stop()` erreicht. `dev_year = NA` führt zu einem unklaren Fehler.
- **Verbesserungen:** keine.

### `generate_pattern()` — `R/small_claims.R:69-95`
- **Zweck:** Erzeugt das Abwicklungsmuster aus Chain-Ladder-Faktoren und mischt optional ein externes Tail-Muster ein.
- **Paperbezug:** 2.3.1 S. 13; Tail/Muster als übliches Reserving-Werkzeug · konform, externes Muster ist eine Erweiterung.
- **Fehler:** `D-F04` (mittel) Ein einspaltiges Dreieck (nur ein Abwicklungsjahr) bricht ab. `rep(1, ndim0 - 1)` ist dann leer, die Schleife `for (dev_year in (1:(ndim0 - 1)))` läuft aber über `1:0 = c(1, 0)` (Z. 81–83). `cl_factor(., 0)` wirft „dev_year must be integer greater 0“, obwohl es keinen Entwicklungsfaktor gibt. Beleg: `befunde/test-D-F04.R`; Korrektur: `generate_pattern_v()` in `verbesserungen/D-F04.R`.
- **Verdacht (unbelegt):** Ist `external_pattern` kürzer als das interne Muster, wird `pattern[min(ndim0, int2ext_transition):(ndim - 1)]` bei `ndim < ndim0` zu einer rückwärts laufenden Indexfolge und kann Werte an falsche Stellen schreiben (Z. 87–90). Ein `int2ext_transition < 1` wird nicht abgefangen (Z. 85).
- **Verbesserungen:** D-F04 behebt zugleich die `int2ext_transition < 1`-Lücke.
- **Hinweise:** keine.

### `fill_up_triangle()` — `R/small_claims.R:114-146`
- **Zweck:** Füllt das untere rechte Dreieck mit einem Entwicklungsmuster auf.
- **Paperbezug:** 2.3.1 S. 13 · nicht im Paper (Hilfsfunktion der deterministischen Abwicklung).
- **Fehler:** `D-F05` (mittel) Ein einspaltiges Dreieck bricht ab. Die Pretail-Schleife `for (aj in (1:(ndim0 - 1)))` läuft über `1:0` (Z. 132). Für `aj = 1` wird bei `ndim == ndim0` die nicht vorhandene Spalte 2 adressiert, für `aj = 0` die Zeile `n_row + 1`; Ergebnis ist „subscript out of bounds“. Beleg: `befunde/test-D-F05.R`; Korrektur: `fill_up_triangle_v()` in `verbesserungen/D-F05.R`.
- **Verdacht (unbelegt):** Ein kürzeres `pattern` als `ndim0 - 1` führt zu `NA`-Werten (Z. 132–136); eine Längenprüfung fehlt.
- **Verbesserungen:** keine über die Korrektur hinaus.

### `result2best_estimate()` — `R/small_claims.R:164-171`
- **Zweck:** Zieht die kumulierten Zahlungen vom Ultimate ab und liefert den Best Estimate je Anfalljahr.
- **Paperbezug:** 2.3.1 S. 13 · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden. `diag(paid[, nrow(paid):1])` (Z. 170) liest die beobachtete Diagonale korrekt, wenn `paid` das quadratische Abwicklungsdreieck ist.
- **Verdacht (unbelegt):** Ein Vektor als `paid` besteht die `NROW`-Prüfung, scheitert aber an `paid[, ...]`; bei `ncol(paid) < nrow(paid)` ist der Spaltenzugriff fehlerhaft. Beides ist außerhalb des Paketpfads.
- **Verbesserungen:** keine.

### `merge_results()` — `R/small_claims.R:193-210`
- **Zweck:** Gewichtetes Mittel aus Paid- und Incurred-Ultimate.
- **Paperbezug:** 2.3.1 S. 13 · Erweiterung (die Wahl zwischen Zahlungs- und Aufwandsdreieck ist im Paper als übliches Verfahren angelegt).
- **Fehler:** keine gefunden; Längenprüfungen Z. 199–207 sind vorhanden.
- **Verdacht (unbelegt):** Sind beide Gewichte einer Zeile 0, entsteht `NaN` statt einer Fehlermeldung (Z. 209–210); negative Gewichte werden nicht abgefangen.
- **Verbesserungen:** keine.

### `settlement_rates()` — `R/small_claims.R:221-223`
- **Zweck:** Wandelt Entwicklungsfaktoren in kumulierte Zahlungsanteile je Abwicklungsjahr um.
- **Paperbezug:** 2.3.1 S. 13 · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden. `c(rev(cumprod(rev(1/pattern))), 1)` liefert die kumulierten Paid-Anteile einschließlich 1 am Ende.
- **Verdacht (unbelegt):** Pattern-Werte 0 oder negativ erzeugen `Inf`/negative Anteile; die Datenprüfung erfolgt nicht hier.
- **Verbesserungen:** keine.

### `rollout_best_estimate()` — `R/small_claims.R:237-266`
- **Zweck:** Verteilt einen Best Estimate mit dem Zahlungsmuster auf die Folgejahre (maximal 250 Jahre).
- **Paperbezug:** 2.3.1 S. 13 · nicht im Paper (Hilfsfunktion der deterministischen Abwicklung).
- **Fehler:** keine gefunden. Die Fälle `dev_year` ungültig (Z. 243–247), `dev_year` jenseits des Patterns (Z. 249–251) und `1 - settle_rate == 0` (Z. 257–261) werden sauber abgefangen.
- **Verdacht (unbelegt):** Bei einem Pattern mit mehr als 249 Einträgen kann `cashflow[1:(pattern_length - dev_year)]` über 250 hinauswachsen; ein `pattern = NULL` wird nur zufällig sinnvoll behandelt.
- **Verbesserungen:** `D-V02` (effizienter) berechnet `settlement_rates()` und `cum2inc()` nur einmal statt je Element und nutzt `vapply()`; Code: `verbesserungen/D-V02.R`, Test: `tests/verbesserungen/test-D-V02.R`, Benchmark: `bench/D-V02.R`.
- **Hinweise:** `Vectorize()` verliert bzw. recycelt Namen; im Paketpfad ohne Bedeutung.

### `best_estimate2cashflow()` — `R/small_claims.R:281-288`
- **Zweck:** Wandelt einen Best-Estimate-Vektor je Anfalljahr in eine Prognosematrix mit 250 Kalenderjahren.
- **Paperbezug:** 2.3.1 S. 13 · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden. `dev_year = NROW(best_estimate):1` (Z. 284) passt zur Sortierung „ältestes Anfalljahr zuerst“; Row-/Colnames (Z. 285–286) sind konsistent.
- **Verdacht (unbelegt):** Die Funktion setzt implizit voraus, dass die Anzahl der Anfalljahre gleich der Anzahl beobachteter Abwicklungsjahre ist und `best_estimate` bereits nach Anfalljahr sortiert ist; eine Prüfung fehlt. Für `NROW(best_estimate) = 0` ist das Verhalten ungeklärt.
- **Verbesserungen:** keine separate Datei (profitiert von D-V02).

### `compute_small_claims()` — `R/small_claims.R:444-624`
- **Zweck:** Berechnet in einem Schritt Zahlungen, Reserven, bekannte und künftige Renten sowie Quota-Share-Rückversicherung der Basisschäden.
- **Paperbezug:** 2.3.1 S. 13 (deterministische Dreiecke), 2.3.2 S. 13 (bekannte Renten deterministisch, künftige additiv), 2.4.6/2.4.7 S. 16–17 · konform · die Schritte 1–3 (Z. 488–605) folgen dem Bericht; die bekannten kleinen Renten werden mit `stop.at = "end_of_probs"` deterministisch abgewickelt (Z. 567–573).
- **Fehler:** `D-F02` (mittel) `if (!is.null("reinsurance"))` (Z. 609) ist immer wahr, weil `"reinsurance"` ein Zeichenvektor ist. Bei `reinsurance = NULL` wird die Summe mit `NULL` multipliziert; `small_ceded_quota_payments` ist dann ein leerer Vektor statt der dokumentierten Nullmatrix (Z. 610–613, Rückgabe Z. 622). Beleg: `befunde/test-D-F02.R`; Korrektur: `compute_small_claims_v()` in `verbesserungen/D-F02.R`. `D-F03` (hoch) Die Quota wird über `reinsurance$Quota_share[reinsurance$Origin_year %in% first:last]` (Z. 613) positionsabhängig zugeordnet. Bei nicht nach `Origin_year` sortierten RV-Daten erhält das falsche Anfalljahr die Quote; `reinsurance_ok()` prüft die Reihenfolge nicht. Zusätzliche Jahre außerhalb des Bereichs schaden nicht (`%in%` filtert sie heraus); fehlen Jahre im Bereich, wird der kürzere Vektor recycelt, was im `sicr()`-Pfad `reinsurance_ok()` verhindert (`R/data_checks.R:582-586`). Beleg: `befunde/test-D-F03.R`; Korrektur: `compute_small_claims_v()` in `verbesserungen/D-F03.R`.
- **Verdacht (unbelegt):** Die Schritt-2-Kommentare („step 2“ doppelt, Z. 559 und 571) und die deutschen Kommentare Z. 554–555 sind reine Doku; inhaltlich unkritisch. `small_claims_reserved` kann durch die Subtraktion negativ werden, ohne dass dies geprüft wird.
- **Verbesserungen:** keine über D-F02/D-F03 hinaus.

### `generate_small_claims_annuities_parameters()` — `R/small_claims_future_annuities.R:94-192`
- **Zweck:** Leitet additive Faktoren (Anerkennungen je Abwicklungsjahr relativ zum Reservenvolumen) und die mittlere kleine Rente ab.
- **Paperbezug:** 2.3.2 S. 13 (additives Verfahren, Durchschnittsrente aus Mann/Frau) · überwiegend konform, in der konkreten Mittelung abweichend (Variante) · die Anzahl wird additiv aus historischen Anerkennungen und einer Bestandsgröße gebildet (Z. 152–178), die Durchschnittsrente wird aus den individuellen Cashflows der historischen Anerkennungen gemittelt (Z. 180–187) statt aus einem männlichen und einem weiblichen fiktiven Cashflow. Das ist eine zulässige Variante, weil die individuellen Alter/Geschlechter und die Indexierung direkt eingehen.
- **Fehler:** `D-F07` (hoch) wird hier vorbereitet: Die Reserven werden vom Anfalljahr auf das Indexjahr indexiert (Z. 167–170), die Faktoren enthalten dadurch `I(Index)/I(Anfalljahr)`. In `generate_small_claims_future_annuities()` wird die Anwendung aber mit dem rohen Reservenvolumen und einer Indexierung vom Indexjahr in die Zukunft kombiniert, sodass ein Faktor `I(Anfalljahr)/I(Indexjahr)` übrig bleibt. Beleg und Korrektur siehe dort (`befunde/test-D-F07.R`, `verbesserungen/D-F07.R`).
- **Verdacht (unbelegt):** Ein fehlendes `attr(indices, "index_year")` führt nicht zu einer klaren Meldung, sondern zu einem leeren `reserved` und damit zu undefinierten Faktoren. Mehrere Renten desselben Schadens im selben Jahr werden als mehrere Anerkennungen gezählt (Z. 156–162), obwohl das Paper Anerkennungen zählt; bei den Beispieldaten unkritisch.
- **Verbesserungen:** keine separate Datei; die verschachtelte Doppelschleife Z. 156–162 ist quadratisch und ließe sich durch `table()` ersetzen (Hinweis, nicht als D-V-Datei ausgearbeitet).
- **Hinweise:** `small_claims_reserved` muss Integer-Rownames besitzen; `as.integer(rownames(...))` (Z. 121–122) ist ungeschützt.

### `generate_small_claims_future_annuities()` — `R/small_claims_future_annuities.R:287-338`
- **Zweck:** Multipliziert die erwarteten künftigen Anerkennungszahlen mit der Durchschnittsrente und erzeugt die Prognosematrix.
- **Paperbezug:** 2.3.2 S. 13 („Anzahl … mit dem Cashflow einer Durchschnittsrente multipliziert“, nicht-ganze Anzahlen) · konform bis auf D-F07.
- **Fehler:** `D-F06` (mittel) Bei nur einem Anfalljahr bricht die Funktion mit „subscript out of bounds“ ab: `small_future_annuities_count[, 2:dev_years_count]` ist `[, 2:1]` (Z. 307), und die Schleife `for (current_row in 2:years_count)` läuft über `2:1` (Z. 320). Beleg: `befunde/test-D-F06.R`; Korrektur: `generate_small_claims_future_annuities_v()` in `verbesserungen/D-F06 (bricht mit verständlicher Meldung ab; eine Nullprognose wäre still zu niedrig).R`. `D-F07` (hoch) Das Ergebnis hängt vom willkürlich wählbaren Indexjahr ab: Die erwarteten Anzahlen werden einheitlich vom Indexjahr in das Zukunftsjahr indexiert (Z. 311–315), die Faktoren stammen aber aus auf das Indexjahr indexierten Reserven. Im konstruierten Beispiel mit konstanter Inflation 2 % ist das Ergebnis für Indexjahr 2021 genau 1/1.02-mal das Ergebnis für Indexjahr 2020, obwohl Zahlungsstrom und Indexreihe identisch sind. Beleg: `befunde/test-D-F07.R`; Korrektur: `generate_small_claims_future_annuities_v()` in `verbesserungen/D-F07.R` (indexiert jede Zeile vom eigenen Anfalljahr in das Zukunftsjahr, fängt zugleich einspaltige Eingaben und externe Faktorvektoren ab).
- **Verdacht (unbelegt):** `dev_years_count` (Länge der Faktoren) wird als Spaltenzahl der quadratischen Reservedreiecksmatrix verwendet (Z. 301, 307); bei externen Faktoren anderer Länge ist der Zugriff falsch. Die Korrektur D-F07 fängt dies ab.
- **Verbesserungen:** Die korrigierte Funktion D-F07 ersetzt zugleich die verschachtelten Ergebnis-Schleifen Z. 327–335 durch eine kompaktere, vektorisierte Variante.
- **Hinweise:** Der Kommentar „indexate to future years … mean annuity is not changed“ (Z. 310) beschreibt genau die problematische Indexierungsrichtung.

## Befundliste
| ID | Funktion | Art | Schwere/Ziel | Kurzbeschreibung | Beleg |
|---|---|---|---|---|---|
| D-F01 | `generate_annuity_probabilities()` | Fehler | mittel | Bekannte Renten: Sterblichkeit ab q(x) statt q(x+1), Reserve systematisch zu hoch (+1,9 % auf den Beispieldaten) | `befunde/test-D-F01.R`, `verbesserungen/D-F01.R` |
| D-F02 | `compute_small_claims()` | Fehler | mittel | `!is.null("reinsurance")` immer wahr; ohne RV-Programm leerer Vektor statt Nullmatrix | `befunde/test-D-F02.R`, `verbesserungen/D-F02.R` |
| D-F03 | `compute_small_claims()` | Fehler | hoch | Quota-Share positionsabhängig statt nach Anfalljahr; unsortierte RV-Daten ergeben falsche Quoten | `befunde/test-D-F03.R`, `verbesserungen/D-F03.R` |
| D-F04 | `generate_pattern()` | Fehler | mittel | Absturz bei einspaltigem Dreieck durch `1:0` und `cl_factor(., 0)` | `befunde/test-D-F04.R`, `verbesserungen/D-F04.R` |
| D-F05 | `fill_up_triangle()` | Fehler | mittel | Absturz bei einspaltigem Dreieck durch `1:0`-Pretail-Schleife | `befunde/test-D-F05.R`, `verbesserungen/D-F05.R` |
| D-F06 | `generate_small_claims_future_annuities()` | Fehler | mittel | Absturz bei nur einem Anfalljahr (`2:dev_years_count`, `2:years_count`) | `befunde/test-D-F06.R`, `verbesserungen/D-F06.R` |
| D-F07 | `generate_small_claims_annuities_parameters()` / `generate_small_claims_future_annuities()` | Fehler | hoch | Ergebnis der künftigen Basisrenten hängt vom Indexjahr ab (Faktor `I(Anfalljahr)/I(Indexjahr)`) | `befunde/test-D-F07.R`, `verbesserungen/D-F07.R` |
| D-V01 | `generate_annuity_payments()` | Verbesserung | effizienter | Zeilenschleife durch Matrixkonstruktion ersetzt | `verbesserungen/D-V01.R`, `tests/verbesserungen/test-D-V01.R`, `bench/D-V01.R` |
| D-V02 | `rollout_best_estimate()` | Verbesserung | effizienter | `settlement_rates()`/`cum2inc()` nur einmal, `vapply()` statt wiederholter Vorberechnung | `verbesserungen/D-V02.R`, `tests/verbesserungen/test-D-V02.R`, `bench/D-V02.R` |
