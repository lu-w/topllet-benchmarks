#!/bin/bash
# USAGE: create_benchmarks.sh M S, where M is the maximum N of the benchmarks to create and S an optional seed
# Note: overwrites previously created benchmarks

if [ "$#" -gt 0 ]
then
  M=$1
else
  M=1
fi
if [ "$#" -gt 1 ]
then
  S=$2
else
  S=1
fi

for N in $(seq 1 "$M")
do
  echo "=== Creating benchmarks for N = ${N} ==="
  mkdir -p "aboxes/${N}"
  KBS_FILE="aboxes/${N}/aboxes.kbs"
  echo "" > "$KBS_FILE"
  for T in $(seq 0 2)
  do
    ABOX_FILE="aboxes/${N}/abox_${T}.owl"
    echo "Creating benchmark for T=${T}, N=${N}, S=${S}, and saving to ${ABOX_FILE}"
    python create_abox.py "$T" "$N" "$S" > "$ABOX_FILE"
    echo "abox_${T}.owl" >> "$KBS_FILE"
  done
done
