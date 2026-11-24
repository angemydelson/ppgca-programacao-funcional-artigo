# Ambiente de execução

Ambiente principal: **WSL 2 (Ubuntu)** com OTP e Elixir no `$HOME` (sem
`sudo`), via `install.sh` de [elixir-lang.org](https://elixir-lang.org/install.html).
Alternativa: Windows nativo (`winget`). Linux nativo só para energia (RAPL).

Versões de referência: **OTP 27.1.2** e **Elixir 1.17.3** (mínimo do
projeto: Elixir 1.14+). Outras versões exigem ajuste do `PATH`.

## 1. WSL

### 1.1 Pré-requisitos

- WSL 2 com Ubuntu (`wsl --install -d Ubuntu` no PowerShell, se necessário)
- `curl` e `unzip` (padrão no Ubuntu; senão `sudo apt install -y curl unzip`)

### 1.2 Instalação no `$HOME`

No bash do WSL:

```bash
cd ~
curl -fsSO https://elixir-lang.org/install.sh
sh install.sh elixir@1.17.3 otp@27.1.2
```

Binários em `~/.elixir-install/installs/otp/27.1.2` e
`~/.elixir-install/installs/elixir/1.17.3-otp-27`.

Atalho do repositório:

```bash
bash scripts/install_elixir_wsl.sh
```

### 1.3 `PATH`

Sessão atual:

```bash
export PATH="$HOME/.elixir-install/installs/otp/27.1.2/bin:$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:$PATH"
```

Permanente (`~/.bashrc`):

```bash
echo 'export PATH="$HOME/.elixir-install/installs/otp/27.1.2/bin:$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verificação:

```bash
which erl elixir mix
erl -noshell -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().'
elixir --version
```

### 1.4 Dependências do projeto

```bash
cd "/mnt/c/Users/Softex/Documents/Angemydelson-PPGCA/Materias/Programacao Funcional/Tema do Artigo/ppgca-programacao-funcional-artigo"
mix local.hex --force
mix local.rebar --force
mix deps.get
mix compile
mix test
```

Benchmark: [`REPRODUCAO.md`](REPRODUCAO.md).

### 1.5 PowerShell → WSL

O PowerShell expande `$PATH`/`$HOME` e interpreta `|`. Escape com crase:

```powershell
wsl --cd "C:\Users\Softex\Documents\Angemydelson-PPGCA\Materias\Programacao Funcional\Tema do Artigo\ppgca-programacao-funcional-artigo" bash -lc "export PATH=`$HOME/.elixir-install/installs/otp/27.1.2/bin:`$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:`$PATH; mix test"
```

Com `PATH` já no `~/.bashrc`, usar `bash -ic` (shell interativo).

### 1.6 Notas WSL

| Tema | Detalhe |
|---|---|
| Disco | `/mnt/c/...` é mais lento que o FS Linux; afeta `deps.get`/`compile`, não a medição em memória. Cópia opcional para `~/...`. |
| `_build` / `deps` | Não compartilhar entre Windows nativo e WSL. Ao alternar: `rm -rf _build deps` e `mix deps.get`. |
| Fins de linha | `.gitattributes` força LF em `*.ex`, `*.exs`, `*.sh` (CRLF quebra `energy_rapl.sh`). |
| Energia | WSL não expõe RAPL (seção 3). |
| Ruído | VM compartilha CPU com o Windows host. |

## 2. Windows nativo (`winget`)

### 2.1 Instalação

```powershell
winget install --id Erlang.ErlangOTP -e
winget install --id ElixirLang.Elixir -e
```

Reabrir o terminal após instalar. Se `elixir`/`mix` faltarem no `PATH`,
incluir as pastas `bin` (tipicamente `C:\Program Files\Elixir\bin` e
`C:\Program Files\Erlang OTP\bin`).

Scripts bloqueados no PowerShell: usar `mix.bat` ou
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

### 2.2 Verificação

```powershell
erl -noshell -eval "io:format('~s~n', [erlang:system_info(otp_release)]), halt()."
elixir --version
mix --version
```

### 2.3 Execução

```powershell
cd ppgca-programacao-funcional-artigo
mix local.hex --force
mix local.rebar --force
mix deps.get
mix test
$env:BENCH_QUICK = "1"; $env:BENCH_OPS = "pipeline"; mix run bench/run.exs
Remove-Item Env:BENCH_QUICK, Env:BENCH_OPS
```

### 2.4 Host Windows e WSL

O WSL compartilha CPU com o host. RAPL não está disponível no Windows; sem
Linux nativo ou medidor externo, energia fica fora do escopo.

## 3. Linux nativo (energia)

Mesmo `install.sh` da seção 1.2. Pacotes da distribuição podem estar
desatualizados.

### RAPL

```bash
ls /sys/class/powercap/
cat /sys/class/powercap/intel-rapl:0/name           # package-0
sudo cat /sys/class/powercap/intel-rapl:0/energy_uj
```

Se o diretório não existir: `sudo modprobe intel_rapl_common` (ou
`intel_rapl` em kernels antigos). VMs e WSL em geral não expõem RAPL.

### Medição

```bash
chmod +x bench/energy_rapl.sh
sudo -E env "PATH=$PATH" bench/energy_rapl.sh pipeline lazy 100000 200 10
sudo -E env "PATH=$PATH" bench/energy_rapl.sh pipeline_selective lazy 100000 200 10
```

`sudo -E env "PATH=$PATH"` preserva o Elixir do `$HOME`. Saída:
`results/energy.csv`.

Opcional: `sudo cpupower frequency-set -g performance`; `taskset` para
fixar núcleos.
