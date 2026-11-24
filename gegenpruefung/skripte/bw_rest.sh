#!/bin/sh
# Rest der Gruppen F (nach einem Verbindungsabbruch); haengt an both_ways_roh.csv an.
set -e
cd /work
export AKTUAR_ROOT=/work
for spec in "F-F01 F-F01" "F-F02 F-F02" "F-F03 F-F03"; do
  set -- $spec
  for m in orig patch mutant; do Rscript gegenpruefung/skripte/both_ways.R "$1" "$m" "$2" 2>&1 | tail -1; done
done
