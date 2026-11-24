#!/bin/sh
# Seitenweise Textextrakte des DAV-Berichts (eine Datei je Seite, für prüfbare Seitenzahlen).
set -e
n=$(pdfinfo /a/paper.pdf | awk '/^Pages:/ {print $2}')
mkdir -p /a/gegenpruefung/paper
i=1
while [ "$i" -le "$n" ]; do
  pdftotext -f "$i" -l "$i" -layout /a/paper.pdf "/a/gegenpruefung/paper/seite_$(printf %02d "$i").txt"
  i=$((i+1))
done
echo "pages=$n"
