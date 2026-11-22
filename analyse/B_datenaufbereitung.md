# Gruppe B: Datenaufbereitung

Dateien: `R/data_functions.R` (758 Zeilen), `R/basic.R` (515 Zeilen) · Funktionen: 28

## Überblick
Die beiden Dateien enthalten die Datenaufbereitung für die stochastische Einzelschadenreservierung: Indexierung von Zahlungen, Reserven und Grenzen (2.1), die Trennung in Basis- und Großschäden nach Methode 3 einschließlich der Zahlung im Jahr des Großwerdens (2.2), die exakte Bestimmung des Großwerdens sowie der Abwicklungsjahre und Reserveklassen (2.4.1, 2.4.2) und zahlreiche Hilfsfunktionen für Cashflow- und Dreiecksmatrizen. Insgesamt ist die Umsetzung des UAG-Standards gut erkennbar: Die Indexierung erfolgt auf ein konstantes Indexjahr, die Trennung verwendet durchgehend Methode 3, und die Zahlung im Jahr des Großwerdens verbleibt durch `Dev_year_since_large >= 1` im Großschadenteil. Die größten Schwächen liegen weniger in der Reservierungslogik als in der robusten Behandlung von Indexreihen und leeren Dreiecken: `expand_historic_indices()` verarbeitet die historische Indexreihe positionsbasiert, und zwei Dreiecks-Hilfsfunktionen brechen bei leeren Eingaben ab. Kritische Fehler in der Reserve- oder Verteilungslogik wurden nicht gefunden.

## Funktionen

### `expand_historic_indices()` — `R/data_functions.R:34-50`
- **Zweck:** Erweitert eine historische Indexreihe um 250 zukünftige Kalenderjahre und ergänzt bei Bedarf `Index_re = 0`.
- **Paperbezug:** 2.1 Indexierung, S. 10 · nicht im Paper (Hilfsfunktion) · Unterstützt die dort geforderte Indexreihe und die Prognose zukünftiger Indizes; die Funktion selbst ist nicht explizit beschrieben.
- **Fehler:** `B-F01` (hoch) In Zeile 47 wird `Calendar_year` als lückenlose Folge `min:max+250` erzeugt, in Zeile 48 werden die `Index_gross`-Werte aber unverändert in Zeilenreihenfolge angehängt. Eine unsortierte `historic_indices`-Tabelle passiert `historic_indices_ok()` und führt zu still falsch zugeordneten Indizes; Lücken vor `first_orig_year` führen wegen unterschiedlicher Spaltenlängen zu einem kryptischen `data.frame`-Fehler. Beleg: `befunde/test-B-F01.R`.
- **Verdacht (unbelegt):** Die Notwendigkeit einer sortierten und lückenlosen Jahresreihe ist in der Dokumentation nicht klar genannt; `historic_indices_ok()` prüft nur die Vollständigkeit von `first_orig_year:last_orig_year`.
- **Verbesserungen:** `B-F01` Korrektur: `verbesserungen/B-F01.R` sortiert zuerst und prüft danach explizit auf Lücken.

### `add_transition_factor()` — `R/data_functions.R:77-82`
- **Zweck:** Ergänzt `Transition_factor` als Verhältnis der kumulierten Grossindizes zum gewählten Indexjahr.
- **Paperbezug:** 2.1 Indexierung, S. 10 · nicht im Paper (Hilfsfunktion) · Setzt das konstante Indexierungsjahr des UAG-Standards um; die Ratio-Bildung entspricht der Indexierung auf das Niveau des Indexjahres.
- **Fehler:** `B-F02` (mittel) In Zeile 79 wird der Nenner über `cumprod(...)[Calendar_year == index_year]` gebildet. Fehlt `index_year`, ist der Nenner `numeric(0)` und die Zuweisung bricht mit einer unklaren data.frame-Meldung ab; doppelte Kalenderjahre würden stillschweigend recycelt. Beleg: `befunde/test-B-F02.R`.
- **Verbesserungen:** `B-F02` Korrektur: `verbesserungen/B-F02.R` validiert ein einzelnes, enthaltenes und eindeutiges `index_year`.

### `generate_claims_list()` — `R/data_functions.R:116-133`
- **Zweck:** Reduziert die vorbereiteten Daten auf den Grossschadenstatus des letzten Kalenderjahres.
- **Paperbezug:** 2.4.1/2.4.2, S. 13–14 · nicht im Paper (Hilfsfunktion) · Stellt den Startzustand (Abwicklungsjahr seit Grosswerden und Reserveklasse) für die Simulation bereit.
- **Fehler:** keine gefunden.
- **Hinweise:** Der Filter `Origin_year >= first_orig_year` schließt Alt-Schäden mit Teilhistorie aus der Simulation aus. Das ist in der Dokumentation der Funktion so angelegt; für die Poolhistorie werden solche Schäden an anderer Stelle berücksichtigt.

### `reduce_data()` — `R/data_functions.R:156-187`
- **Zweck:** Vorauswahl möglicher Grossschäden anhand eines konservativ skalierten Grenzwerts.
- **Paperbezug:** 2.2 Trennung, S. 11 · nicht im Paper (Hilfsfunktion) · Die Vorauswahl ist konservativ, weil mit dem minimalen `Transition_factor` der in den Daten vorkommenden Jahre gearbeitet wird; ein später tatsächlich grosser Schaden kann dadurch nicht verloren gehen.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** In Zeile 167–168 wird `min()` ohne `na.rm` auf die zu den `Calendar_year`-Werten gematchten Faktoren angewendet. Enthält `claims_data` ein Kalenderjahr, das in `indices` fehlt, wird `minimal_threshold` zu `NA`; die Vorauswahl kann dann still leer werden. Wegen des nicht geprüften `data.table`-Verhaltens bei NA-Index ist dies nur ein Verdacht.
- **Hinweise:** Das Kappen negativer Reserven mit `pmax(0, ...)` in Zeile 175 macht die Vorauswahl nur grosszügiger und ist für die spätere exakte Prüfung unschädlich.

### `add_missing_years()` — `R/data_functions.R:212-236`
- **Zweck:** Ergänzt je Schaden alle Kalenderjahre von `Origin_year` bis `last_orig_year` und setzt fehlende Zahlungen/Reserven auf 0.
- **Paperbezug:** 2.4 Datenaufbereitung, S. 14 · nicht im Paper (Hilfsfunktion) · Bereitet die für Pools und Kumulation benötigte lückenlose Jahresreihe auf.
- **Fehler:** keine gefunden.
- **Hinweise:** Zeile 233 verwendet `arrange("Origin_year", ...)` mit Zeichenketten. Das ist mindestens missverständlich, weil dplyr Ausdrücke und keine Spaltennamen-Zeichenketten erwartet; für den Gesamtpfad ist es unkritisch, weil `add_columns()` erneut und korrekt sortiert. Für Alt-Schäden kann die Erweiterung ab `Origin_year` viele Nullzeilen erzeugen; das kostet Speicher, ist aber logisch konsistent zur späteren Fortschreibung.

### `add_columns()` — `R/data_functions.R:258-287`
- **Zweck:** Ergänzt Entwicklungsjahr, Summen, kumulierte Zahlungen, Incurred- und Entry-Reserve-Spalten.
- **Paperbezug:** 2.2/2.4.1, S. 11–14 · nicht im Paper (Hilfsfunktion) · Bildet die für Methode 3 und die Abwicklungszählung benötigten Zustandsgrössen.
- **Fehler:** keine gefunden.
- **Hinweise:** Die Entry-Reserve wird über `lag()` nach der Sortierung und Gruppierung gebildet; das ist im vorgesehenen Ablauf nach `add_missing_years()` korrekt, weil jede Schadenkette dann lückenlos ab `Origin_year` beginnt.

### `add_indexed_columns()` — `R/data_functions.R:312-349`
- **Zweck:** Indexiert Zahlungen und Reserven auf das Indexjahr und ergänzt indizierte Entry-Reserven und Kumulationen.
- **Paperbezug:** 2.1 Indexierung, S. 10 · konform · Zahlungen und Reserven werden mit derselben Grossindexreihe indiziert; das entspricht ausdrücklich der UAG-Empfehlung.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** `lag()` für die Entry-Reserven wird vor der Gruppierung nach `Claim_id` berechnet (Zeile 330–331). Im dokumentierten Ablauf mit sortierten, lückenlosen Daten ist das korrekt; bei direkt aufgerufener Funktion mit fehlenden Jahren oder unvollständiger Sortierung können Entry-Reserven über Schadengrenzen hinweg falsch gebildet werden.
- **Hinweise:** Für Zahlung oder Reserve exakt 0 wird unabhängig vom Indexfaktor 0 gesetzt; das ist fachlich unproblematisch.

### `filter_large_claims()` — `R/data_functions.R:378-419`
- **Zweck:** Bestimmt exakt, welche Schäden wann gross werden, und setzt `Large_since`, `Dev_year_of_growing_large` und `Dev_year_since_large`.
- **Paperbezug:** 2.2 Trennung und 2.4.1 Abwicklungsjahre, S. 11–14 · konform · Verwendet den indexierten Schadenaufwand und das erste Überschreiten der Schwelle; das Jahr des Grosswerdens wird als erstes Abwicklungsjahr seit Grosswerden gezählt. Methode 3 und die Zuordnung der Zahlung im Jahr des Grosswerdens zum Grossschaden werden eingehalten; die im Paper verworfenen Methoden 1/2 sind bewusst nicht implementiert.
- **Fehler:** keine gefunden.
- **Hinweise:** Die strenge Bedingung `Ind_incurred > threshold` entspricht dem Wortlaut „die Grossschadengrenze überschritten“; exakte Gleichheit macht den Schaden nicht gross. Für Schäden ohne volle Historie wird `Large_since` über `expected_year_of_growing_large` geschätzt, wie in 2.2/3.2.7 vorgesehen.

### `add_classes()` — `R/data_functions.R:447-456`
- **Zweck:** Ordnet Entry- und Exit-Reserve jeweils eine Reserveklasse zu.
- **Paperbezug:** 2.4.2 Reserveklassen, S. 14 · konform · Verwendet die indexierte HGB-Reserve und eine frei wählbare Klassengrenzenfolge; `findInterval()` bildet links geschlossene Intervalle `[a,b)`, wie in der Dokumentation beschrieben.
- **Fehler:** keine gefunden.
- **Hinweise:** Reserve 0 fällt bei der Beispielklasseneinteilung in Klasse 0; das passt zur internen Null-basierten Klassenverwendung in `generate_pools()`.

### `attach_future_annuities()` — `R/data_functions.R:493-551`
- **Zweck:** Hängt je Schaden und Kalenderjahr bis zu fünf Zeilenindizes neuer Renten aus `pool_of_annuities` an.
- **Paperbezug:** 2.4.7 Zukünftige Verrentungen, S. 17 · Erweiterung · Setzt die im Paper geforderte Erweiterung der Pools um Rentenmerkmale für die Simulation um; die Beschränkung auf fünf neue Renten pro Schaden und Jahr ist dokumentiert.
- **Fehler:** keine gefunden.
- **Hinweise:** Das Attribut `pool_of_annuities` enthält nach Zeile 535–549 die zusammengefasste Tabelle, während die `New_annuity_i`-Werte auf Zeilen der ursprünglichen Pool-Tabelle verweisen. Intern wird das Attribut nicht verwendet; irreführend ist es dennoch.

### `prepare_data()` — `R/data_functions.R:726-758`
- **Zweck:** Führt die sieben Aufbereitungsschritte in der vorgesehenen Reihenfolge aus.
- **Paperbezug:** 2.1–2.4.7, S. 10–17 · konform · Der UAG-Standard (konstantes Indexjahr, Methode 3, Zahlung im Jahr des Grosswerdens beim Grossschaden, indexierte Reserveklassen) wird als fester Ablauf umgesetzt.
- **Fehler:** keine gefunden.
- **Hinweise:** Die im Paper diskutierten Alternativen (Methoden 1/2, andere Zuordnung der Zahlung im Jahr des Grosswerdens) sind nicht per Parameter wählbar. Da das Paper Methode 3 und die Grossschadenzuordnung als UAG-Standard festhält, ist das für die Standardkonformität unproblematisch.

### `skeleton_triangle()` — `R/basic.R:14-21`
- **Zweck:** Erzeugt eine leere quadratische Historienmatrix mit Anfallsjahren als Zeilen- und Kalenderjahren als Spaltennamen.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.
- **Hinweise:** Für `first_orig_year > last_orig_year` entsteht eine negative Dimension und damit ein R-Fehler; der Parameterfall ist nicht dokumentiert.

### `skeleton_prediction()` — `R/basic.R:36-43`
- **Zweck:** Erzeugt eine leere Prognosematrix mit 250 zukünftigen Kalenderjahren.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.

### `cut2history()` — `R/basic.R:56-58`
- **Zweck:** Schneidet die ersten `n` Historien-Spalten aus einer Gesamtmatrix.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.
- **Hinweise:** Die Funktion setzt die in der Dokumentation geforderte Dimension `n × (n+250)` voraus.

### `cut2prediction()` — `R/basic.R:72-74`
- **Zweck:** Schneidet die 250 Prognose-Spalten aus einer Gesamtmatrix.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.

### `generate_triangle()` — `R/basic.R:102-141`
- **Zweck:** Aggregiert Einzelschadendaten zu einem Anfallsjahr-/Kalenderjahr-Dreieck und blendet bei Bedarf die Basis-Schadenhistorie aus.
- **Paperbezug:** 2.2 Trennung und 2.4.1, S. 11–14 · konform · Mit `include_small_claims = FALSE` werden alle Zeilen mit `Dev_year_since_large < 1` genullt; damit bleiben Zahlungen vor dem Grosswerden im Basisbereich, während die Zahlung und die Reserve im Jahr des Grosswerdens im Grossschadenbereich verbleiben. Das entspricht Methode 3 und dem UAG-Standard zur Zahlung im Jahr des Grosswerdens.
- **Fehler:** keine gefunden.
- **Verdacht (unbelegt):** Enthält `Dev_year_since_large` `NA`, so ist die logische Indexierung in Zeile 116 nicht sauber definiert; im Paketpfad wird die Spalte zuvor in `filter_large_claims()` berechnet, sodass dieser Fall dort nicht auftritt.
- **Hinweise:** Die Verwendung von `xtabs` mit `Origin_year + Calendar_year` ist korrekt als Formeloperator und nicht als arithmetische Addition zu lesen.

### `convert_single2dev_year_triangle()` — `R/basic.R:166-191`
- **Zweck:** Summiert einen Einzelschaden-Cashflow je Anfallsjahr zu einer Kalenderjahr-Matrix.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion) · Der Name ist irreführend, weil das Ergebnis noch ein Kalenderjahrdreieck ist; die eigentliche Umwandlung erfolgt mit `cal_year2dev_year()`.
- **Fehler:** keine gefunden.
- **Hinweise:** Anfallsjahre ausserhalb von `first_orig_year:last_orig_year` werden stillschweigend ignoriert; bei direkter Verwendung ohne vorherige Validierung kann das Daten verlieren.

### `convert_single2dev_year_prediction()` — `R/basic.R:215-240`
- **Zweck:** Summiert Einzelschaden-Prognosen je Anfallsjahr zu einer Prognosematrix.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.
- **Hinweise:** Wie oben werden Anfallsjahre ausserhalb des Rasters nicht gemeldet.

### `generate_history_per_claim()` — `R/basic.R:265-296`
- **Zweck:** Erzeugt aus langen Schadendaten eine Matrix mit einer Zeile je Schaden und einer Spalte je Kalenderjahr.
- **Paperbezug:** Hilfsfunktion für 2.1/2.6, nicht im Paper · nicht im Paper (Hilfsfunktion) · Stellt die Zahlungshistorie für Backtesting und Rückversicherungsrechnung bereit.
- **Fehler:** keine gefunden.
- **Hinweise:** Schäden mit `Origin_year < first_orig_year` werden vollständig aus der Historie entfernt; das entspricht der Dokumentation, schränkt aber die Verwendung von Alt-Schäden in der Historie ein. Der leere Datenfall ist nicht explizit getestet.

### `apply_index()` — `R/basic.R:328-341`
- **Zweck:** Indiziert Zahlungen von ihren ursprünglichen Kalenderjahren auf neue Kalenderjahre.
- **Paperbezug:** 2.1 Indexierung, S. 10 · konform · Verwendet das Verhältnis der Transition-Faktoren und entspricht damit der geforderten Indexierung auf ein einheitliches Niveau bzw. auf das Auszahlungsjahr.
- **Fehler:** keine gefunden.
- **Hinweise:** Die Länge von `payments`, `original_cal_years` und `new_cal_years` wird nicht geprüft; bei abweichenden Längen greift R-Recycling.

### `tail_factor()` — `R/basic.R:362-371`
- **Zweck:** Liefert den linearen Abschmelzfaktor vom ersten Nachlaufjahr auf ein gewünschtes Abwicklungsjahr.
- **Paperbezug:** 2.4.4 Nachlauf, S. 15 · konform · Die Funktion ist äquivalent zur Paperformel \(Z_{M+j}=Z_{M+1}\cdot(T-M-j+1)/(T-M)\) für `start_of_tail = M+1` und `end_of_tail = T`.
- **Fehler:** keine gefunden.
- **Verbesserungen:** `B-V01` (kürzer/lesbarer) Direkte Umsetzung der Formel ohne doppeltes `pmin`; Code: `verbesserungen/B-V01.R`.
- **Hinweise:** Für `start_of_tail > end_of_tail` ist der Nachlaufbereich leer; die Division durch einen nichtpositiven Nenner ist nicht abgefangen.

### `cal_year2dev_year()` — `R/basic.R:386-396`
- **Zweck:** Wandelt ein Kalenderjahrdreieck in ein Abwicklungsjahrdreieck um.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.
- **Verbesserungen:** `B-V02` (effizienter) Vektorisierte Zellzuordnung statt zeilenweisem R-Loop; Code: `verbesserungen/B-V02.R`, Benchmark: `bench/B-V02.R`.
- **Hinweise:** Die Funktion unterstellt ein quadratisches Dreieck und dass Zeilen- und Spaltenjahre übereinstimmen.

### `dev_year2cal_year()` — `R/basic.R:412-422`
- **Zweck:** Wandelt ein Abwicklungsjahrdreieck in ein Kalenderjahrdreieck zurück.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.
- **Hinweise:** Die Kalenderjahre werden aus den Zeilennamen rekonstruiert; das setzt die übliche Übereinstimmung von Anfalls- und Kalenderjahren voraus.

### `inc2cum()` — `R/basic.R:433-439`
- **Zweck:** Kumuliert jede Zeile eines Dreiecks über die Spalten.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** `B-F03` (mittel) Durch `for (i in 1:NROW(incr_triangle))` läuft die Schleife bei einer Matrix mit 0 Zeilen als `1:0` und greift auf Zeile 1 zu; eine leere Matrix führt zum Abbruch statt zur unveränderten leeren Matrix. Beleg: `befunde/test-B-F03.R`.
- **Verbesserungen:** `B-F03` Korrektur: `verbesserungen/B-F03.R` verwendet `seq_len()`.

### `cum2inc()` — `R/basic.R:450-460`
- **Zweck:** Wandelt ein kumulatives Dreieck in ein inkrementelles Dreieck um.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** `B-F04` (niedrig) Für `numeric(0)` liefert die Vektorbranch `c(cum_triangle[1], diff(...))` den Wert `NA` statt `numeric(0)`. Beleg: `befunde/test-B-F04.R`.
- **Verbesserungen:** `B-F04` Korrektur: `verbesserungen/B-F04.R` behandelt leere Vektoren und Matrizen.

### `matrix2triangle()` — `R/basic.R:473-475`
- **Zweck:** Nullt das obere linke Dreieck einschliesslich der Diagonalen und lässt nur das untere rechte Dreieck stehen.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.
- **Hinweise:** Die Bedingung `col + row > dim(matr)[1] + 1` ist für quadratische Matrizen korrekt; bei nichtquadratischen Matrizen ist die Diagonale nicht eindeutig.

### `sample_1()` — `R/basic.R:493-499`
- **Zweck:** Wie `sample()`, aber bei einem einelementigen Pool wird der Wert `i`-mal wiederholt.
- **Paperbezug:** Hilfsfunktion für das Sampling, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.
- **Hinweise:** Die Prüfung verwendet `NROW(pool)` statt `length(pool)`; für die intern verwendeten atomaren Vektoren ist beides identisch, für Matrizen oder Listen mit einem Element wäre das Verhalten nicht das eines Pools. Ein leerer Pool wird nicht abgefangen.

### `nice_format()` — `R/basic.R:513-515`
- **Zweck:** Formatiert Zahlen mit zwei Dezimalstellen und deutschen Trennzeichen.
- **Paperbezug:** Hilfsfunktion, nicht im Paper · nicht im Paper (Hilfsfunktion).
- **Fehler:** keine gefunden.
- **Hinweise:** Die Verwendung von `round()` mit `format()` ist für reine Ausgabezwecke unkritisch.

## Befundliste
| ID | Funktion | Art | Schwere/Ziel | Kurzbeschreibung | Beleg |
|---|---|---|---|---|---|
| B-F01 | `expand_historic_indices()` | Fehler | hoch | Indexwerte werden positionsbasiert statt nach `Calendar_year` zugeordnet; Lücken erzeugen einen kryptischen Fehler | `befunde/test-B-F01.R` |
| B-F02 | `add_transition_factor()` | Fehler | mittel | Fehlendes `index_year` führt zu `numeric(0)`-Nenner und unklarem Abbruch statt Validierung | `befunde/test-B-F02.R` |
| B-F03 | `inc2cum()` | Fehler | mittel | Leere Matrix stürzt durch `for (i in 1:0)` ab | `befunde/test-B-F03.R` |
| B-F04 | `cum2inc()` | Fehler | niedrig | Leerer Vektor liefert `NA` statt `numeric(0)` | `befunde/test-B-F04.R` |
| B-V01 | `tail_factor()` | Verbesserung | kürzer/lesbarer | Direkte Paperformel ohne doppeltes `pmin` | `verbesserungen/B-V01.R`, `tests/verbesserungen/test-B-V01.R` |
| B-V02 | `cal_year2dev_year()` | Verbesserung | effizienter | Vektorisierte Dreiecksumwandlung statt Zeilen-Loop | `verbesserungen/B-V02.R`, `tests/verbesserungen/test-B-V02.R`, `bench/B-V02.R` |
