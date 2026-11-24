# Nachprüfung Runde 3

Unabhängige Nachprüfung der Runde 2 (`gegenpruefung/`) des Audits von sicr 1.1.1.
Alle Skripte laufen aus der Repo-Wurzel, benutzen das installierte Paket `sicr` und
schreiben ihre Ergebnisse nach `nachpruefung/ergebnisse/`. Der Bericht steht in
[`bericht.md`](bericht.md).

| Skript | Docker-Aufruf | Ausgabe |
|---|---|---|
| `wirkung.R` | `docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e AKTUAR_ROOT=/work -v <repo>:/work -v <sicr>:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/wirkung.R` | `nachpruefung/ergebnisse/wirkung.csv` |
| `mutanten_verbesserungen.R` | `docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e AKTUAR_ROOT=/work -v <repo>:/work -v <sicr>:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/mutanten_verbesserungen.R` | `nachpruefung/ergebnisse/mutanten_verbesserungen.csv` |
| `both_ways_stichprobe.R` | `docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e AKTUAR_ROOT=/work -v <repo>:/work -v <sicr>:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/both_ways_stichprobe.R` | `nachpruefung/ergebnisse/both_ways_stichprobe.csv` |
| `both_ways_auswerten.R` | `docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e AKTUAR_ROOT=/work -v <repo>:/work -v <sicr>:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/both_ways_auswerten.R` | `nachpruefung/ergebnisse/both_ways_r.csv` (zum `cmp` gegen `gegenpruefung/both_ways.csv`) |
| `benchmarks_spanne.R` | `docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e AKTUAR_ROOT=/work -v <repo>:/work -v <sicr>:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/benchmarks_spanne.R 5` | `nachpruefung/ergebnisse/benchmarks_spanne.csv` und `benchmarks_spanne_zusammenfassung.csv` |
| `f_f01_vignette.R` | `docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e AKTUAR_ROOT=/work -v <repo>:/work -v <sicr>:/sicr:ro -w /work aktuar-r:1 Rscript nachpruefung/skripte/f_f01_vignette.R` | `nachpruefung/ergebnisse/f_f01_vignette.csv` |

Hinweise: `wirkung.R` berechnet die Großschadenwirkung mit n = 1 und Seed 12345.
Die drei Permutationstests in `wirkung.R` benutzen Seed 42. Von den 12
Verbesserungen haben nur 8 eine `bench/`-Datei; die übrigen vier erhalten in
`benchmarks_spanne.csv` den Faktor `NA` und in der Zusammenfassung `Laeufe = 0`.
`f_f01_vignette.R` misst F-F01 am Backtesting-Beispiel der Vignette.
