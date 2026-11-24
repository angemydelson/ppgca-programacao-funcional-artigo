#!/usr/bin/env bash
# Benchmark sério (não QUICK) dos pipelines.
# Escreve em ~/fp_bench_results (FS Linux, rápido) e copia CSV para results/.
set -euo pipefail
export PATH="$HOME/.elixir-install/installs/otp/27.1.2/bin:$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="${HOME}/fp_bench_results"
rm -rf "$OUT"
mkdir -p "$OUT" results

# Limpa artefatos enormes de runs anteriores no /mnt/c
rm -f results/*_raw.csv erl_crash.dump 2>/dev/null || true

unset BENCH_QUICK || true
export BENCH_OPS="${BENCH_OPS:-pipeline,pipeline_selective}"
export BENCH_TIME="${BENCH_TIME:-5}"
export BENCH_WARMUP="${BENCH_WARMUP:-2}"
export BENCH_MEMORY_TIME="${BENCH_MEMORY_TIME:-1}"
export BENCH_OUT="$OUT"
# HTML off por padrão (lento no /mnt/c)
unset BENCH_HTML || true

echo "==> Bench pipelines → ${OUT} (time=${BENCH_TIME}s)"
mix run bench/run.exs

cp -f "$OUT"/*.csv "$OUT"/environment.txt results/
echo "==> Copiado para ${ROOT}/results/"
ls -lh results/*.csv results/environment.txt
echo "==> Feito. Veja results/*.csv"
