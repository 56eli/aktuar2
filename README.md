# aktuar2: Prüfung des R-Pakets sicr 1.1.1

Diese Prüfung untersucht alle 83 Funktionen des R-Pakets [sicr](https://github.com/dskowasch/sicr) von Dirk
Skowasch (Version 1.1.1, Commit `c0ad2ad`) auf drei Fragen:

1. **Paperkonformität:** Passt die Umsetzung zum DAV-Ergebnisbericht
   [„Stochastische Einzelschadenreservierung“ (04.02.2025)](https://aktuar.de/content/PDF/Fachwissen/2025-02-04_DAV_SV_EB_Stochastische_Einzelschadenreservierung.pdf)?
2. **Fehler:** Wo rechnet der Code falsch? Jeder Fehler ist durch einen testthat-Test belegt.
3. **Verbesserungen:** Wie wird der Code kürzer, lesbarer, eleganter oder schneller? Zu jedem Vorschlag gibt es
   lauffähigen Code, einen Gleichheitstest und bei Effizienzvorschlägen einen Benchmark. Der Gleichheitstest
   zeigt nur, dass das Ergebnis gleich bleibt; den Nutzen belegt der Benchmark.

Die gesamte wissenschaftliche Arbeit ist in R gerechnet.

**→ [Prüfbericht lesen](bericht/bericht.md)**

## Ergebnis auf einen Blick

| | |
|---|---|
| Geprüfte Funktionen | 83 (77 exportiert, 6 intern) in 17 Dateien |
| Prüfpunkte aus Anhang D des Berichts | 46: 31 konform · 10 konform, aber durch einen Fehler beeinträchtigt · 2 abweichend · 3 fehlen |
| Belegte Fehler | 30: 1 kritisch · 7 hoch · 17 mittel · 5 niedrig |
| Verbesserungen | 12, davon 6 gemessen schneller (1,8× bis 8,4×) |
| Tests | 76, alle bestanden ([`ergebnisse/testergebnisse.csv`](ergebnisse/testergebnisse.csv)) |

Die wichtigsten Befunde:

- **E-F01 (kritisch):** In den aggregierten Großschadendreiecken fehlt der XL-Anteil der Spätgroßschäden, die
  Nettoreserve ist dort zu hoch.
- **B-F01, C-F03, D-F03, E-F02 (hoch):** Historische Indizes, Exposure und Quoten werden nach Zeilenposition statt
  nach Jahr zugeordnet. Bei unsortierter Eingabe entstehen ohne Meldung falsche Werte.
- **F-F01 (hoch):** Das Backtesting vergleicht nominale Prognosen mit deflationierten Ist-Zahlungen.
- **A-F01, D-F07 (hoch):** Die Ausreißergrenzen im Nachlauf greifen auf dem falschen Niveau, und die künftigen
  Basisrenten hängen vom gewählten Indexjahr ab.
- **Paper:** Das Verfahren ist im Kern berichtskonform. Methodisch fehlen das letzte Abwicklungsjahr im additiven
  Spätschadenmodell (C-F05), AAD/AAL in der Rückversicherung und das Ultimate-Backtesting.

## Aufbau

| Pfad | Inhalt |
|---|---|
| [`bericht/bericht.md`](bericht/bericht.md) | Prüfbericht mit Grafiken, gerendert aus `bericht.Rmd` |
| [`analyse/`](analyse/) | Sechs Gruppenanalysen A–F mit je einem Abschnitt pro Funktion, dazu die [Paperabgleich-Matrix](analyse/paper_abgleich.md) und die Gegenprüfungen |
| [`befunde/`](befunde/) | `test-<ID>.R`: ein Test je Fehler. Grün heißt, der Fehler besteht in sicr 1.1.1. Ein zweiter Test zeigt die Korrektur. |
| [`verbesserungen/`](verbesserungen/) | `<ID>.R`: Korrekturen und Verbesserungen als Funktionen `<name>_v()` |
| [`tests/verbesserungen/`](tests/verbesserungen/) | Gleichheitstests der Verbesserungen gegen das Original |
| [`bench/`](bench/) | Benchmarks der Effizienzvorschläge (`bench::mark`) |
| [`skripte/`](skripte/) | Testlauf, Einzeltest, Benchmarks, Code-Metriken |
| [`ergebnisse/`](ergebnisse/) | Testergebnisse, Benchmarks und Metriken als CSV |
| [`docker/`](docker/) | Image mit R 4.4.2 und sicr 1.1.1 an Commit `c0ad2ad` |

**IDs:** `<Gruppe>-F<nn>` Fehler, `-V<nn>` Verbesserung, `-H<nn>` Hinweis, `-K<nn>` Korrektheitsnachweis.
Gruppen: A Kernsimulation · B Datenaufbereitung · C IBNR, Sonderschäden, Rückversicherung · D Renten und
Basisschäden · E Ausgabe und Eingabeprüfungen · F Plots und Backtesting.

**Schwere:** *kritisch*: Reserve oder Verteilung im Normalfall falsch · *hoch*: falsch in realistischen
Datenlagen · *mittel*: Randfall oder Absturz · *niedrig*: Stil, Doku.

## Reproduzieren

```sh
docker build -t aktuar-r:1 docker
docker run --rm -v "$PWD":/work -w /work aktuar-r:1 Rscript skripte/tests_ausfuehren.R   # alle Tests
docker run --rm -v "$PWD":/work -w /work aktuar-r:1 Rscript skripte/einzeltest.R befunde/test-E-F01.R
docker run --rm -v "$PWD":/work -w /work aktuar-r:1 Rscript skripte/benchmarks.R
```

Wie Metriken und Bericht entstehen, steht im Abschnitt [Reproduktion](bericht/bericht.md#reproduktion) des
Berichts. Die GitHub-Action [`r-tests.yml`](.github/workflows/r-tests.yml) führt alle Tests bei jedem Push aus.

## Hinweise

- Der DAV-Bericht liegt aus urheberrechtlichen Gründen nicht im Repo. Er ist verlinkt und wird mit Seitenzahl
  zitiert.
- Die Verbesserungen sind Einzelfunktionen zum Nachvollziehen, kein Fork von sicr.
- Lizenz: [GPL-3](LICENSE) wie sicr, weil Korrekturen und Verbesserungen aus dessen Code abgeleitet sind.
