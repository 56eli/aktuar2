# Paperabgleich-Matrix: sicr 1.1.1 gegen DAV-Ergebnisbericht „Stochastische Einzelschadenreservierung“ (04.02.2025)

Die Matrix prüft das R-Paket sicr 1.1.1 gegen die Prüf-Checkliste D.1–D.11 des DAV-Ergebnisberichts. Skala: konform (Standard umgesetzt oder per Parameter wählbar), konform (Fehler) (Methode wie im Paper umgesetzt, aber durch einen belegten Programmierfehler beeinträchtigt; die Befund-ID bleibt stehen), abweichend (methodisch andere Umsetzung, z. B. fehlendes Abwicklungsjahr N, kein AAD/AAL), fehlt, Erweiterung, nicht im Paper. Die Spalte Begründung (max. 25 Wörter) erläutert jede Einstufung, die nicht schlicht konform ist. Diskussionspunkte aus Kapitel 3.2 sind nur Hinweise; maßgeblich sind Anhang D, der Code und die Einstufungen in `analyse/A_*.md` bis `analyse/F_*.md`.

## D.1 Daten und Vorverarbeitung

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.1.1 | Einzelschadenbasis mit Zahlungen und HGB-Reserven; optional Renten, RV, Exposure, Indizes (S. 9) | `prepare_data()` `R/data_functions.R:726-758`; `claims_data_ok()` `R/data_checks.R:275-335`; `sicr()` `R/sicr.R:113-128` | konform | – | – |
| D.1.2 | Alle Zahlungen und Reserven auf einheitliches Niveau und Auszahlungsjahr indexieren (S. 10) | `add_indexed_columns()` `R/data_functions.R:312-349`; `apply_index()` `R/basic.R:328-341`; `sicr()` `R/sicr.R:451` | konform | – | – |
| D.1.3 | Großschaden- und Reserveklassengrenzen auf Indexjahr indexieren (S. 10) | `filter_large_claims()` `R/data_functions.R:394-412`; `add_classes()` `R/data_functions.R:447-452` | konform | – | – |
| D.1.4 | Konstantes Indexierungsjahr über Reservierungsjahre als Standard (S. 10) | `add_transition_factor()` `R/data_functions.R:77-82`; Attribut `index_year` `R/data_functions.R:347` | konform (Fehler) | B-F02 | Konstantes Indexjahr ist umgesetzt; B-F02 betrifft nur die fehlende Validierung eines ungültigen index_year. |
| D.1.5 | Dokumentierte Indexreihe und Prognose per Mittelwert oder linearer Fortschreibung (S. 10) | `expand_historic_indices()` `R/data_functions.R:34-50`; `add_transition_factor()` `R/data_functions.R:77-82` | konform (Fehler) | B-F01 | Indexreihe und Prognose folgen dem Paper; B-F01 ordnet historische Indizes positions- statt kalenderjahrbasiert zu. |

## D.2 Trennung Basis-/Großschäden

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.2.1 | Großschaden: indexierter Aufwand überschreitet G mindestens einmal, danach dauerhaft (S. 11) | `filter_large_claims()` `R/data_functions.R:394-413` | konform | – | – |
| D.2.2 | G unterhalb der minimalen RV-Priorität aller Schadenjahre wählen (S. 11) | Keine Prüfung von `threshold` gegen `reinsurance$Priority`; `prepare_data()` `R/data_functions.R:726-733`, `xl_cashflow()` `R/reinsurance.R:296-303` | fehlt | – | Keine Prüfung, dass G unter der minimalen RV-Priorität aller Schadenjahre liegt. |
| D.2.3 | Methode 3: HGB-Reserve ins Großschadendreieck, frühere Zahlungen zu Basis (S. 11) | `filter_large_claims()` `R/data_functions.R:410-413`; `generate_triangle()` `R/basic.R:112-117`; `compute_small_claims()` `R/small_claims.R:489-503` | konform | – | – |
| D.2.4 | Zahlung im Jahr des Großwerdens den Großschäden zuordnen (S. 12) | `generate_triangle()` `R/basic.R:112-117`; `Dev_year_since_large` `R/data_functions.R:410-413` | konform | – | – |

## D.3 Zustände und Pools

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.3.1 | Abwicklungsjahr zählt ab dem Jahr des Großwerdens (S. 13–14) | `filter_large_claims()` `R/data_functions.R:410-413`; `generate_claims_list()` `R/data_functions.R:124-131`; `sicr()` `R/sicr.R:372-373` | konform | – | – |
| D.3.2 | Reserveklassen aus indexierter HGB-Reserve; offen/geschlossen; Mindestbeobachtungen (S. 14) | `add_classes()` `R/data_functions.R:447-452`; Dummy-Zeilen für leere Pools `R/generate_pools.R:86-89, 124-125` | konform | – | Klassen aus indexierter HGB-Reserve; offen/geschlossen sind abbildbar, Mindestbesetzung bleibt Nutzerentscheidung. |
| D.3.3 | Pool P(i,rk): je historischem Großschaden Zahlung Folgejahr und neue Klasse (S. 8, 14) | `generate_pools()` `R/generate_pools.R:71-102`, Spalten `:74-84` | konform | – | – |
| D.3.4 | Optionale Poolmerkmale für Rentenanerkennungen (S. 17) | `attach_future_annuities()` `R/data_functions.R:493-551`; Poolspalten `R/generate_pools.R:77-84` | konform | – | – |
| D.3.5 | Historienbegrenzung sowie Ausschluss extremer Zahlungen und Regresse regeln (S. 14) | `generate_pools()` `R/generate_pools.R:61-68, 74-76, 92-94, 130-139` | konform (Fehler) | A-F01 | Historienbegrenzung und Ausschluss extremer Zahlungen sind umgesetzt; A-F01 wendet die Grenzen nach der Hochskalierung an. |

## D.4 Simulation (Ziehungslogik)

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.4.1 | Startzustand jedes offenen Großschadens als Abwicklungsjahr und Reserveklasse (S. 7–8) | `generate_claims_list()` `R/data_functions.R:116-133`; `sicr()` `R/sicr.R:371-373` | konform | – | – |
| D.4.2 | Zufällige Zeile aus P(i,rk) ziehen; Zahlung und neuen Zustand übernehmen (S. 8) | `sicr()` `R/sicr.R:167-200`; `get_matrix_info()` `R/sampling_preparation.R:167-188` | konform | A-K01 | – |
| D.4.3 | Aus P(i+1,rk') bis zum Abwicklungsende fortsetzen (S. 8) | `sicr()` `R/sicr.R:442-452`; `sample_next_year()` `R/sicr.R:193-197` | konform | A-K02 | – |
| D.4.4 | Je Pfad Jahreszahlungen, Klassenverlauf und Abwicklungsende ausgeben (S. 8, 55) | `sicr()` `R/sicr.R:544-565, 585-602, 650-653` | konform | – | Detaillierter Export liefert Zahlungen, Reserveklassen- und Abwicklungsjahr je Schaden und Jahr; Rückgabe über Realisationen gemittelt. |
| D.4.5 | Renten: je Simulation zufälliges Sterbejahr; volle Zahlung bis dahin, danach null (S. 17) | `roll_out_annuity()` `R/annuity_functions.R:209-229`; `sicr()` `R/sicr.R:455-461` | konform (Fehler) | D-F01 | Zufälliges Sterbejahr mit voller Zahlung bis dahin ist umgesetzt; D-F01 verschiebt die Überlebenswahrscheinlichkeiten um ein Jahr. |
| D.4.6 | Gezogene Rentenzeile erzeugt neue Rente mit Merkmalen und stochastischer Abwicklung (S. 17) | `attach_future_annuities()` `R/data_functions.R:493-551`; `sicr()` `R/sicr.R:464-490` | konform (Fehler) | D-F01 | Gezogene Rentenzeile erzeugt eine neue Rente mit Merkmalen; D-F01 verschiebt die Sterbewahrscheinlichkeiten um ein Jahr. |

## D.5 Nachlauf/Tail

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.5.1 | Parameter M für letztes Samplingjahr und T für Abwicklungsende (S. 15) | `generate_pools()` `R/generate_pools.R:61-68`; Attribute `R/generate_pools.R:149-150` | konform | – | – |
| D.5.2 | Zahlungen der Jahre M+1 bis T je Reserveklasse zu einem Nachlaufpool bündeln (S. 15) | `generate_pools()` `R/generate_pools.R:104-142` | konform | – | – |
| D.5.3 | Nachlauf mit Formel hoch- und herunterskalieren (S. 15) | `generate_pools()` `R/generate_pools.R:130-131`; `tail_factor()` `R/basic.R:362-371`; `sicr()` `R/sicr.R:195-197` | konform | A-K02 | – |
| D.5.4 | Reserveklassen und Klassenwechsel im Nachlauf beibehalten (S. 15) | `generate_pools()` `R/generate_pools.R:108-120`; `sicr()` `R/sicr.R:194, 449` | konform | – | – |
| D.5.5 | T auch für länger laufende Renten berücksichtigen (S. 20, 29, 37) | `sicr()` `R/sicr.R:475-487`; gesamte Rente mit einem `tail_factor()` des Entstehungsjahres skaliert | konform | – | Renten laufen über 130 Spalten aus (`R/sicr.R:475`), also über T hinaus; der `tail_factor` skaliert nur die Wahrscheinlichkeit einer Neuanerkennung im Nachlauf (cl1 am Code geprüft). |

## D.6 Spätgroßschäden (IBNR der Großschäden)

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.6.1 | Erwartete Spätgroßschadenanzahl additiv je Abwicklungsjahr aus Beobachtungen und Bestand (S. 16) | `get_additive_ibnr_model()` `R/ibnr.R:41-72`; `get_expected_ibnr_numbers()` `R/ibnr.R:96-121` | abweichend | C-F03, C-F05 | C-F05 lässt das letzte Abwicklungsjahr N weg; C-F03 ordnet Bestandsgrößen zudem positionsabhängig statt nach Anfalljahr zu. |
| D.6.2 | Erwartete Anzahlen runden und auf Schaden- und Abwicklungsjahre verteilen (S. 16) | `round_expected_ibnr_numbers()` `R/ibnr.R:189-201` | konform | C-H04 | – |
| D.6.3 | Höhe aus bekannten Spätgroßschäden gleichen Abwicklungsjahres sampeln; späte Jahre bündeln (S. 16) | `generate_ibnr_pools()` `R/ibnr.R:287-299`; `sample_ibnr()` `R/sicr.R:204-263` | konform | C-H03 | Die Pflichtmethode ist umgesetzt; die im Paper optionale Zusammenfassung späterer Abwicklungsjahre fehlt (C-H03). |
| D.6.4 | Zahlungen vor dem Großwerden konsistent zur Trennungsmethode behandeln (S. 16) | `sample_ibnr()` `R/sicr.R:241-247`; `generate_triangle()` `R/basic.R:112-117` | konform | – | – |

## D.7 Basisschäden

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.7.1 | Homogene Zahlungs- und Aufwandsdreiecke deterministisch abwickeln (S. 13) | `compute_small_claims()` `R/small_claims.R:488-557`; `cl_factor()` bis `best_estimate2cashflow()` `R/small_claims.R:17-288` | konform (Fehler) | D-F04, D-F05 | Deterministische Dreiecksabwicklung ist umgesetzt; D-F04 und D-F05 brechen nur bei einem einspaltigen Dreieck ab. |
| D.7.2 | Bekannte Renten lebensversicherungsmathematisch, künftige Anerkennungen additiv abwickeln (S. 13) | `compute_small_claims()` `R/small_claims.R:561-604`; `R/small_claims_future_annuities.R:94-338` | konform (Fehler) | D-F01, D-F07 | Bekannte Renten werden lebensversicherungsmathematisch, künftige additiv abgewickelt; D-F01 und D-F07 verfälschen Wahrscheinlichkeiten und Indexierung. |

## D.8 Sonderschäden

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.8.1 | Sonderschäden grafisch/quantilbasiert und im Austausch mit Schadenabteilung identifizieren (S. 18) | `plot_identify_special_claims()` `R/plots.R:47-154`; `special_claims` als Nutzereingabe `R/special_claims.R:102-120` | konform | – | – |
| D.8.2 | Erwartungswert und Auszahlungsmuster einzelfallweise deterministisch schätzen; Renten lebensversicherungsmathematisch (S. 18) | `compute_special_claims()` `R/special_claims.R:196-359`; `roll_out_single_claim()` `R/special_claims.R:28-72`; Renten `:313-318` | konform (Fehler) | C-F01, C-H01 | Einzelfallweise deterministische Schätzung ist umgesetzt; C-F01 erzeugt bei ungültigem Rollout_type still einen Null-Cashflow. |

## D.9 Rückversicherung

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.9.1 | RV-Programm je Schaden und Simulation: Quote, XL, Indexklausel, ggf. AAD/AAL, Ereignis-XL, Fakultativ (S. 18–19, 55) | `xl_cashflow()` `R/reinsurance.R:255-326`; `generate_xl_indices_per_claim()` `R/reinsurance.R:47-104`; `sicr()` `R/sicr.R:504-513` | abweichend | C-F02, C-F04, C-H05 | AAD/AAL sind nicht implementiert (C-H05); C-F04 verankert die Indexklausel ein Jahr zu früh, C-F02 betrifft nur die Ausgabewahl. |
| D.9.2 | Netto = Brutto nach RV-Programm; RV-Anteil = Brutto − Netto; Verteilung und Best Estimate (S. 55) | `sicr()` `R/sicr.R:544-565, 597-602`; `aggregate_large_claims_results()` `R/aggregate_large_claims_results.R:84-207` | konform (Fehler) | E-F01, E-F02 | Netto = Brutto minus RV-Anteil ist umgesetzt; E-F01 und E-F02 verfälschen die RV-Abgrenzung bei IBNR-XL und Quotenzuordnung. |
| D.9.3 | Adverse Pfade berücksichtigen, sodass Schäden unter Priorität RV-Anteil erhalten (S. 9, 19, 55) | `xl_cashflow()` `R/reinsurance.R:279-308`; `sicr()` `R/sicr.R:504-513` | konform | – | – |

## D.10 Auswertung, Backtesting, Sensitivitäten

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.10.1 | Best Estimate als Erwartungswert; zusätzlich Verteilung, Konfidenzintervalle und VaR (S. 7, 55) | `sicr()` Mittelwert `R/sicr.R:535-540`; Standardfehler `:266-281`; Summary `:609-610` | konform | – | Best Estimate und Standardfehler sind umgesetzt; Verteilung, Konfidenzintervalle und VaR nennt das Paper nur als Möglichkeit. |
| D.10.2 | Cashflow-Backtesting: prognostizierte vs. tatsächliche Zahlung im ersten Folgejahr (S. 22) | `backtesting_1y_per_reserve_class()` `R/plots.R:1209-1350`; `backtesting_1y_per_origin_year()` `R/plots.R:1434-1577`; `backtesting_1y_single_per_dev_year()` `R/plots.R:1667-1871` | konform (Fehler) | F-F01, F-F02 | Cashflow-Backtesting ist umgesetzt; F-F01 vergleicht nominale Erwartung mit indexiertem Ist, F-F02 vertauscht die Quantilslegenden. |
| D.10.3 | Ultimate-Backtesting gegen Benchmark 9 % bzw. 10 % durchführen (S. 22, 43, 49) | Keine Funktion vorhanden | fehlt | F-H01 | Ultimate-Backtesting gegen die Benchmarks 9 % und 10 % fehlt vollständig (F-H01). |
| D.10.4 | Sensitivitäten für Stichjahre, G, M, Klassen, Inflation und Abwicklungslänge ermöglichen (S. 23–24 u. a.) | `prepare_data()` `R/data_functions.R:726-733`; `generate_pools()` `R/generate_pools.R:61-68`; `add_transition_factor()` `R/data_functions.R:77-82` | konform | – | – |
| D.10.5 | Simulationskonvergenz und 1–2 % Rauschen bei Sensitivitäten berücksichtigen (S. 40) | `se()` `R/sicr.R:266-281`; Summary `R/sicr.R:609-610` | konform | – | – |
| D.10.6 | Variationsanalyse: alte Pools behalten, Abwicklungsstände und Parameter schrittweise ändern (S. 57) | Keine eigene Funktion; manuell über `sicr()` `R/sicr.R:113-128` mit Vorjahres-Pools; Beispiel `vignettes/sicr.Rmd:957-1024` | konform | – | Keine eigene Funktion nötig; Vorjahres-Pools und aktualisierte Daten lassen sich manuell an sicr() übergeben. |

## D.11 Dokumentationspflichten aus dem Bericht

| Nr. | Anforderung (eigene Worte, max. 15 Wörter, Seitenzahl) | Umsetzung in sicr (Funktion, R/datei.R:Zeile) | Einstufung | Befund-ID(s) aus analyse/ oder – | Begründung |
|---|---|---|---|---|---|
| D.11.1 | G, M, T, Klassen, Historienlänge, Ausschlüsse, Indexreihe und Indexjahr dokumentieren (S. 57) | `prepare_data()` `R/data_functions.R:560-637`; `generate_pools()` `R/generate_pools.R:3-12`; `add_transition_factor()` `R/data_functions.R:84-100`; Vignette `vignettes/sicr.Rmd:145-166, 304, 417-421` | konform | – | – |
| D.11.2 | Behandlung von Renten, Sonderschäden, Spätgroßschäden und Basisschäden dokumentieren (S. 13, 16–18) | `R/annuity_functions.R:88-104`; `R/special_claims.R:102-120`; `R/ibnr.R:318-336`; `compute_small_claims()` `R/small_claims.R:444-467` | konform | C-H03 | – |
| D.11.3 | RV-Programm und verwendete Vereinfachungen dokumentieren (S. 18–19) | `xl_cashflow()` `R/reinsurance.R:126-188`; `reinsurance_xmpl` `R/data.R:221-238` | konform | C-H05 | – |
| D.11.4 | Backtesting- und Sensitivitätsergebnisse je Bestand dokumentieren (S. 20–54) | Keine Ergebnissammlung im Paket; nur Backtesting-Funktionen `R/plots.R:1209-2120` | fehlt | F-H01 | Eine Ergebnissammlung je Bestand fehlt; nur Backtesting-Funktionen sind vorhanden (F-H01). |

## Zusammenfassung

| Einstufung | Anzahl |
|---|---:|
| konform | 31 |
| konform (Fehler) | 10 |
| abweichend | 2 |
| fehlt | 3 |
| Erweiterung | 0 |
| nicht im Paper | 0 |
| **Gesamt** | **46** |

*D.3.2, D.4.4, D.10.1, D.10.6 und D.5.5 sind nach erneuter Prüfung konform (D.5.5 von cl1 am Code geprüft: `R/sicr.R:475` rollt neue Renten über 130 Jahre aus). Grenzfälle bleiben D.6.1 (fehlendes Abwicklungsjahr N neben dem Sortierfehler C-F03) und D.9.1 (fehlendes AAD/AAL neben C-F02/C-F04). D.11.4 ist eine Dokumentationspflicht des Anwenders; „fehlt“ heißt hier nur, dass das Paket keine Ergebnissammlung anbietet.*
