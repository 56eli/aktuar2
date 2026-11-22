# Gegenprüfung der Gruppen A, B, C

> **Stand:** Diese Gegenprüfung bezieht sich auf den ersten Stand der Analysen (Commit `c83d9cd`), Wort für Wort so belassen. Ihre Urteile sind seitdem eingearbeitet: geänderte Schweregrade und Begründungen stehen in den Gruppenanalysen, D-F01 und D-F06 sind neu belegt bzw. korrigiert, und ein vollständiger Testlauf ist grün (`ergebnisse/testergebnisse.csv`). Wo ein Urteil nicht übernommen wurde, steht der Grund im Bericht (`bericht/bericht.md`, Abschnitt „Gegenstand und Vorgehen“). Lesehilfe: `.review/sicr/R/` meint den sicr-Quellcode `R/` am Commit `c0ad2ad`, `vignettes/` liegt neben `R/`. `.review/testergebnisse.csv` ist der erste Testlauf, den der Prüfer vorliegen hatte; die dort verzeichneten Fehlschläge und Abbrüche sind behoben, maßgeblich ist der Schlusslauf in `ergebnisse/testergebnisse.csv` (76 Tests, alle bestanden).

Geprüft wurden die Analysen `analyse/A_kernsimulation.md`, `analyse/B_datenaufbereitung.md` und
`analyse/C_ibnr_sonderschaeden_rv.md` gegen den Quellcode in `.review/sicr/R/`, die Befunde in
`befunde/`, die Korrekturen/Verbesserungen in `verbesserungen/` sowie die zugehörigen Tests und
Benchmarks. Zeilenangaben beziehen sich auf `.review/sicr/R/`.

**Testlage (wichtig):** R/Rscript ist in dieser Umgebung nicht installiert, daher konnte ich keinen
Test ausführen. Die beigefügte `.review/testergebnisse.csv` ist außerdem **nicht** durchgehend grün:
Sie verzeichnet Fehlschläge für `A-V01`, den ersten Test von `C-F03` und den inzwischen entfernten
Test `C-F05 (a)`. Die aktuellen Dateien wurden laut Commit danach geändert (`C-F05(a)` entfernt,
`C-F03`/`A-V01`-Tests repariert); ein neuer Lauf liegt nicht vor. Meine Urteile stützen sich deshalb
auf Quellcode, Testlogik und die vorhandenen Dateien, nicht auf einen eigenen Lauf.

## Urteile

| ID | Urteil (bestätigt / abgeschwächt / widerlegt / umgedeutet) | Schwere neu | Begründung mit Zeilenangaben |
|---|---|---|---|
| A-F01 | bestätigt | hoch | Die Nachlauf-Grenzen werden erst nach der Hochskalierung angewandt (`R/generate_pools.R:130-139`), obwohl die Doku sie auf `index_year`-Niveau definiert (`R/generate_pools.R:8-11`). Bei finiten Grenzen wird die Tail-Verteilung um bis zu `(T-M)` verfälscht. Test A-F01 und `generate_pools_v()` (`verbesserungen/A-F01.R`) drehen die Reihenfolge korrekt. Einschränkung: Defaults sind `-Inf/Inf`, der Fehler tritt nur bei gesetzten Grenzen auf. |
| A-F02 | bestätigt | mittel | `2:(start_of_tail - 1)` liefert für `start_of_tail = 2` die absteigende Folge `c(2,1)` (`R/generate_pools.R:73`) und ebenso in `pools2matrix()` (`R/sampling_preparation.R:85`); Jahr 2 landet doppelt im Pretail- und im Nachlaufpool. `start_of_tail = 2` wird nirgends validiert und ist laut Doku nicht verboten; Randfall. Die Korrekturen in `A-F01.R`/`A-F02.R` sind für Pool- und Matrixaufbau vollständig. |
| A-F03 | abgeschwächt | mittel | `tail(indices$Transition_factor, 250)[year]` (`R/sicr.R:451`) setzt `max(indices$Calendar_year) == last_orig_year + 250` voraus; `indices_ok()` (`R/data_checks.R:507-516`) erlaubt zusätzliche späte Jahre. Der Test mit einem Extra-Jahr 2271 belegt die Verschiebung. Die Behauptung „oder früher beginnende Jahre“ ist falsch: zusätzliche frühe Jahre ändern `tail(..., 250)` nicht. Der Standardpfad `expand_historic_indices()` (`R/data_functions.R:47-49`) endet bei `max(historic) + 250`; der Trigger verlangt eine Indexreihe über `last_orig_year` hinaus. Korrektur `future_index_factors_v()` ist richtig. |
| A-V01 | bestätigt | — (Ziel: effizienter) | Wiederholtes `rbind()` in zwei Schleifen (`R/generate_pools.R:211-226`) wird durch Sammeln und einmaliges `do.call(rbind, ...)` ersetzt (`verbesserungen/A-V01.R`); der Nutzen ist real. Der Gleichheitstest `tests/verbesserungen/test-A-V01.R` vergleicht aber erst nach `strip_types()` und Sortierung, also nicht Typen und Zeilenordnung; der Lauf in `.review/testergebnisse.csv` ist als fehlgeschlagen verzeichnet (danach laut Commit repariert). |
| A-V02 | abgeschwächt | — (Ziel: lesbarer/robuster) | `get_matrix_info()` (`R/sampling_preparation.R:167-188`) ist korrekt; `ifelse()` wertet den nicht benötigten Zweig aus, erzeugt dort aber nur verworfene `NA`. `get_matrix_info_v()` (`verbesserungen/A-V02.R`) ist länger und ändert das `"range"`-Verhalten für Vektoren nicht: `start:(start + sample_size - 1)` nutzt weiterhin nur die ersten Elemente. Kein Fehler behoben; Nutzen marginal. |
| B-F01 | bestätigt | hoch | `Calendar_year` wird als lückenlose Folge `min:max+250` erzeugt, `Index_gross` aber in Zeilenreihenfolge angehängt (`R/data_functions.R:47-49`); `historic_indices_ok()` prüft keine Sortierung (`R/data_checks.R:431-441`). Unsortierte Eingaben werden still falsch zugeordnet; Lücken erzeugen den Längenfehler. Die Korrektur sortiert und prüft Lücken; für den in der Vignette (`vignettes/sicr.Rmd:283`) erlaubten Fall einzelner älterer Basisjahre bleibt sie streng (Fehler statt Auffüllen) – keine Regression, aber unvollständig. |
| B-F02 | abgeschwächt | niedrig | Fehlt `index_year`, entsteht `numeric(0)` im Nenner (`R/data_functions.R:78-79`) und ein Abbruch mit unklarer Meldung; ein falsches Ergebnis für gültige Eingaben entsteht nicht. Doppelte Jahre werden zwar recycelt, aber `indices_ok()` (`R/data_checks.R:501-505`) verwirft sie vor der Verwendung. Validierungs-/Meldungsfehler, kein Rechenfehler; „mittel“ ist zu hoch. Korrektur `add_transition_factor_v()` ist richtig. |
| B-F03 | bestätigt | mittel | `for (i in 1:NROW(...))` läuft bei 0 Zeilen als `1:0` und greift auf Zeile 1 zu (`R/basic.R:433-438`); eine leere Matrix bricht ab. `inc2cum_v()` mit `seq_len(0)` (`verbesserungen/B-F03.R`) liefert die leere Matrix unverändert. Randfall, aber exportierte Hilfsfunktion. |
| B-F04 | bestätigt | niedrig | `cum2inc(numeric(0))` bildet `c(cum_triangle[1], diff(...))` und liefert `NA` statt `numeric(0)` (`R/basic.R:450-453`). Korrektur B-F04 behandelt leere Vektoren/Matrizen; ohne Einfluss auf normale Dreiecke. |
| B-V01 | bestätigt | — (Ziel: kürzer/lesbarer) | `tail_factor_v()` (`verbesserungen/B-V01.R`) ist algebraisch äquivalent zu `tail_factor()` (`R/basic.R:362-371`), auch für `dev_year` außerhalb `[start, end]` und für `start > end`; Test B-V01 deckt die normalen Fälle ab. Keine Verhaltensänderung. |
| B-V02 | bestätigt | — (Ziel: effizienter) | `cal_year2dev_year_v()` (`verbesserungen/B-V02.R`) bildet dieselbe untere Dreieckszuordnung wie der Loop (`R/basic.R:386-396`); Test B-V02 prüft 3×3 und 20×20. Der Effizienzgewinn ist plausibel, im Repo ist aber keine Bench-Ausgabe hinterlegt (`bench/B-V02.R` existiert nur als Skript). |
| C-F01 | bestätigt | mittel | Zeile 30 setzt `art` statt `type` (`R/special_claims.R:28-32`); bei ungültigem `Rollout_type` bleibt `type` ungültig, keine der drei `if`-Bedingungen greift, und `roll_out_single_claim()` liefert 250 Nullen (Best Estimate 0). `compute_special_claims()` prüft den Typ nicht. Korrektur C-F01 setzt `type <- "linear"` und ist richtig; der Warnungstext enthält weiterhin den Tippfehler „lineaer“. |
| C-F02 | bestätigt | niedrig | `output == "future"` statt Zuweisung (`R/reinsurance.R:310-313`); bei ungültigem `output` bleibt der Wert unverändert, der `else`-Zweig (`R/reinsurance.R:323-325`) liefert die volle Matrix. Nur bei ungültigem Argument; Korrektur C-F02 ist richtig. |
| C-F03 | bestätigt | hoch | `rev(exposure$Exposure)`, Zeilenumdrehung und `rownames` aus `exposure$Origin_year` (`R/ibnr.R:104-118`) setzen eine aufsteigend sortierte `exposure` voraus; `exposure_ok()` prüft keine Reihenfolge (`R/data_checks.R:353-389`). Unsortiert werden die IBNR-Anzahlen den falschen Anfalljahren zugeordnet; Test C-F03 zeigt die Verschiebung. Korrektur C-F03 sortiert intern und ist richtig. |
| C-F04 | bestätigt | mittel | `cumprod` startet im Basisjahr B (`R/reinsurance.R:76`) und wird ab B abgelegt (`R/reinsurance.R:78,85`); der Faktor im Basisjahr ist `1 + Index_re[B]` statt 1. Da `xl_cashflow()` durch diesen Faktor teilt, wird die Priorität zu hoch und der RV-Anteil zu klein. Doku `R/reinsurance.R:139-158`; Korrektur C-F04 beginnt bei B+1, richtig. Betrifft nur den RV-Anteil und eine Jahresverschiebung. |
| C-F05 | bestätigt | mittel | `max_dev_year <- max(1, NROW(orig_years) - 1)` (`R/ibnr.R:49`) lässt das letzte mögliche Abwicklungsjahr N weg; Paper 2.4.5, S. 16 verlangt jedes Abwicklungsjahr. Test C-F05 zeigt 0 statt 4 erwartete Schäden im Beispiel. Korrektur C-F05 setzt `max_dev_year = NROW(orig_years)`; `generate_ibnr_pools()` hat den Pool für N bereits (`R/ibnr.R:293-295`), daher vollständig. |
| C-V01 | bestätigt | — (Ziel: kürzer/lesbarer) | `generate_ibnr_pools_v()` ersetzt Schleife und data.frame-Filter durch einen logischen Vektor mit `lapply`/`which` (`verbesserungen/C-V01.R`); Test C-V01 zeigt Gleichheit inklusive Randfall „nur ein Anfalljahr“. Eintrag k gehört weiterhin zu Abwicklungsjahr k+1; Hinweis C-H03 bleibt gültig. |
| C-V02 | bestätigt | — (Ziel: effizienter) | `expand.grid()` + `rep()` (`verbesserungen/C-V02.R`) bilden die column-major-Reihenfolge von `as.vector()` und die Sortierung von `ibnr_transform2dataframe()` (`R/ibnr.R:233-251`) nach; Test C-V02 prüft die Doku-Matrix und die leere Matrix. Die dplyr/tidyr-Abhängigkeit entfällt. |

## Erläuterungen zu den nicht schlicht bestätigten Urteilen

### A-F03 — abgeschwächt (mittel)

Der Code `tail(indices$Transition_factor, 250)[year]` (`R/sicr.R:451`) ist nur dann äquivalent zur
kalenderjahrbasierten Indexierung, wenn die letzte Zeile von `indices` genau `last_orig_year + 250`
ist. `indices_ok()` verlangt zwar alle Jahre von `first_orig_year` bis `last_orig_year + 250`
(`R/data_checks.R:507-511`), verbietet aber zusätzliche spätere Jahre nicht. Der Test zeigt das
korrekt: Mit einem zusätzlichen Jahr 2271 wird für das erste Zukunftsjahr 2021 bereits
`Transition_factor(2022)` verwendet. Die im Analysetext zusätzlich genannte Variante „früher
beginnende Jahre“ ist dagegen kein Trigger: `tail(..., 250)` nimmt bei `max = last_orig_year + 250`
unabhängig von der Anzahl früherer Zeilen die Jahre `last_orig_year + 1` bis `last_orig_year + 250`.
Damit ist die Aussage zu breit und die Schwere „hoch“ zu hoch: Der Standardweg
`expand_historic_indices()` (`R/data_functions.R:47-49`) erzeugt bei `max(historic) = last_orig_year`
genau `last_orig_year + 250`; der Fehler braucht eine über `last_orig_year` hinausgehende Indexreihe
(z. B. Indexdaten bis 2024 bei Bewertung 2023). Die Korrektur `future_index_factors_v()` ist sachlich
richtig und invariant gegen Extrajahre, weil sie die Jahre über `Calendar_year` sucht.

### A-V02 — abgeschwächt (Ziel: lesbarer/robuster)

`get_matrix_info()` (`R/sampling_preparation.R:167-188`) liefert für alle intern verwendeten
skalaren Aufrufe korrekte Werte. Das `ifelse()` in `sample_size()` wertet den nicht gewählten Zweig
aus und indexiert dabei für Nachlaufjahre weit außerhalb von `lengths_vector`; das Ergebnis ist
`NA`, wird aber verworfen. Es liegt also kein Rechenfehler vor. `get_matrix_info_v()`
(`verbesserungen/A-V02.R`) vermeidet diese unnötigen Zugriffe, ist aber länger (zwei Zweige,
`rep_len`) und ändert das Verhalten von `"range"` für Vektoren nicht: Auch dort wird
`start:(start + sample_size - 1)` verwendet, was bei Vektoren nur die ersten Elemente auswertet. Der
Test `tests/verbesserungen/test-A-V02.R` vergleicht beide Funktionen und schreibt dieses Verhalten
damit fest. Der Nutzen ist auf Skalare beschränkt und marginal; die Bezeichnung „robuster“ ist nur
eingeschränkt gerechtfertigt.

### B-F02 — abgeschwächt (niedrig)

`add_transition_factor()` (`R/data_functions.R:77-82`) bricht bei fehlendem `index_year` ab, weil
der Nenner `numeric(0)` ist. Das ist eine unklare Fehlermeldung, aber kein stilles falsches Ergebnis
für eine gültige Eingabe: `index_year` ist ein Pflichtargument, und der dokumentierte Ablauf
(`vignettes/sicr.Rmd:290-315`, `R/data.R:170-179`) übergibt es immer. Der Fall doppelter
Kalenderjahre ist ebenfalls kein stiller Normalfall, weil `indices_ok()`
(`R/data_checks.R:501-505`) Duplikate vor der Verwendung in `prepare_data()` ablehnt. Die Korrektur
`add_transition_factor_v()` ist richtig und verbessert die Meldung, aber der Befund ist ein
Validierungs-/Dokumentationsproblem (niedrig), kein Rechenfehler mittlerer Schwere.

## Weitere Anmerkungen zu bestätigten Befunden und Korrekturen

- **A-F01:** Die Korrektur `generate_pools_v()` ist inhaltlich richtig; sie ändert aber zugleich den
  Pretail-Bereich für `start_of_tail <= 2` und damit auch A-F02. Das ist beabsichtigt, sollte aber
  beim Vergleich mit dem Original nicht als „nur A-F01“ gelesen werden.
- **A-V01:** Der Nutzen (kein quadratisches `rbind()`) ist real. Der Test ist jedoch kein
  vollständiger Gleichheitsnachweis, weil `strip_types()` alle Spalten in `numeric` wandelt und die
  Zeilen sortiert; zudem ist der Lauf in `.review/testergebnisse.csv` als fehlgeschlagen
  verzeichnet. Für einen belastbaren Nachweis wäre `expect_identical()` auf einer konstruierten
  Pool-Struktur mit definierten Typen und Zeilenordnung nötig.
- **B-F01:** Die Korrektur `expand_historic_indices_v()` behebt die stille Fehlzuordnung und macht
  Lücken zu einem klaren Fehler. Sie unterstützt aber weiterhin nicht den in der Vignette
  (`vignettes/sicr.Rmd:283`) beschriebenen Fall, dass einzelne ältere Basisjahre (z. B. für
  `Base_year` der RV) ergänzt werden und dadurch eine Lücke entsteht. Das Original bricht dort
  ebenfalls ab; die Korrektur ist also keine Regression, aber unvollständig.
- **B-V02:** Die Effizienzbehauptung ist plausibel, aber ohne Bench-Ergebnis im Repo nicht belegt;
  `bench/B-V02.R` ist nur das Messskript.
- **C-F05 / Gruppe C:** Der Überblick der Analyse behauptet weiterhin einen dritten Fehler
  („Abschneiden der Bestandsgröße auf ganze Zahlen“). Dieser ist widerlegt: Bei der Zuweisung an
  `sum_of_exposures` wandelt R den `integer`-Vektor in `double` um; der frühere Test `C-F05(a)` ist
  in `.review/testergebnisse.csv` als fehlgeschlagen verzeichnet und wurde entfernt. Der Überblick
  sollte auf zwei Fehler korrigiert werden.
- **A-K01/A-K02:** Die beiden Korrektheitsnachweise sind in sich plausibel. A-K01 prüft das
  Poolmittel und die Nichtverwendung der Null-Auffüllzeilen; A-K02 prüft den Nachlaufpfad
  `c(300, 200, 100, 0, 0)` gegen die Paperformel. Sie ersetzen keinen Fehlerbefund und wurden hier
  nicht als Fehler gezählt.
- **C-H01 (unbelegt):** Der Verdacht, dass die Sonder-Cashflows nicht auf die künftigen
  Auszahlungsjahre indexiert werden, ist nach Quellcode (`R/special_claims.R:299-318`) plausibel und
  wäre der stärkste Kandidat für einen eigenen Befund mit Test; die Doku lässt allerdings die
  Gegenlesart zu, dass der Nutzer den Best Estimate bereits nominal vorgibt. Ohne Test bleibt es ein
  Hinweis.

**Selbsteinschätzung (Can-fail):** Am ehesten könnte mein Urteil zu **A-F03** falsch sein, weil die
Abgrenzung „nur zusätzliche späte Jahre“ von der Frage abhängt, ob man eine über `last_orig_year`
hinausgehende Indexreihe als realistische Datenlage akzeptiert. Wenn ja, wäre „hoch“ statt „mittel“
richtig; die Korrektur selbst bleibt davon unberührt.
