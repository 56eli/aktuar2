#!/bin/sh
# Führt die Both-ways-Prüfung für alle 30 Fehlerbefunde aus (orig, patch, mutant).
# Aufruf im Container aus der Repo-Wurzel: sh gegenpruefung/skripte/both_ways_lauf.sh
set -e
export AKTUAR_ROOT=$(pwd)
rm -f gegenpruefung/both_ways_roh.csv
rm -rf gegenpruefung/logs
for spec in \
  "A-F01 A-F01" "A-F02 A-F01,A-F02" "A-F03 A-F03" \
  "B-F01 B-F01" "B-F02 B-F02" "B-F03 B-F03" "B-F04 B-F04" \
  "C-F01 C-F01" "C-F02 C-F02" "C-F03 C-F03" "C-F04 C-F04" "C-F05 C-F05" \
  "D-F01 D-F01" "D-F02 D-F02" "D-F03 D-F03" "D-F04 D-F04" "D-F05 D-F05" \
  "D-F06 D-F06" "D-F07 D-F07" \
  "E-F01 E-F01" "E-F02 E-F02" "E-F03 E-F03" "E-F04 E-F04" "E-F05 E-F05" \
  "E-F06 E-F06" "E-F07 E-F07" "E-F08 E-F08" \
  "F-F01 F-F01" "F-F02 F-F02" "F-F03 F-F03"
do
  set -- $spec
  for modus in orig patch mutant; do
    Rscript gegenpruefung/skripte/both_ways.R "$1" "$modus" "$2" 2>&1 | tail -1
  done
done
