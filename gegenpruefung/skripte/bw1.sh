#!/bin/sh
set -e
cd /work
export AKTUAR_ROOT=/work
rm -f gegenpruefung/both_ways_roh.csv
rm -rf gegenpruefung/logs
for spec in "A-F01 A-F01" "A-F02 A-F01,A-F02" "A-F03 A-F03" "B-F01 B-F01" "B-F02 B-F02" "B-F03 B-F03" "B-F04 B-F04" "C-F01 C-F01" "C-F02 C-F02" "C-F03 C-F03" "C-F04 C-F04" "C-F05 C-F05"; do
  set -- $spec
  for m in orig patch mutant; do Rscript gegenpruefung/skripte/both_ways.R "$1" "$m" "$2" 2>&1 | tail -1; done
done
