#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$LAB_ROOT/.tools/oss-cad-suite/bin:$PATH"

failed=0
for command_name in python3 iverilog verilator yosys make; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '%-10s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    printf '%-10s MISSING\n' "$command_name"
    failed=1
  fi
done

if [[ ! -x "$LAB_ROOT/.venv/bin/python" ]]; then
  echo ".venv      MISSING (run make setup)"
  failed=1
else
  echo ".venv      ready"
fi

exit "$failed"
