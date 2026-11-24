#!/bin/sh
set -e
cd /work
export AKTUAR_ROOT=/work
for spec in "E-F06 E-F06" "E-F07 E-F07" "E-F08 E-F08" "F-F01 F-F01" "F-F02 F-F02" "F-F03 F-F03"; do
  set -- $spec
  for m in orig patch mutant; do Rscript gegenpruefung/skripte/both_ways.R "$1" "$m" "$2" 2>&1 | tail -1; done
done
