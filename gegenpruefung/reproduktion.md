# Reproduktion der Gegenprüfung

Alles hier läuft offline in einem Container; das Prüfobjekt `sicr` wird **nicht** verändert (read-only
gemountet) und **nicht** gepatcht — Korrekturen werden im laufenden R-Prozess per
`assignInNamespace`/Body-Ersetzung eingesetzt (`gegenpruefung/skripte/patch_helpers.R`).

## 0. Umgebung

```sh
git clone https://github.com/56eli/aktuar2 audit            # Audit, main = 0548983
git clone https://github.com/dskowasch/sicr sicr            # Prüfobjekt
git -C sicr rev-parse HEAD                                  # c0ad2ade80dad83b1d6faec1bd4e34bd20233c92
docker build -t aktuar-r:1 audit/docker                     # R 4.4.2 + sicr 1.1.1 aus dem Tarball dieses Commits
docker build -t aktuar-gegen:1 -f audit/gegenpruefung/docker/Dockerfile.gegen .
```

Prüfwert im Image (ein Kommando, eine Zeile Beleg):

```sh
docker run --rm aktuar-r:1 Rscript -e 'library(sicr); cat(as.character(packageVersion("sicr")), packageDescription("sicr")$RemoteSha, R.version.string, "\n")'
# 1.1.1 c0ad2ade80dad83b1d6faec1bd4e34bd20233c92 R version 4.4.2 (2024-10-31)
```

Der Klon muss für die UID, mit der der Container läuft (`-u`), lesbar sein; dafür genügen Eigentümer-
oder Gruppenrechte. Verzeichnisse nicht für alle (`o+rx`) freigeben.

Der Aufruf, mit dem alle folgenden Schritte laufen (`$A` = Verzeichnis des Audit-Klons, `$S` = des
sicr-Klons):

```sh
docker run --rm -u 10004:10005 -e HOME=/tmp -e AKTUAR_ROOT=/work \
  -v "$A":/work -v "$S":/sicr:ro -w /work aktuar-r:1 <befehl>
```

## 1. Testsuite des Audits (Determinismus)

```sh
Rscript skripte/tests_ausfuehren.R          # zweimal ausführen
```

Erwartet: 76 `test_that`-Blöcke, 76 bestanden, 0 fehlgeschlagen, 0 Abbruch, 0 übersprungen; die
Spalten `datei/test/ok` beider Läufe und von `ergebnisse/testergebnisse.csv` sind identisch, nur
`sekunden` differiert. Nachzählen: `grep -rho "expect_[a-z_]*(" befunde tests | wc -l` → 200.

## 2. Both-ways: unterscheidet jeder Befundtest?

```sh
sh gegenpruefung/skripte/bw1.sh      # A-F01 .. C-F05, legt both_ways_roh.csv neu an
sh gegenpruefung/skripte/bw2.sh      # D-F01 .. E-F05
sh gegenpruefung/skripte/bw3.sh      # E-F06 .. F-F03
sh gegenpruefung/skripte/bw_rest.sh  # nur falls ein Lauf abbricht: F-F01 .. F-F03 nachziehen
python3 gegenpruefung/skripte/both_ways_auswerten.py
```

Ein Lauf je ID und Modus (`orig` = unverändertes sicr, `patch` = Originalfunktion durch die
Korrektur aus `verbesserungen/<ID>.R` ersetzt, `mutant` = offensichtlich falsche Funktion). Erwartet
in `gegenpruefung/both_ways.csv` für alle 30 Zeilen: `failed_original = 0`, `failed_patch ≥ 1`,
`diskriminiert = ja`, `mutation_testet = ja`.

## 3. Reproduktion jedes Befunds in einem Prozess

```sh
Rscript gegenpruefung/skripte/repro.R    # druckt je ID den beobachteten falschen Wert
```

Prüft zusätzlich, dass die Blöcke aus `upstream.md` wie abgedruckt laufen:

```sh
Rscript gegenpruefung/skripte/pruefe_upstream.R
# Blöcke gefunden: 13 / je Block "ok"
```

## 4. Wirkung auf den Beispieldaten des Pakets

```sh
Rscript gegenpruefung/skripte/beispiel_basis.R      # baut gegenpruefung/cache/basis.rds
sh gegenpruefung/skripte/wirkung_lauf.sh            # D-F01 A-F01 B-F01 C-F03 D-F03 E-F02 D-F07 F-F01
Rscript gegenpruefung/skripte/wirkung_ef01.R 1              # E-F01, Beispielprogramm
Rscript gegenpruefung/skripte/wirkung_ef01.R 1 500000       # E-F01, Priorität 500.000
```

Erwartete Zeilen (Protokoll: `gegenpruefung/wirkung_roh.txt`, `wirkung_ef01.txt`):

```
D-F01 undiskontiert: original 9239437, korrigiert 9070927, Abweichung +1.86 %
A-F01 Grenzen 0/100000: original 14937148, korrigiert 15715053, Abweichung -4.95 %
A-F01 Grenzen 0/250000: ... -3.82 %      A-F01 Grenzen 0/500000: ... -2.90 %
B-F01 permutierte Indizes: 19.7 % der Jahre weichen ab, max 26.22 %
C-F03 erwartete IBNR-Schäden: original 35, korrigiert 43, Abweichung -18.6 %
D-F03/E-F02 permutierte RV-Jahre: 19 von 35 Anfalljahren, max 50.0 Prozentpunkte
D-F07 künftige Basisrenten: 2022 310978, 2018 347997, Abweichung -10.6 %; korrigiert 0.00
F-F01 Verzerrung je Jahr +9.1 %, nach 5 Jahren +22.8 %
E-F01 Beispielprogramm: Netto 0.00 %; Priorität 500.000: Ceded XL -7.07 %, Netto +2.85 %
```

## 5. Verbesserungen: Verhalten und Regression

```sh
Rscript gegenpruefung/skripte/indices_varianten.R
```

Erwartet: `E-F04`, `E-F05`, `E-V01` und das **Original** `indices_ok` liefern in allen vier Fällen
(gültig, ohne `Index_re`, `Calendar_year` als `double`, unsortiert) dasselbe; die Zeilen
„gleich gleich gleich“ belegen, dass keine der drei Fassungen das Originalverhalten ändert
(`gegenpruefung/indices_varianten.txt`). Benchmarks in `ergebnisse/benchmarks.csv`, dreimal gelaufen
(`logs/benchmark_1..3`): Faktoren als Spanne, nicht als Median.

## 6. Metriken

```sh
Rscript skripte/metriken.R /sicr
```

Erwartet für `R/plots.R`: 1301 Codezeilen, Duplikatanteil 0,390; lintr 770 Meldungen
(`logs/metriken_lintr.csv`), höchste Komplexität `sicr()` 53.

## 7. Paper als Primärquelle

```sh
curl -o paper.pdf https://aktuar.de/content/PDF/Fachwissen/2025-02-04_DAV_SV_EB_Stochastische_Einzelschadenreservierung.pdf
sha256sum paper.pdf        # a1628808cd71eb7208301841aeb0e5daa6caa9e04738e34dc65c3d9561f200af
pdfinfo paper.pdf | grep Pages    # 58
for p in $(seq 1 58); do pdftotext -f $p -l $p -layout paper.pdf gegenpruefung/paper/seite_$(printf %02d $p).txt; done
grep -il "anhang\|prüfpunkt\|checkliste" gegenpruefung/paper/*.txt    # leer
```

Erwartet: das Inhaltsverzeichnis (S. 4–5) endet bei 3.2.9, die letzte Seite ist 58, es gibt keinen
Anhang D und keine Prüf-Checkliste D.1–D.11.

## Aufräumen

```sh
~/bin/escalate drop && ~/bin/escalate status | grep "leases held"    # 0 leases held
```
