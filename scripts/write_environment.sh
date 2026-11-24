#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.elixir-install/installs/otp/27.1.2/bin:$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:$PATH"
cd "$(dirname "$0")/.."
mkdir -p results
rm -f erl_crash.dump

OTP=$(erl -noshell -eval 'io:put_chars(erlang:system_info(otp_release)), halt().')
ARCH=$(erl -noshell -eval 'io:put_chars(erlang:system_info(system_architecture)), halt().')
JIT=$(erl -noshell -eval 'io:write(erlang:system_info(emu_flavor)), halt().')

{
  echo "timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "hostname=$(hostname)"
  echo "os=$(uname -srm)"
  echo "cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ //')"
  echo "cores=$(nproc)"
  echo "mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
  echo "elixir=$(elixir --short-version)"
  echo "otp=${OTP}"
  echo "arch=${ARCH}"
  echo "jit=${JIT}"
  echo "note=see_README.md_for_full_bench"
} > results/environment.txt
cat results/environment.txt
