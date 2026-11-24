# FpBench

Comparação empírica de três estilos de processamento de listas em Elixir,
mais uma variante fundida em um único passo. Artefato do trabalho final da
disciplina **CAES005 — Introdução à Programação Funcional** (PPGCA/UTFPR).

| Estilo | Módulo | Descrição |
|---|---|---|
| Recursão em três passos | `FpBench.Recursive` | `map` + `filter` + `sum` com acumulador e `[h \| t]` |
| Eager | `FpBench.Eager` | `Enum` (materializa listas intermediárias) |
| Lazy | `FpBench.Lazy` | `Stream` (compõe estágios e força no fim) |
| Fusão manual | `Recursive.pipeline_fused/1` | uma passada, sem listas intermediárias |

Operações: `sum`, `map`, `filter`, `reverse`, `reduce` e dois pipelines
`map → filter → sum`. O artigo usa os pipelines; as demais operações estão
no código como material suplementar.

| Pipeline | Estágios | Filtro | Forma fechada em `input(n)` |
|---|---|---|---|
| `pipeline` | dobrar → pares → somar | 100% | `n·(n+1)` |
| `pipeline_selective` | dobrar → múltiplos de 4 → somar | 50% | `2·k·(k+1)`, `k = ⌊n/2⌋` |

Métricas (Benchee): mediana do tempo e alocação cumulativa no heap.
Energia (RAPL) só em Linux nativo.

Tamanhos padrão: 1.000, 10.000 e 100.000 (`BENCH_FULL=1` → 1.000.000).

## Requisitos

- Elixir 1.14+ / OTP 25+ (medição do artigo: Elixir 1.17.3, OTP 27.1.2)
- Ambiente principal: WSL 2 (Ubuntu)
- Alternativa: Windows nativo (`winget`)
- Energia: Linux nativo com Intel RAPL

## Instalação (WSL)

```bash
bash scripts/install_elixir_wsl.sh

export PATH="$HOME/.elixir-install/installs/otp/27.1.2/bin:$HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin:$PATH"

mix local.hex --force
mix local.rebar --force
mix deps.get
mix compile
```

Se `_build/` ou `deps/` forem de compilação no Windows nativo:

```bash
rm -rf _build deps && mix deps.get && mix compile
```

Smoke (deps + testes + bench curto):

```bash
bash scripts/smoke_wsl.sh
```

### Windows nativo

```powershell
winget install --id Erlang.ErlangOTP -e
winget install --id ElixirLang.Elixir -e
mix local.hex --force
mix local.rebar --force
mix deps.get
mix test
```

## Testes

```bash
mix format --check-formatted
mix test
```

Equivalência entre estilos, oráculo `:lists`, formas fechadas e preguiça do
`Stream`. Medição do artigo: 25 doctests + 37 testes, 0 failures.

## Benchmark

```bash
mix run bench/run.exs
mix bench
mix bench.quick
```

| Variável | Padrão | Efeito |
|---|---|---|
| `BENCH_SIZES` | `1000,10000,100000` | tamanhos de entrada |
| `BENCH_FULL=1` | off | inclui 1.000.000 |
| `BENCH_OPS` | todas | ex.: `pipeline,pipeline_selective` |
| `BENCH_TIME` | `5` | segundos de medição de tempo |
| `BENCH_WARMUP` | `2` | segundos de aquecimento |
| `BENCH_MEMORY_TIME` | `1` | segundos de medição de memória |
| `BENCH_QUICK=1` | off | 0,5 / 0,2 / 0,2 s |
| `BENCH_HTML=1` | off | gera `results/html/` |
| `BENCH_OUT` | `results` | diretório de saída |

### Medição do artigo (pipelines)

```bash
bash scripts/bench_pipelines_wsl.sh
```

Grava em `~/fp_bench_results` e copia CSV + `environment.txt` para `results/`.

```bash
BENCH_OPS=pipeline,pipeline_selective \
  BENCH_OUT="$HOME/fp_bench_results" \
  mix run bench/run.exs
cp -f "$HOME/fp_bench_results"/*.csv "$HOME/fp_bench_results"/environment.txt results/
```

### Saídas

| Arquivo | Conteúdo |
|---|---|
| `results/pipeline.csv` | estatísticas Benchee |
| `results/pipeline_selective.csv` | estatísticas Benchee |
| `results/environment.txt` | Elixir/OTP, schedulers, parâmetros |
| `results/html/` | relatório HTML (`BENCH_HTML=1`) |

```bash
elixir scripts/export_latex.exs results/pipeline.csv results/tables/pipeline.tex
```

No CSV: tempos em nanossegundos; coluna Memory = alocação cumulativa no
heap. Em `n` pequeno a ordem entre Enum, Stream e recursão oscila; em
`n = 10⁵` estabiliza.

## Resultados (2026-11-20)

WSL 2, Elixir 1.17.3 / OTP 27.1.2, i7-1355U, 12 schedulers, ~7,6 GB RAM.
Fonte: `results/*.csv` (execução completa, sem `BENCH_QUICK`).

### Tempo (mediana) — `pipeline` (filtro 100%)

| n | fused | Stream | Enum | recursão 3 passos |
|---|---|---|---|---|
| 1.000 | **7,35 µs** | 52,23 µs | 42,86 µs | 48,10 µs |
| 10.000 | **76,72 µs** | 594 µs | 600 µs | 1083 µs |
| 100.000 | **1,00 ms** | 6,37 ms | 11,69 ms | 21,77 ms |

### Tempo (mediana) — `pipeline_selective` (filtro 50%)

| n | fused | Stream | Enum | recursão 3 passos |
|---|---|---|---|---|
| 1.000 | **10,34 µs** | 39,08 µs | 37,65 µs | 35,37 µs |
| 10.000 | **103 µs** | 430 µs | 431 µs | 452 µs |
| 100.000 | **1,28 ms** | 5,35 ms | 13,77 ms | 13,47 ms |

### Memória (heap cumulativo) — `n = 100.000`

| Estilo | pipeline | seletivo |
|---|---|---|
| Fusão | **0 B** | **0 B** |
| Enum | 3,05 MB | 2,29 MB |
| Stream | 6,10 MB | 4,20 MB |
| Recursão 3 passos | 6,10 MB | 4,58 MB |

Em `n = 10⁵`, Stream foi ~1,8× (pipeline) a ~2,6× (seletivo) mais rápido que
Enum e alocou mais no heap. Fusão: menor tempo e 0 B. Recursão em três passos:
mais lenta no pipeline 100%; no seletivo, próxima de Enum.

Energia: não medida (WSL).

## Energia (Linux nativo)

```bash
ls /sys/class/powercap/intel-rapl:0
sudo -E env "PATH=$PATH" bench/energy_rapl.sh pipeline lazy 100000 200 10
```

Saída: `results/energy.csv`.

## Estrutura

```text
.
├── mix.exs
├── lib/fp_bench.ex
├── lib/fp_bench/
│   ├── recursive.ex
│   ├── eager.ex
│   └── lazy.ex
├── test/
├── bench/
│   ├── run.exs
│   ├── energy.exs
│   └── energy_rapl.sh
├── scripts/
│   ├── install_elixir_wsl.sh
│   ├── smoke_wsl.sh
│   ├── bench_pipelines_wsl.sh
│   └── export_latex.exs
├── docs/
│   ├── DESENVOLVIMENTO.md
│   ├── AMBIENTE.md
│   ├── REPRODUCAO.md
│   └── RESULTADOS.md
└── results/
```

Docs: [`DESENVOLVIMENTO.md`](docs/DESENVOLVIMENTO.md) ·
[`AMBIENTE.md`](docs/AMBIENTE.md) ·
[`REPRODUCAO.md`](docs/REPRODUCAO.md) ·
[`RESULTADOS.md`](docs/RESULTADOS.md).

## Licença

[`LICENSE`](LICENSE).
