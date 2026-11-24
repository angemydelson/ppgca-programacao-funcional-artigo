#!/usr/bin/env bash
# Energia via Intel RAPL (Linux nativo). Lê energy_uj antes/depois de
# bench/energy.exs e acrescenta uma linha em results/energy.csv.
#
#   sudo bench/energy_rapl.sh <op> <estilo> <tamanho> <iterações> [reps]
#   sudo bench/energy_rapl.sh pipeline lazy 100000 200 10
#
# Requer /sys/class/powercap/intel-rapl:0 (root no kernel >= 5.10).
# RAPL = pacote da CPU, não o processo BEAM isolado.

set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "usage: $0 <operation> <style> <size> <iterations> [repetitions]" >&2
  exit 1
fi

OP="$1"; STYLE="$2"; SIZE="$3"; ITER="$4"; REPS="${5:-5}"
RAPL="${RAPL_DOMAIN:-/sys/class/powercap/intel-rapl:0}"
OUT="results/energy.csv"

if [[ ! -r "$RAPL/energy_uj" ]]; then
  echo "RAPL counter not readable at $RAPL/energy_uj (unsupported hardware/OS or missing permission)." >&2
  exit 2
fi

MAX_RANGE="$(cat "$RAPL/max_energy_range_uj")"

mkdir -p results
if [[ ! -f "$OUT" ]]; then
  echo "operation,style,size,iterations,repetition,energy_uj,wall_s,energy_per_iteration_uj" > "$OUT"
fi

# Compile once outside the measured region.
MIX_ENV="${MIX_ENV:-dev}" mix compile >/dev/null

for rep in $(seq 1 "$REPS"); do
  start_uj="$(cat "$RAPL/energy_uj")"
  start_ns="$(date +%s%N)"

  mix run bench/energy.exs "$OP" "$STYLE" "$SIZE" "$ITER" >/dev/null

  end_ns="$(date +%s%N)"
  end_uj="$(cat "$RAPL/energy_uj")"

  # The counter wraps around at max_energy_range_uj.
  if (( end_uj >= start_uj )); then
    delta=$(( end_uj - start_uj ))
  else
    delta=$(( MAX_RANGE - start_uj + end_uj ))
  fi

  wall_s="$(awk -v a="$start_ns" -v b="$end_ns" 'BEGIN { printf "%.6f", (b - a) / 1e9 }')"
  per_iter="$(awk -v e="$delta" -v n="$ITER" 'BEGIN { printf "%.3f", e / n }')"

  echo "$OP,$STYLE,$SIZE,$ITER,$rep,$delta,$wall_s,$per_iter" | tee -a "$OUT"
  sleep 2
done
