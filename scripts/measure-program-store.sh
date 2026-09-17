#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YOSYS="$LAB_ROOT/.tools/oss-cad-suite/bin/yosys"
SOURCE="$LAB_ROOT/experiments/program_store/program_store.v"

if [[ ! -x "$YOSYS" ]]; then
  echo "OSS CAD Suite is missing; run 'make setup' first." >&2
  exit 1
fi

for words in 32 64; do
  if [[ "$words" == "32" ]]; then
    address_width=5
  else
    address_width=6
  fi

  echo "=== ${words} x 16 asynchronous-read program store ==="
  "$YOSYS" -p "read_verilog $SOURCE; chparam -set WORDS $words -set ADDR_WIDTH $address_width program_store; synth -top program_store; stat" 2>&1 \
    | sed -n '/^4\. Printing statistics/,$p' \
    | grep -E '^[[:space:]]+[0-9]+[[:space:]]+cells$|[$]_(DFFE|MUX|AND|NOT|OR)'
done
