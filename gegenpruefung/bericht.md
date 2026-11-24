# Gegenuntersuchung des sicr-Audits — Bericht

## Urteil

Das Audit hält. Alle 30 Fehlerbefunde lassen sich gegen unverändertes sicr nachstellen, und alle 30
Befundtests **diskriminieren**: Wird die Originalfunktion durch die vorgeschlagene Korrektur ersetzt,
wird der Test rot; wird sie durch einen offensichtlich falschen Mutanten ersetzt, ebenfalls. Das war
die eigentliche offene Frage („grün gegen sicr und grün gegen `_v()`“) und sie ist beantwortet: die
Tests prüfen den Codepfad, nicht nur eine zweite Funktion. 29 Befunde bestätige ich unverändert,
einen schwäche ich ab: **E-F01 ist auf den Beispieldaten wirkungslos (0,0 %) und deshalb „hoch“, nicht
„kritisch“** — mit einer Priorität von 500.000 ändert die Korrektur das zedierte XL um −7,07 % und
die Nettoreserve um +2,85 %. Eine Zahl korrigiere ich: **F-F01 verzerrt im Beispiel um 9,1 % (nicht
~16 %); 16 % wären fünf Jahre Abstand bei 3 %.** Alle 30 Befunde sind übergabereif; übernommen aus dem
Audit werden 29, einer mit neuer Schwere.

Was fällt, fällt auf der Ebene des Berichts, nicht der Befunde:

- **„46 Prüfpunkte aus Anhang D“ ist falsch.** Der 58-seitige DAV-Bericht hat keinen Anhang D; das
  Inhaltsverzeichnis endet bei 3.2.9 (S. 5), die letzte Seite ist 58. Die 46 Punkte (D.1–D.11) sind
  eine eigene, plausible Gliederung des Prüfers. Der Bericht muss das sagen; die Punkte selbst
  bleiben brauchbar.
- **Von den drei „fehlenden“ Paper-Punkten ist keiner eine Paketanforderung**: G unter der Priorität
  ist eine Empfehlung („sollte“, S. 11), Ultimate-Backtesting ist die Anwendung der UAG (Kap. 3),
  Ergebnisdokumentation ist Pflicht des Anwenders. Sie gehören unter „optional“.
- **Benchmark-Faktoren sind Einzelmedians.** Derselbe Code, drei Läufe: C-V02 10,6/11,1/14,5 ms
  (Faktor 6,5–11,3 statt 8,4), E-V01 6,3–7,9, F-V01 1,8–2,9, A-V01 1,4–2,5. Die Richtung stimmt
  überall, die Punktwerte sind nicht reproduzierbar; Spannen berichten.
- **`plots.R` hat 1301 Codezeilen, nicht 1372.** `skripte/metriken.R` liefert 1301, Duplikatanteil
  0,390, lintr 770, Komplexität `sicr()` 53 — alles identisch zum Bericht. Die 1372 stehen nur in
  `analyse/gegenpruefung_DEF.md:36` und sind dort falsch.
- **„76 Tests“ sind 76 `test_that`-Blöcke mit 200 Assertions**, nicht 76 Fehlertests; davon sind 30
  Fehlerbelege, 30 Korrekturbelege und 16 Gleichheits-/Korrektheitsnachweise. Der Bericht sagt das
  an einer Stelle richtig, im README steht die Kurzform.
- **Die Gegenprüfungsdateien beschreiben einen älteren Stand.** `gegenpruefung_DEF.md:11` nennt
  D-F01 weiter falsch (`cbind(probs[,-1],1)`), während `verbesserungen/D-F01.R` heute anders rechnet
  und der Test q(50)=1/q(51)=0 nutzt. Der Kopf sagt „Wort für Wort so belassen“ — es fehlt nur die
  Lesehilfe „Review-Stand c83d9cd, Endstand 0548983“.

Unprüfbar bleibt wenig: die Benchmark-Punktwerte (Instabilität), die Wirkung von E-F01 auf *fremden*
Portfolios (programmabhängig) und die Frage, ob die 30 Fehler die einzigen sind — mein Sweep über die
vier Fehlerklassen (Positionszuordnung, `1:n`, Literal in `is.null`/`==`, `&`/`|` in `if`) und die
vollständige Lektüre von `sicr()` fanden nichts Neues; das ist ein begrenzter, kein vollständiger
Beweis.

## Zahlen

| Größe | Audit | Gegenprüfung | Urteil |
|---|---:|---:|---|
| Fehler | 30 | 30 | 29 bestätigt, 1 abgeschwächt (E-F01) |
| Schwere | 1 kritisch / 7 hoch / 17 mittel / 5 niedrig | 0 / 8 / 17 / 5 | E-F01 kritisch→hoch |
| Tests | 76 grün | 76 grün, 2 Läufe identisch | bestätigt (200 Assertions) |
| Diskrimination | nicht geprüft | 30/30 both-ways + Mutant rot | bestätigt |
| Verbesserungen | 12, 6 schneller | 12, Gleichheitstests grün | bestätigt; Faktoren als Spanne |
| Prüfpunkte | 46 („Anhang D“) | 46 eigene Punkte, kein Anhang D | Herkunft widerlegt |
| `plots.R` Codezeilen | 1301 | 1301 | bestätigt; „1372“ falsch |
| lintr | 770 | 770 | bestätigt |
| Benchmark C-V02 | 8,4× | 6,5–11,3× (3 Läufe) | Punktwert nicht reproduzierbar |

## Wirkung der schweren Befunde (Beispieldaten, selbst gemessen)

| ID | Messung | Zahl |
|---|---|---|
| E-F01 | Nettoreserve, Beispielprogramm (Prio 1,0–1,5 Mio.) | 0,00 % |
| E-F01 | Nettoreserve, Priorität 500.000 | +2,85 % (Ceded XL −7,07 %) |
| A-F01 | Nachlaufpoolmasse, Grenzen 0/100k · 0/250k · 0/500k | −4,95 % · −3,82 % · −2,90 % |
| B-F01 | Jahre mit falschem Index bei permutierter Reihe / max. Abweichung | 19,7 % / 26,2 % |
| C-F03 | erwartete IBNR-Schäden, permutierte Exposure | 35 statt 43 (−18,6 %) |
| D-F03, E-F02 | Anfalljahre mit falscher Quote / max. Abweichung | 19 von 35 / 50 Pp. |
| D-F07 | künftige Basisrenten, Indexjahr 2022 vs. 2018 | −10,6 % (Mini-Fall −7,6 %) |
| D-F01 | undiskontierte Rentenzahlungen | +1,86 % (9.239.437 vs. 9.070.927) |
| F-F01 | Verzerrung 1. Folgejahr / nach 5 Jahren | +9,1 % / +22,8 % |

## Urteile je Behauptung

Vollständig in [`urteile.csv`](urteile.csv) (30 Fehler, 12 Verbesserungen, 3 Paper-Punkte, 3
Berichts-Behauptungen). Both-ways je ID in [`both_ways.csv`](both_ways.csv); Rohprotokoll in
[`both_ways_roh.csv`](both_ways_roh.csv), Testprotokolle in `logs/`.

## Grenzen dieser Gegenprüfung

- Die Reihenfolge „blind vor belegt“ ist für die Paper-Matrix nicht eingehalten: Ich habe
  `analyse/paper_abgleich.md` gelesen, um die behauptete Quelle („Anhang D“) zu identifizieren, bevor
  ich die Punkte selbst formuliert hatte. Die Seitenprüfungen selbst (S. 5, 10, 11, 15, 16, 22, 55, 58)
  sind unabhängig, die Einstufungen der 46 Punkte nicht blind.
- Die Verbesserungen habe ich auf Gleichheit (Tests grün) und Benchmark-Spanne geprüft, aber keinen
  Mutanten gegen die Gleichheitstests gesetzt; „der Gleichheitstest würde eine falsche `_v()` erkennen“
  ist damit **unbelegt**.
- Die Wirkungszahlen gelten für die Beispieldaten des Pakets und n = 1 Realisation (E-F01), nicht für
  fremde Bestände.
