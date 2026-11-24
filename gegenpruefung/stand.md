# Stand der Gegenprüfung

**Prüfobjekt:** sicr 1.1.1, `c0ad2ade80dad83b1d6faec1bd4e34bd20233c92` — am 2026-11-24 erneut geprüft:
`main` unverändert, 0 offene Issues, 0 Pull Requests, `packageVersion()` im Prüf-Image 1.1.1.

## Erledigt (mit Beleg)

| Schritt | Beleg |
|---|---|
| Prüfobjekt und Image verifiziert (Version, RemoteSha, R 4.4.2) | `reproduktion.md` §0 |
| Testsuite 2× gelaufen, deterministisch 76/76 | `logs/testergebnisse_{1,2}.csv` (Host) |
| Paper selbst gezogen (58 S., sha256 `a1628808…`), seitenweise extrahiert | `gegenpruefung/paper/seite_01..58.txt` |
| 30 Fehler: Both-ways (orig/patch/mutant) | `both_ways.csv`, `both_ways_roh.csv`, `both_ways.log`-Reihe |
| 30 Fehler: Reproduktion mit `library(sicr)` + Base R | `skripte/repro.R`; `skripte/pruefe_upstream.R` (13/13 ok) |
| Wirkung auf den Beispieldaten je schwerem Befund | `wirkung_roh.txt`, `wirkung_ef01.txt` |
| 12 Verbesserungen: Gleichheitstests grün, Benchmarks 3× | `logs/benchmark_1..3`; Faktoren als Spanne |
| 3 Fassungen `indices_ok_v` gegen das Original geprüft | `indices_varianten.txt` (alle „gleich“) |
| Metriken 1301 Zeilen / 0,390 / 770 lintr / Komplexität 53 | `logs/metriken_*.csv` (Host) |
| 46 Prüfpunkte gegen das PDF geprüft | `paper/seite_04,05,58.txt`: kein Anhang D |

## Offen / nicht belastbar

- **„Anhang D“ existiert im veröffentlichten Bericht nicht.** Die 46 Prüfpunkte sind eine eigene
  Gliederung des Prüfers; nur die Seitenbefunde (S. 5, 10, 11, 15, 16, 22, 55, 58) sind paper-belegt.
  Ob eine andere DAV-Fassung einen Anhang hat, ist **ungeklärt** — bis dahin sind die Einstufungen
  „konform (Fehler)“ / „fehlt“ nicht paper-belegt (Urteil: `widerlegt` für die Quelle, `umgedeutet`
  für die drei „fehlenden“ Punkte).
- **F-F01 „~16 %“** ist für die Beispieldaten nicht reproduziert: gemessen +9,1 % im ersten Folgejahr,
  +22,8 % nach fünf Jahren (Übergangsfaktor 1,0912 / 1,2282 bei Indexjahr 2022). Schwere bleibt
  „hoch“, Begründung neu.
- **E-F01 von „kritisch“ auf „hoch“**: auf den Beispieldaten 0,0 % Wirkung (kein IBNR-Schaden über
  der Priorität); mit Priorität 500.000 Ceded XL −7,07 %, Netto +2,85 %.
- **Blindregel nur teilweise protokolliert.** Für die Paper-Matrix ist die Reihenfolge dokumentiert
  (erst Seitenprüfung, dann cl1s `paper_abgleich.md`); für die 30 Codebefunde ist sie in dieser
  Session nicht je Befund festgehalten. Die Wirkungszahlen sind unabhängig gerechnet.
- **Verbesserungen ohne Mutanten.** Die 12 Gleichheitstests sind grün, aber nicht gegen eine
  absichtlich falsche `_v()`-Fassung getestet; „der Test würde eine falsche Fassung erkennen“ ist
  damit unbelegt.

## Nächster Schritt

1. Owner entscheidet über die Weitergabe von `upstream.md` an den Autor (kein Kontakt von hier).
2. Falls der Autor den Bericht ändern will: „Anhang D“ durch die eigene Gliederung ersetzen,
   Benchmark-Tabellen als Spanne, `analyse/gegenpruefung_DEF.md` mit Lesehilfe (Stand `c83d9cd`).
3. Offene Frage an den Owner: Papierfassung mit Anhang D — gibt es eine andere DAV-Version?
