#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.elixir-install/installs/otp/27.1.2/bin:$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:$PATH"
cd "$(dirname "$0")/.."
echo "==> Elixir $(elixir --short-version) / OTP $(erl -noshell -eval 'io:put_chars(erlang:system_info(otp_release)), halt().')"
mix local.hex --force
mix local.rebar --force
mix deps.get
mix format --check-formatted || mix format
mix test
echo "==> Quick bench (pipeline + pipeline_selective)"
export BENCH_QUICK=1
export BENCH_OPS=pipeline,pipeline_selective
export BENCH_OUT="${HOME}/fp_bench_smoke"
rm -rf "$BENCH_OUT"
mkdir -p "$BENCH_OUT" results
mix run bench/run.exs
cp -f "$BENCH_OUT"/*.csv "$BENCH_OUT"/environment.txt results/ 2>/dev/null || true
echo "==> Smoke OK"
