#!/bin/sh
set -e
cd /work
export AKTUAR_ROOT=/work
for id in D-F01 A-F01 B-F01 C-F03 D-F03 E-F02 D-F07 F-F01; do
  Rscript gegenpruefung/skripte/wirkung.R "$id" 2>&1 | tail -3
done
