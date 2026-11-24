#!/usr/bin/env python3
"""Wertet gegenpruefung/both_ways_roh.csv zu gegenpruefung/both_ways.csv aus.
Ein Befund diskriminiert, wenn sein Fehlerblock (korrektur=FALSE) gegen das
unveränderte sicr grün ist und gegen die gepatchte Funktion rot wird."""
import csv, collections

RAW = "gegenpruefung/both_ways_roh.csv"
OUT = "gegenpruefung/both_ways.csv"

def red(r):
    return r["error"] == "TRUE" or r["failed"] not in ("0", "")

rows = list(csv.DictReader(open(RAW)))
last = collections.OrderedDict()
for r in rows:
    last[(r["id"], r["modus"], r["test"])] = r
ids = []
for (i, m, t) in last:
    if i not in ids:
        ids.append(i)

out = []
for i in ids:
    blk = {k: [r for (ii, m, t), r in last.items() if ii == i and m == k]
           for k in ("orig", "patch", "mutant")}
    bug = lambda r: r["korrektur"] == "FALSE"
    orig_bug = [r for r in blk["orig"] if bug(r)]
    patch_bug = [r for r in blk["patch"] if bug(r)]
    mut_bug = [r for r in blk["mutant"] if bug(r)]
    fo = sum(red(r) for r in blk["orig"])
    fp = sum(red(r) for r in blk["patch"])
    fm = sum(red(r) for r in blk["mutant"])
    out.append(dict(id=i, test_datei="befunde/test-%s.R" % i,
                    gepatchte_funktion=blk["patch"][0]["gepatcht"],
                    failed_original=fo, failed_patch=fp,
                    diskriminiert="ja" if fo == 0 and fp > 0 else "nein",
                    failed_mutant=fm,
                    fehlerbloecke=len(orig_bug),
                    korrekturbloecke=len([r for r in blk["orig"] if not bug(r)]),
                    mutation_testet="ja" if fm > 0 else "nein"))

with open(OUT, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(out[0]))
    w.writeheader(); w.writerows(out)
print(open(OUT).read())
