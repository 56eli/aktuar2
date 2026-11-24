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
**→ [Präsentation](praesentation/praesentation.html)** (selbstenthaltene HTML-Datei zum Herunterladen und Öffnen)

## Ergebnis auf einen Blick

| | |
|---|---|
| Geprüfte Funktionen | 83 (77 exportiert, 6 intern) in 17 Dateien |
| Prüfpunkte | 46 eigene Punkte D.1–D.11, aus Kapitel 2 abgeleitet (der DAV-Bericht hat keinen Anhang D): 31 konform · 10 konform (Fehler) · 2 abweichend · 2 optional · 1 kein Paperbezug · 0 fehlen |
| Belegte Fehler | 30: 0 kritisch · 8 hoch · 17 mittel · 5 niedrig |
| Wirkung | A-F01 −2,9 bis −5,0 % Poolmasse · D-F01 +1,86 % · D-F07 −10,6 % · E-F01 −7,04 % zediertes XL / +2,91 % netto (Prio 500.000, n = 1) · F-F01 +5,95 % im Vignettenfall |
| Verbesserungen | 12: 6 gemessen schneller (1,7–2,0× bis 8,2–11,4×), 2 langsamer (nur Lesbarkeit), 4 ohne Benchmark |
| Tests | 76 `test_that`-Blöcke mit 200 `expect_`-Aufrufen: 62 in `befunde/` (Fehler- und Korrekturbelege; C-F05 vereint beide in einem Block), 14 Gleichheitstests in `tests/verbesserungen/`; alle grün ([`ergebnisse/testergebnisse.csv`](ergebnisse/testergebnisse.csv)) |

Die wichtigsten Befunde:

- **E-F01 (hoch):** In den aggregierten Großschadendreiecken fehlt der XL-Anteil der Spätgroßschäden. Auf den
  Beispieldaten ist die Wirkung 0,0 %, weil kein IBNR-Schaden die Beispielprioritäten (1,0–1,5 Mio.) übersteigt;
  mit Priorität 500.000 ändert die Korrektur das zedierte XL um −7,04 % und die Nettoreserve um +2,91 %.
- **B-F01, C-F03, D-F03, E-F02 (hoch):** Historische Indizes, Exposure und Quoten werden nach Zeilenposition statt
  nach Jahr zugeordnet. Bei unsortierter Eingabe entstehen ohne Meldung falsche Werte.
- **F-F01 (hoch):** Das Backtesting vergleicht nominale Prognosen mit deflationierten Ist-Zahlungen. Der
  Bias-Faktor ist der `Transition_factor` des Backtestjahres relativ zum Indexjahr; im Vignettenfall 2022/2023
  hebt die Korrektur den Ist-Wert um 5,95 % an.
- **A-F01, D-F07 (hoch):** Die Ausreißergrenzen im Nachlauf greifen auf dem falschen Niveau, und die künftigen
  Basisrenten hängen vom gewählten Indexjahr ab.
- **Paper:** Das Verfahren ist im Kern berichtskonform. Die 46 Punkte sind eine eigene Checkliste, kein Anhang des
  Berichts. Methodisch abweichend bleiben das letzte Abwicklungsjahr im additiven Spätschadenmodell (C-F05) und
  AAD/AAL in der Rückversicherung; Ultimate-Backtesting und die Großschadenschwelle sind optional, die
  Ergebnisdokumentation hat keinen Paperbezug.

## Prüfrunden

| Runde | Ordner | Ergebnis |
|---|---|---|
| 1 – Audit | `analyse/`, `befunde/`, `verbesserungen/`, `bericht/` | 30 Fehler, 12 Verbesserungen, 46 eigene Prüfpunkte; Bericht und Grafiken |
| 2 – Gegenprüfung (seat oc1) | [`gegenpruefung/`](gegenpruefung/) | alle 30 Fehler both-ways bestätigt; E-F01 kritisch→hoch; „Anhang D“ widerlegt; F-F01-Zahl relativiert |
| 3 – Nachprüfung (cl1) | [`nachpruefung/`](nachpruefung/) | F-F01 im Vignettenfall +5,95 %; D.11.4 ohne Paperbezug; 10/10 eigene Mutanten, 12/12 Verbesserungsmutanten; Benchmark-Spannen aus 5 Läufen |

## Aufbau

| Pfad | Inhalt |
|---|---|
| [`bericht/bericht.md`](bericht/bericht.md) | Prüfbericht mit Grafiken, gerendert aus `bericht.Rmd` |
| [`praesentation/praesentation.html`](praesentation/praesentation.html) | Foliensatz (12 Folien), selbstenthaltene HTML-Datei zum Herunterladen und Öffnen |
| [`analyse/`](analyse/) | Sechs Gruppenanalysen A–F mit je einem Abschnitt pro Funktion, dazu die [Paperabgleich-Matrix](analyse/paper_abgleich.md) und die Gegenprüfungen |
| [`befunde/`](befunde/) | `test-<ID>.R`: ein Test je Fehler. Grün heißt, der Fehler besteht in sicr 1.1.1. Ein zweiter Test zeigt die Korrektur. |
| [`verbesserungen/`](verbesserungen/) | `<ID>.R`: Korrekturen und Verbesserungen als Funktionen `<name>_v()` |
| [`tests/verbesserungen/`](tests/verbesserungen/) | Gleichheitstests der Verbesserungen gegen das Original |
| [`bench/`](bench/) | Benchmarks der Effizienzvorschläge (`bench::mark`) |
| [`gegenpruefung/`](gegenpruefung/) | Runde 2: unabhängige Gegenprüfung, Both-ways-Tests, Urteile |
| [`nachpruefung/`](nachpruefung/) | Runde 3: eigene Skripte, Mutanten, Wirkungs- und Benchmark-Spannen |
| [`skripte/`](skripte/) | Testlauf, Einzeltest, Benchmarks, Code-Metriken, gemeinsame Grafiken, Rendern |
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
docker run --rm -v "$PWD":/work -w /work aktuar-r:1 Rscript skripte/render.R              # Bericht und Präsentation
```

Runde 3 läuft aus der Repo-Wurzel; `<sicr>` ist ein Checkout von sicr an Commit `c0ad2ad`:

```sh
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/wirkung.R
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/both_ways_stichprobe.R
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/mutanten_verbesserungen.R
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/benchmarks_spanne.R 5
docker run --rm -e HOME=/tmp -e AKTUAR_ROOT=/work -v "$PWD":/work -v /tmp/sicr:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/f_f01_vignette.R
```

Wie Metriken und Bericht entstehen, steht im Abschnitt [Reproduktion](bericht/bericht.md#reproduktion) des
Berichts. Die GitHub-Action [`r-tests.yml`](.github/workflows/r-tests.yml) führt alle Tests bei jedem Push aus.

## Hinweise

- Der DAV-Bericht liegt aus urheberrechtlichen Gründen nicht im Repo. Er ist verlinkt und wird mit Seitenzahl
  zitiert.
- Die Verbesserungen sind Einzelfunktionen zum Nachvollziehen, kein Fork von sicr.
- Lizenz: [GPL-3](LICENSE) wie sicr, weil Korrekturen und Verbesserungen aus dessen Code abgeleitet sind.
