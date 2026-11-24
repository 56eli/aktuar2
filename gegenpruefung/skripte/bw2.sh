#!/bin/sh
set -e
cd /work
export AKTUAR_ROOT=/work
for spec in "D-F01 D-F01" "D-F02 D-F02" "D-F03 D-F03" "D-F04 D-F04" "D-F05 D-F05" "D-F06 D-F06" "D-F07 D-F07" "E-F01 E-F01" "E-F02 E-F02" "E-F03 E-F03" "E-F04 E-F04" "E-F05 E-F05"; do
  set -- $spec
  for m in orig patch mutant; do Rscript gegenpruefung/skripte/both_ways.R "$1" "$m" "$2" 2>&1 | tail -1; done
done
