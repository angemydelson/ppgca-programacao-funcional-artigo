#!/usr/bin/env bash
# Instala OTP + Elixir no home do usuário (sem sudo), via install.sh oficial.
set -euo pipefail

ELIXIR_V="1.17.3"
OTP_V="27.1.2"
INSTALLS_DIR="${HOME}/.elixir-install/installs"
OTP_BIN="${INSTALLS_DIR}/otp/${OTP_V}/bin"
ELIXIR_BIN="${INSTALLS_DIR}/elixir/${ELIXIR_V}-otp-27/bin"

if command -v elixir >/dev/null 2>&1 && elixir --version >/dev/null 2>&1; then
  echo "==> Elixir já disponível: $(command -v elixir)"
  elixir --version
  exit 0
fi

if [[ -x "${ELIXIR_BIN}/elixir" && -x "${OTP_BIN}/erl" ]]; then
  echo "==> Instalação prévia encontrada em ${INSTALLS_DIR}"
else
  echo "==> Baixando instalador oficial..."
  cd "${HOME}"
  curl -fsSO https://elixir-lang.org/install.sh
  chmod +x install.sh
  echo "==> Instalando elixir@${ELIXIR_V} otp@${OTP_V} (pode demorar)..."
  sh install.sh "elixir@${ELIXIR_V}" "otp@${OTP_V}"
fi

MARKER="# >>> fp_bench elixir >>>"
if ! grep -qF "${MARKER}" "${HOME}/.bashrc" 2>/dev/null; then
  {
    echo ""
    echo "${MARKER}"
    echo "export PATH=\"${OTP_BIN}:${ELIXIR_BIN}:\$PATH\""
    echo "# <<< fp_bench elixir <<<"
  } >> "${HOME}/.bashrc"
  echo "==> PATH adicionado ao ~/.bashrc"
fi

export PATH="${OTP_BIN}:${ELIXIR_BIN}:${PATH}"
echo "==> Verificando..."
elixir --version
mix --version
echo "==> OK"
