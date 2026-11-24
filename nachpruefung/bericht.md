# Nachprüfung (Runde 3) des sicr-Audits

## Urteil

Die Gegenprüfung aus Runde 2 hält im Kern. Runde 3 bestätigt mit eigenen Skripten, dass alle 30 Fehler gegen
unverändertes sicr nachstellbar sind, dass die Befundtests diskriminieren und dass die Wirkungszahlen der
schweren Befunde in der berichteten Größenordnung stimmen. Sie bestätigt außerdem, dass der DAV-Bericht keinen
Anhang D hat und die 46 Prüfpunkte eine eigene Checkliste sind.

Korrigiert werden drei Punkte: **F-F01** wirkt im Vignetten-Backtesting nicht „rund 16 %“, sondern hebt den
Ist-Wert um den Faktor 1,0595 an (+5,95 %); die Runde-2-Zahlen +9,1 % / +22,8 % gehören zu Jahren, für die das
Beispiel keine Daten hat. **D.11.4** ist keine Anwenderpflicht, sondern ohne Paperbezug, weil das Paper kein Wort
„Dokumentation“ enthält. Und die kleine Fehlerliste aus Runde 2 (F11) ist bereinigt.

## Zahlen: Audit | Runde 2 | Runde 3 | Urteil

| Größe | Audit | Runde 2 | Runde 3 | Urteil |
|---|---:|---:|---:|---|
| Prüfpunkte | 46: 31 konform, 10 konform (Fehler), 2 abweichend, 3 fehlen | 46, davon 3 ohne Paketanforderung | 46: 31 · 10 · 2 · 2 optional · 1 kein Paperbezug · 0 fehlen | Herkunft korrigiert, Zählung bestätigt |
| Fehler | 30: 1 kritisch, 7 hoch, 17 mittel, 5 niedrig | 30: 0 · 8 · 17 · 5 | 30: 0 · 8 · 17 · 5 | E-F01 kritisch→hoch bestätigt |
| Tests | 76 grün | 76 grün, 200 Assertions, 2 Läufe identisch | 76 grün, am 2026-11-24 erneut gelaufen | bestätigt |
| Diskrimination | nicht geprüft | 30/30 both-ways | 10/10 eigene Mutanten, 12/12 Verbesserungsmutanten | bestätigt und Lücke geschlossen |
| E-F01 | kritisch | 0,0 % im Beispiel; Prio 500.000: −7,07 % XL / +2,85 % netto | Prio 500.000: −7,04 % XL / +2,91 % netto (n = 1) | hoch, zwei unabhängige Läufe |
| F-F01 | „rund 16 %“ | +9,1 % / +22,8 % (Jahre ohne Beispieldaten) | +5,95 % im Vignettenfall (Faktor 1,0595) | Runde-3-Zahl gilt |
| D.11.4 | fehlt | „Anwenderpflicht“ (nicht belegt) | kein Paperbezug | Runde 3 korrigiert |
| `plots.R` | 1301 Codezeilen | 1301, Duplikatanteil 0,390 | 1301, Duplikatanteil 0,39 | bestätigt; „1372“ gestrichen |
| Benchmark C-V02 | 8,4× | 6,5–11,3× (3 Läufe) | 8,2–11,4× (5 Läufe) | nur Spannen berichten |

## Wirkung der schweren Befunde (Beispieldaten)

| ID | Messung | Runde 3 |
|---|---|---:|
| A-F01 | Nachlaufpoolmasse, Grenzen 0/100k · 0/250k · 0/500k | −4,95 % · −3,82 % · −2,90 % |
| D-F01 | undiskontierte Rentenzahlungen | +1,86 % (9.239.437 statt 9.070.927) |
| D-F07 | künftige Basisrenten, Indexjahr 2022 gegen 2018 | −10,6 % |
| E-F01 | zediertes XL / Nettoreserve, Priorität 500.000 | −7,04 % / +2,91 % |
| F-F01 | Ist-Wert im Vignetten-Backtest 2023 (Indexjahr 2022) | +5,95 % |
| B-F01 | Jahre mit falschem Index nach Permutation (Seed 42) | 20,4 % (Runde 2: 19,7 %) |
| C-F03 | erwartete IBNR-Schäden nach Permutation (Seed 42) | 38,3 statt 43,9 (Runde 2: 35 statt 43) |
| D-F03/E-F02 | Anfalljahre mit falscher Quote / max. Abweichung | 22 von 35 / 50 Prozentpunkte |

B-F01, C-F03 und D-F03/E-F02 hängen von der zufälligen Permutation ab. Die Zahlen sind Illustrationen der
Mechanismen, keine festen Punktwerte. Quelle: [`ergebnisse/wirkung.csv`](ergebnisse/wirkung.csv).

## Belastbarkeit der Tests

Runde 2 hat alle 30 Fehler both-ways geprüft: Original grün, Korrektur rot, Mutant rot. Runde 3 wiederholte das
mit eigenen Mutanten für eine Stichprobe von 10 Befunden (A-F01, B-F01, C-F03, C-F05, D-F01, D-F03, D-F07, E-F01,
E-F02, F-F01); alle 10 unterscheiden
([`both_ways_stichprobe.csv`](ergebnisse/both_ways_stichprobe.csv)). Zusätzlich wurden alle 12
Verbesserungen mit einem absichtlich falschen `_v()`-Mutanten geprüft; alle 12 Gleichheitstests werden rot
([`mutanten_verbesserungen.csv`](ergebnisse/mutanten_verbesserungen.csv)). Der R-Port der Both-ways-Auswertung
reproduziert `gegenpruefung/both_ways.csv` inhaltlich identisch; Python schrieb dort nur CRLF-Zeilenenden.

## Benchmarks

Fünf Läufe bestätigen die Richtung, nicht die Punktwerte. A-V01 1,7–2,0× · C-V02 8,2–11,4× · D-V01 3,1–4,4× ·
D-V02 3,2–4,2× · E-V01 6,4–6,6× · F-V01 2,2–2,5× schneller; A-V02 0,63–0,70× und B-V02 0,49–0,75× langsamer,
beide bleiben als Lesbarkeitsverbesserungen. Einzelmedians sind nicht reproduzierbar.
Quelle: [`ergebnisse/benchmarks_spanne_zusammenfassung.csv`](ergebnisse/benchmarks_spanne_zusammenfassung.csv).

## Kleine Fehler in Runde 2 (F11)

- `gegenpruefung/urteile.csv` hat vier Paper-Zeilen, nicht drei.
- Die Zahl „1372“ stand nicht nur in `analyse/gegenpruefung_DEF.md:36`, sondern auch in
  `analyse/F_plots_backtesting.md:7,97`; beide Stellen nennen jetzt 1301 Codezeilen und Duplikatanteil 0,39.
- `gegenpruefung/skripte/repro.R` hat keinen Block für F-F01.
- Die in `gegenpruefung/stand.md` zitierten Logs (`testergebnisse_1/2`, `benchmark_1..3`, `metriken_*`) liegen
  nicht im Repo.
- Die Paper-Seitenextrakte sind aus Urheberrechtsgründen gitignored; die Anhang-D-Widerlegung war deshalb aus dem
  Repo nicht nachprüfbar. Runde 3 hat das PDF unabhängig neu gezogen (gleiche sha256 `a1628808…`).

## Grenzen

- E-F01 ist mit n = 1 und Seed 12345 gemessen; die Größe hängt vom Bestand und der Priorität ab.
- Die Permutationszahlen zu B-F01, C-F03 und D-F03/E-F02 sind seed-abhängig (Seed 42).
- Die eigene Mutantenstichprobe umfasst 10 der 30 Fehler, nicht alle 30.
- Die Verbesserungsmutanten verändern die Ausgabe der echten `_v()`-Funktion, nicht deren Code; geprüft ist die
  Diskrimination des Gleichheitstests, nicht jede denkbare Fehlfassung.
- Das PDF wurde über Textextraktion durch einen Worker geprüft, nicht Zeile für Zeile visuell.

## Reproduktion

Alle Skripte laufen aus der Repo-Wurzel; `<sicr>` ist ein Checkout von sicr an Commit `c0ad2ad`.

```sh
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/wirkung.R
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/both_ways_stichprobe.R
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/mutanten_verbesserungen.R
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/benchmarks_spanne.R 5
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/f_f01_vignette.R
```

Die vollständige Befehlsliste steht in [`README.md`](README.md).
