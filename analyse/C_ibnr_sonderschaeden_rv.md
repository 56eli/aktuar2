# Gruppe C: Spätgroßschäden, Sonderschäden und Rückversicherung

Dateien: `R/ibnr.R` (394 Zeilen), `R/special_claims.R` (360 Zeilen), `R/reinsurance.R` (326 Zeilen) · Funktionen: 10

## Überblick

`R/ibnr.R` setzt Abschnitt 2.4.5 (Spätgroßschäden, S. 16) um: ein additives Verfahren für die erwartete **Anzahl** je Abwicklungsjahr (beobachtete Spätgroßschäden je Bestandsgröße, multipliziert mit der Bestandsgröße der jüngeren Anfalljahre), Rundung auf ganze Anzahlen und ein Pool historischer Spätgroßschäden, aus dem die **Höhe** gesampelt wird. Die Kette ist funktional gut nachvollziehbar und in kleine, einzeln exportierte Schritte zerlegt; zwei Fehler wirken aber direkt auf die Anzahl der erwarteten Schäden (Sortierannahme an `exposure`, fehlendes letztes Abwicklungsjahr) und einer auf die Bestandsgröße (Abschneiden auf ganze Zahlen). `R/special_claims.R` bildet 2.5 (S. 17–18) deterministisch ab: Reserve × BE-Prozentsatz, Ausrollen über ein lineares/konstantes/externes Muster, optional Renten und Rückversicherung — paperkonform, aber mit einem Tippfehler, der bei ungültigem `Rollout_type` still einen Null-Cashflow erzeugt. `R/reinsurance.R` rechnet das XL-Programm je Schaden und Simulation (Brutto → Quote → XL, Netto = Brutto − RV), ist auf Pfadebene angewendet und damit konform zu 3.2.1 (S. 55); die Indexklausel wird jedoch um ein volles Indexjahr zu stark verankert, und AAD/AAL fehlen (dokumentierte Einschränkung, 2.6.3 S. 19). **Gesamturteil:** zwei klare Logikfehler (Spätgroßschadenanzahl), zwei Tippfehler mit stiller Fehlreaktion, eine off-by-one-Indexierung; ansonsten paperkonform mit Randschwächen.

## Funktionen

### `get_additive_ibnr_model()` — `R/ibnr.R:41-73`
- **Zweck:** Schätzt je Abwicklungsjahr die Anzahl beobachteter Spätgroßschäden, die zugehörige Bestandsgröße und den additiven Faktor Anzahl/Bestandsgröße.
- **Paperbezug:** 2.4.5 „Ansatz für Spätgroßschäden“, S. 16 · **konform** · Zähler (Zeilen 57, 62-63: Schäden mit `Large_since` in den Pooljahren und passendem `Dev_year_of_growing_large`) und Nenner (Zeile 64: Bestandsgröße genau der Anfalljahre, deren Großwerden-Kalenderjahr in den Pooljahren liegt) entsprechen dem geforderten Verhältnis „beobachtete Spätgroßschäden / Bestandsgröße“.
- **Fehler:** `C-F05` (mittel) — Zeile 49 begrenzt auf `NROW(orig_years) - 1` Abwicklungsjahre, obwohl der älteste Anfalljahrgang im letzten Kalenderjahr das Abwicklungsjahr N erreichen kann — dessen Spätgroßschäden werden ignoriert (Paper: „für jedes Abwicklungsjahr“). Beleg: `befunde/test-C-F05.R`. *Geprüft und verworfen (cl1):* die zusätzliche Behauptung, `integer()` in Zeile 54 schneide die Bestandsgröße ab – R wandelt bei der Zuweisung in `double` um, sicr liefert 17,5.
- **Verdacht (unbelegt):** Bestandsgröße 0 in einem Pooljahr erzeugt `0/0 = NaN` (Zeile 67); `round_expected_ibnr_numbers()` bricht dann an `if (decimal == 0)` mit „missing value where TRUE/FALSE needed“ ab.
- **Hinweise:** Der Faktor wird für Abwicklungsjahr 1 mitgeschätzt, aber nie verwendet (Spalten der Erwartungsmatrix beginnen bei 2). Keine Prüfung, ob `exposure` alle Anfalljahre enthält (`match` liefert sonst `NA`, Zeile 52).

### `get_expected_ibnr_numbers()` — `R/ibnr.R:96-122`
- **Zweck:** Erwartete künftige IBNR-Anzahlen als Matrix (Anfalljahr × Abwicklungsjahr) durch Multiplikation der Bestandsgröße mit dem additiven Faktor.
- **Paperbezug:** 2.4.5, S. 16 · **konform** · „Das Ergebnis wird mit der Bestandsgröße der jüngeren Schadenjahre multipliziert“: die Matrix enthält für Anfalljahr *o* genau die Abwicklungsjahre, deren Kalenderjahr nach dem Bewertungsjahr liegt, bewertet mit der Bestandsgröße von *o* (Zeilen 104-112).
- **Fehler:** `C-F03` (hoch) — Zeilen 104, 109 und 118 setzen stillschweigend eine aufsteigend nach `Origin_year` sortierte `exposure`-Tabelle voraus (`rev()`, Zeilenumdrehung, `rownames` aus `exposure`). Bei anderer Zeilenreihenfolge erhalten die ältesten Anfalljahre die IBNR-Zahlen der jüngsten und umgekehrt; die Zahlungszeitpunkte der erwarteten Schäden verschieben sich dadurch massiv. Beleg: `befunde/test-C-F03.R`.
- **Hinweise:** Zeile 115 (NA-Ersetzung) ist toter Code — die Matrix füllt sich durch Recycling immer vollständig. Die Doku („one row for each desired origin year“) suggeriert eine Teilmenge; `ibnr_transform2dataframe()` verwendet aber `max(rownames)` als Bewertungsjahr, sodass de facto die volle Reihe bis `last_orig_year` übergeben werden muss.

### `round_expected_ibnr_numbers()` — `R/ibnr.R:189-201`
- **Zweck:** Rundet die Erwartungsmatrix auf ganze Schadenanzahlen und verteilt Reste über die Abwicklungsjahre einer Zeile.
- **Paperbezug:** 2.4.5, S. 16 („Nicht-ganze Schadenanzahlen müssen mit einem Algorithmus auf ganze Schadenanzahlen gerundet und ggf. auf Schaden- und Abwicklungsjahre aufgeteilt werden“) · **konform** · 0-Zellen bleiben 0 (Zeile 195), der Rest wird innerhalb der Zeile weitergetragen (Zeile 197).
- **Fehler:** keine gefunden (der Test in `befunde/test-C-F03.R` nutzt die Funktion nur als Baustein).
- **Hinweise:** `C-H04` — die Doku verspricht, dass „rowsums and colsums“ kaum verändert werden; erhalten bleiben nur die Zeilensummen, und auch die nur bis auf den am Zeilenende verfallenden Rest (bis ±0,5 je Zeile). Spaltensummen können um bis zu 0,5 je Zeile abweichen. `round()` rundet halbe Werte zur geraden Zahl (0,5 → 0, 1,5 → 2). Bei `nrow = 0` bricht `1:nrow(...)` (Zeile 191) ab.

### `ibnr_transform2dataframe()` — `R/ibnr.R:233-251`
- **Zweck:** Wandelt die gerundete Matrix in eine Zeile je erwartetem Spätgroßschaden mit Anfalljahr, Abwicklungsjahr des Großwerdens und `Dev_year_since_large` um.
- **Paperbezug:** nicht im Paper (Hilfsfunktion; liefert den Startzustand der erwarteten Schäden für das Sampling, 2.4.5/2.4.1 S. 13–16).
- **Fehler:** keine gefunden. `Dev_year_since_large = last_orig_year - Origin_year - Dev_year + 2` (Zeile 248) ist korrekt: für künftig groß werdende Schäden ist der Wert < 1, wie dokumentiert.
- **Verbesserungen:** `C-V02` (effizienter, weniger Abhängigkeiten) — die Kette `as.table`/`rename`/`uncount` lässt sich durch `expand.grid()` + `rep()` in base-R ersetzen; Code: `verbesserungen/C-V02.R`, Gleichheitstest `tests/verbesserungen/test-C-V02.R`, Benchmark `bench/C-V02.R`.
- **Hinweise:** `last_orig_year` wird aus `max(rownames)` rekonstruiert (Zeile 238) — bei einer Teilmatrix oder fehlenden Dimnames (`max(NULL)`) ist das Bewertungsjahr falsch bzw. `-Inf`.

### `generate_ibnr_pools()` — `R/ibnr.R:287-299`
- **Zweck:** Baut je Abwicklungsjahr einen Vektor mit den Zeilennummern der historischen Spätgroßschäden, aus denen die Höhe gesampelt wird.
- **Paperbezug:** 2.4.5, S. 16 · **konform** · „Höhe … aus den abgewickelten Schadenhöhen der bekannten im n-ten Abwicklungsjahr groß gewordenen Spätgroßschäden gesampelt“; die Kalenderjahr-Auswahl über `years_for_ibnr_pools` entspricht dem Historienfenster aus 2.4.3 (S. 14).
- **Fehler:** keine gefunden. Der Listenindex ist um eins versetzt (`pools[[k]]` = Abwicklungsjahr k+1); der einzige Konsument `sample_ibnr()` (`R/sicr.R:221`) verwendet `ibnr_pools[[year - 1]]` und ist damit konsistent.
- **Verbesserungen:** `C-V01` (kürzer/lesbarer) — ein logischer Vektor plus `lapply`/`which` statt Schleife mit data.frame-Filter; Code: `verbesserungen/C-V01.R`, Gleichheitstest `tests/verbesserungen/test-C-V01.R`.
- **Hinweise:** `C-H03` — die Doku („List of one vector per development year“) legt nahe, dass Element *n* zu Abwicklungsjahr *n* gehört; tatsächlich fehlt Abwicklungsjahr 1, Element *n* gehört zu *n+1*. Die im Paper optionale Zusammenfassung später Abwicklungsjahre bei wenigen Beobachtungen (S. 16) ist nicht angeboten; die Poolgröße ist je Abwicklungsjahr fix.

### `prepare_ibnr()` — `R/ibnr.R:364-391`
- **Zweck:** Führt die vier Schritte zur Erwartungsliste und die Poolerzeugung zusammen.
- **Paperbezug:** nicht im Paper (Hilfs-/Kompositionsfunktion; Workflow 2.4.5, S. 16).
- **Fehler:** keine gefunden. Sinnvolle Defaults: konstante Bestandsgröße 1 (Zeile 371-372) und alle Jahre als Pooljahre (Zeile 374).
- **Hinweise:** Erbt die Fehler der aufgerufenen Funktionen (`C-F03`, `C-F05`). Die Reihenfolge der Pipeline (`get_additive… %>% get_expected… %>% round… %>% transform…`) ist korrekt.

### `roll_out_single_claim()` — `R/special_claims.R:28-72`
- **Zweck:** Verteilt eine Sonderreserve über künftige Jahre — linear abnehmend, konstant oder nach externem Muster.
- **Paperbezug:** 2.5.2, S. 18 („Einschätzung … zum Auszahlungsmuster“) · **Erweiterung** · das Paper verlangt nur ein individuell vereinbartes Muster; die drei Varianten sind eine über das Paper hinausgehende, sinnvolle Parametrisierung. Die lineare Variante summiert exakt zur Reserve (Zeile 57-60), der letzte Schritt ist 0 (Fortsetzung der Geraden).
- **Fehler:** `C-F01` (mittel) — Zeile 30 setzt im Fehlerfall die Variable `art` statt `type`; ein ungültiger `Rollout_type` wird daher nicht wie angekündigt auf `"linear"` gesetzt, sondern die Funktion liefert einen Nullvektor, d.h. der Sonderschaden erhält einen Best Estimate von 0 (nur eine Warnung). Beleg: `befunde/test-C-F01.R`.
- **Hinweise:** Die Prüfung von `years` ist in Zeilen 51-55 und 63-67 dupliziert; statt `years` auf 1 zu setzen, wäre eine Kappung auf 250 naheliegender. `external_pattern` der Länge 0 führt zu einem Fehler (Zeile 47: `1:0`).

### `compute_special_claims()` — `R/special_claims.R:196-359`
- **Zweck:** Berechnet für die vom Nutzer benannten Sonderschäden Reserve-/Zahlungsdreiecke, Renten sowie die RV-Anteile (Quote und XL) deterministisch.
- **Paperbezug:** 2.5 / 2.5.1 / 2.5.2, S. 17–18 · **konform** · Sonderschäden werden separiert, deterministisch (Reserve × `Reserve2BE_percentage`, kein Sampling), anerkannte Renten lebensversicherungstechnisch abgewickelt (Zeilen 309-326) und sind aus den Basisschadendreiecken herausgerechnet (`R/small_claims.R:490-503`); der RV-Anteil wird trotz deterministischer Bewertung je Schaden berechnet (Zeile 329-340) — das geht über 2.5.2 hinaus, ist aber konsistent zu 3.2.1 (S. 55).
- **Fehler:** keine gefunden. Die Reihenfolge Brutto → Quote → XL ist korrekt (die Quote wird in `xl_cashflow()` intern vor dem XL abgezogen, Zeile 303 dort); `output = "total"` inkludiert bewusst auch die historischen XL-Anteile (konsistent zu `R/aggregate_large_claims_results.R:168-186`), Quote und XL werden nicht doppelt gezählt. Leerer Sonderbestand liefert Nullmatrizen mit korrekten Dimensionen (Zeile 222-227).
- **Verdacht (unbelegt, C-H01):** Der ausgerollte Cashflow wird **nicht** auf die künftigen Kalenderjahre indexiert (Zeilen 299-302 und 313-318 nutzen `indices` nicht), obwohl 2.1 (S. 10) die Hochrechnung aller Zahlungen auf das Auszahlungsjahr verlangt und die große-Schäden-Simulation genau das tut (`R/sicr.R:470-485`). Der Best Estimate der Sonderschäden (und ihr RV-Anteil) fällt damit im Inflationsumfeld zu niedrig aus; `indices` wird laut Doku nur für die Rückversicherung benötigt. Ohne Test, weil die Doku (`Rollout_type`: „The sum is the desired best estimate“) auch die Gegenlesart zulässt.
- **Hinweise:** `C-H02` — 130 ist als Länge der Rentenvektoren hart codiert (Zeilen 320-324); bei einer Änderung von `generate_annuity_payments()` bricht das still. `match()` wird je Schaden in der Schleife neu gebildet (Zeile 298, bei vielen Sonderschäden quadratisch) — könnte einmalig vor die Schleife gezogen werden. Sonderschäden ohne Zeile im letzten Kalenderjahr (bereits geschlossen) erhalten keinen Ausroll-Cashflow.

### `generate_xl_indices_per_claim()` — `R/reinsurance.R:47-104`
- **Zweck:** Erzeugt je Schaden und Kalenderjahr den Faktor der Indexklausel (APK/SIC/FIC) für die XL-Abrechnung.
- **Paperbezug:** 2.6.1, S. 18 („vertraglich vereinbarte Indexklausel … vollständiger Cashflow je Einzelschaden“) · **abweichend** · Aufbau und die drei Klauseltypen (Zeilen 67-89) folgen der in Zeilen 139-164 dokumentierten Formel, die Verankerung des Basisjahres weicht aber ab.
- **Fehler:** `C-F04` (mittel) — Zeile 76 startet `cumprod()` im Basisjahr B und legt den Vektor ab B ab (Zeilen 78, 85); damit ist der Faktor im Basisjahr `1 + Index_re[B]` statt `I_B/I_B = 1`. Implementiert ist `I_i/I_(B-1)`: die Priorität wird um ein volles Indexjahr zu stark indexiert, die Klausel greift ein Jahr zu früh, der RV-Anteil fällt zu klein aus. Beleg: `befunde/test-C-F04.R` (Basisjahr-Inflation 20 % → 80.000 statt 100.000 gedeckt).
- **Hinweise:** `colnames(...) >= first_orig_year` (Zeile 99) vergleicht Zeichenketten mit einer Zahl (funktioniert nur bei durchgängig vierstelligen Jahren). `rep(1, indexation_year - indices$Calendar_year[1])` (Zeilen 78, 85) bricht, wenn das Basisjahr vor dem ersten Indexjahr liegt; `FIC` wird als `APK` mit Marge 0 umgesetzt, sodass bei Deflation (`cum_indices < 1`) keine Indexierung angewendet wird (Zeilen 67-69, 79-81).

### `xl_cashflow()` — `R/reinsurance.R:255-326`
- **Zweck:** Berechnet den XL-Anteil je Schaden aus historischen und simulierten Zahlungen, inklusive indexierter Priorität/Limit, Quote und wahlweise Historie/Zukunft/Gesamt.
- **Paperbezug:** 2.6.1–2.6.3, S. 18–19 sowie 3.2.1, S. 55 · **abweichend** · Brutto-Cashflow je Pfad → Quote → XL und RV = Brutto − Netto ist exakt der in 3.2.1 geforderte Weg (auch für Schäden unterhalb der Priorität, die im Pfad darüber laufen); AAD/AAL (2.6.3, S. 19) sind nicht implementiert — als Einschränkung dokumentiert (`R/data.R:224-225`), damit bewusst und nicht still.
- **Fehler:** `C-F02` (niedrig) — Zeile 311 schreibt `output == "future"` statt `output <- "future"`; bei ungültigem `output` bleibt der Wert unverändert und der else-Zweig (Zeilen 323-325) liefert die volle Matrix statt der 250 Zukunftsspalten, obwohl die Warnung „set to 'future'“ meldet. Beleg: `befunde/test-C-F02.R`.
- **Hinweise:** `C-H05` — `pmax(cum, 0)` (Zeilen 283, 286) kappt negative kumulierte Zahlungen (Regresse) punktuell bei 0; der Gesamtanteil bleibt korrekt (die Differenzenbildung `cum2inc` holt gekappte Beträge zurück), die zeitliche Zuordnung kann sich aber verschieben. Die Recycling-Multiplikation `reinsurance$Priority[origin_years] * adj_factor` (Zeile 299-300) sieht falsch aus, ist aber korrekt, weil `adj_factor` spaltenweise gefüllt ist und der Prioritätsvektor mit Periode `nrow` recycelt wird. Keine Prüfung, dass `ncol(xl_indices_per_claim) == ncol(history) + ncol(future_payments)` (Zeile 286); bei abweichender Indexlänge bricht die Division mit „non-conformable arrays“ ab. Die Doku von `history` („colnames must be the origin years“) meint Kalenderjahre.

## Befundliste

| ID | Funktion | Art | Schwere/Ziel | Kurzbeschreibung | Beleg |
|---|---|---|---|---|---|
| C-F01 | `roll_out_single_claim()` | Fehler | mittel | Zeile 30 setzt `art` statt `type`; ungültiger `Rollout_type` liefert still einen Null-Cashflow (BE = 0) | `befunde/test-C-F01.R`, `verbesserungen/C-F01.R` |
| C-F02 | `xl_cashflow()` | Fehler | niedrig | Zeile 311 `output == "future"` statt `<-`; ungültiger `output` liefert die volle Matrix statt „future“ | `befunde/test-C-F02.R`, `verbesserungen/C-F02.R` |
| C-F03 | `get_expected_ibnr_numbers()` | Fehler | hoch | Stille Sortierannahme an `exposure` (Zeilen 104-118): unsortiert werden IBNR-Anzahlen den falschen Anfalljahren zugeordnet | `befunde/test-C-F03.R`, `verbesserungen/C-F03.R` |
| C-F04 | `generate_xl_indices_per_claim()` | Fehler | mittel | Indexklausel ein Jahr zu früh verankert (Zeile 76): Faktor im Basisjahr 1+`Index_re` statt 1, Priorität zu hoch, RV-Anteil zu klein | `befunde/test-C-F04.R`, `verbesserungen/C-F04.R` |
| C-F05 | `get_additive_ibnr_model()` | Fehler | mittel | Zeile 49 lässt das letzte Abwicklungsjahr N weg, dessen Spätgroßschäden zählen nicht | `befunde/test-C-F05.R`, `verbesserungen/C-F05.R` |
| C-V01 | `generate_ibnr_pools()` | Verbesserung | kürzer/lesbarer | logischer Vektor + `lapply`/`which` statt Schleife mit data.frame-Filter, gleiches Ergebnis | `tests/verbesserungen/test-C-V01.R`, `verbesserungen/C-V01.R` |
| C-V02 | `ibnr_transform2dataframe()` | Verbesserung | effizienter | `expand.grid()` + `rep()` in base-R statt `as.table`/dplyr/`tidyr::uncount`, gleiches Ergebnis | `tests/verbesserungen/test-C-V02.R`, `verbesserungen/C-V02.R`, `bench/C-V02.R` |
| C-H01 | `compute_special_claims()` | Hinweis | – | Sonder-Cashflow wird nicht auf die Auszahlungsjahre indexiert (2.1, S. 10); Verdacht, unbelegt | – |
| C-H02 | `compute_special_claims()` | Hinweis | – | Hart codierte Länge 130 der Rentenvektoren; `match()` je Schleifendurchlauf statt einmalig | – |
| C-H03 | `generate_ibnr_pools()` | Hinweis | – | Listenindex *k* gehört zu Abwicklungsjahr *k+1* (Doku sagt „per development year“); keine Zusammenfassung später Abwicklungsjahre (S. 16) | – |
| C-H04 | `round_expected_ibnr_numbers()` | Hinweis | – | Spaltensummen bleiben nicht erhalten (Doku), Rest am Zeilenende verfällt; `1:nrow` bei 0 Zeilen | – |
| C-H05 | `xl_cashflow()` | Hinweis | – | AAD/AAL (2.6.3, S. 19) nicht implementiert (dokumentiert); keine Längenprüfung der Indexmatrix; `pmax(cum,0)` bei Regressen | – |
