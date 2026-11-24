# Reprodução do experimento

Comandos no **WSL (Ubuntu)**. Instalação: [`AMBIENTE.md`](AMBIENTE.md)
(OTP 27.1.2, Elixir 1.17.3 no `$HOME`).

| Modo | Objetivo | Artigo |
|---|---|---|
| Smoke | Compilar, testar, gerar CSV com janelas curtas | não |
| Completo | Medição dos pipelines (warmup 2 s / time 5 s / memory 1 s) | sim |

## 1. Sessão

```bash
export PATH="$HOME/.elixir-install/installs/otp/27.1.2/bin:$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:$PATH"
cd "/mnt/c/Users/Softex/Documents/Angemydelson-PPGCA/Materias/Programacao Funcional/Tema do Artigo/ppgca-programacao-funcional-artigo"
elixir --version
```

## 2. Preparação (uma vez)

```bash
mix local.hex --force
mix local.rebar --force
mix deps.get
mix compile
```

Se `_build/` ou `deps/` vieram do Windows nativo:

```bash
rm -rf _build deps
mix deps.get
mix compile
```

## 3. Smoke

```bash
bash scripts/smoke_wsl.sh
```

Manual:

```bash
mix format --check-formatted
mix test
BENCH_QUICK=1 BENCH_OPS=pipeline,pipeline_selective mix run bench/run.exs
```

Critérios: `0 failures`; CSV e `environment.txt` em `results/`.

## 4. Medição completa (pipelines)

```bash
bash scripts/bench_pipelines_wsl.sh
```

O script grava em `~/fp_bench_results` (FS Linux) e copia CSV +
`environment.txt` para `results/`.

Manual:

```bash
BENCH_OPS=pipeline,pipeline_selective \
  BENCH_OUT="$HOME/fp_bench_results" \
  mix run bench/run.exs
cp -f "$HOME/fp_bench_results"/*.csv "$HOME/fp_bench_results"/environment.txt results/
```

Tamanhos padrão: 1.000, 10.000, 100.000 (`BENCH_FULL=1` → +1.000.000).

Export LaTeX:

```bash
elixir scripts/export_latex.exs results/pipeline.csv results/tables/pipeline.tex
```

### Todas as operações

```bash
mix run bench/run.exs
```

### Arquivamento de repetições

Cada execução sobrescreve a pasta de saída:

```bash
for rep in 1 2 3; do
  bash scripts/bench_pipelines_wsl.sh
  dest="results/run-$(date +%Y%m%d-%H%M%S)-rep$rep"
  mkdir -p "$dest"
  cp results/*.csv results/environment.txt "$dest"/
done
```

Números da sessão do artigo: [`RESULTADOS.md`](RESULTADOS.md).

## 5. Energia (Linux nativo)

WSL não expõe RAPL. Com `/sys/class/powercap/intel-rapl:0`:

```bash
for op in pipeline pipeline_selective; do
  for style in recursive recursive_fused eager lazy; do
    sudo -E env "PATH=$PATH" bench/energy_rapl.sh "$op" "$style" 100000 200 10
  done
done
```

Saída: `results/energy.csv`.

## 6. PowerShell

```powershell
wsl --cd "C:\Users\Softex\Documents\Angemydelson-PPGCA\Materias\Programacao Funcional\Tema do Artigo\ppgca-programacao-funcional-artigo" bash -lc "export PATH=`$HOME/.elixir-install/installs/otp/27.1.2/bin:`$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:`$PATH; mix test && BENCH_QUICK=1 BENCH_OPS=pipeline mix run bench/run.exs"
```
