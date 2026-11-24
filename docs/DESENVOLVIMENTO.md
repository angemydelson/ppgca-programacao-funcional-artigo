# Desenvolvimento do FpBench

Arquitetura, conceitos de programação funcional, protocolo experimental e
ameaças à validade do artefato Mix usado no artigo CAES005
(`artigo-caes005`).

| Documento | Conteúdo |
|---|---|
| [`AMBIENTE.md`](AMBIENTE.md) | Instalação (WSL principal) |
| [`REPRODUCAO.md`](REPRODUCAO.md) | Comandos de verificação e medição |
| [`RESULTADOS.md`](RESULTADOS.md) | Números da medição do artigo |

## 1. Objetivo

Comparar, de forma empírica e reprodutível, três estilos semanticamente
equivalentes de processamento de listas em Elixir:

1. **Recursão de cauda** — acumulador e casamento de padrões `[h | t]`
2. **Eager** — `Enum` (materializa listas intermediárias)
3. **Lazy** — `Stream` (compõe estágios e força no fim)

Métricas: tempo e alocação de memória (Benchee); energia via RAPL é
opcional e só em Linux nativo.

## 2. Arquitetura

```text
               ┌──────────────────────────────────────┐
               │ FpBench (dados + funções puras)      │
               │ input/1, default_sizes/0,            │
               │ double/1, even?/1, multiple_of_4?/1, │
               │ sum_squares/2, expected_pipeline*/1  │
               └──────────────────┬───────────────────┘
         ┌────────────────────────┼─────────────────────────┐
         ▼                        ▼                         ▼
 FpBench.Recursive         FpBench.Eager              FpBench.Lazy
 (recursão de cauda)       (Enum)                     (Stream)
 + pipeline_fused/1                                   + pipeline_stream/1
 + pipeline_selective_fused/1                         + pipeline_selective_stream/1
         └────────────────────────┼─────────────────────────┘
          mesma API: sum/1, map/2, filter/2, reverse/1, reduce/3,
                     pipeline/1, pipeline_selective/1
         ┌────────────────────────┴─────────────────────────┐
         ▼                                                  ▼
   test/ (ExUnit)                                bench/run.exs (Benchee)
   equivalência + preguiça                       tempo + memória → results/
```

Decisões de projeto:

- **API idêntica** nos três módulos — o estilo é um parâmetro (módulo como valor).
- **Mesmas funções por elemento** — `FpBench.double/1`, `even?/1`,
  `multiple_of_4?/1`, `sum_squares/2`. Varia só a estratégia de travessia.
- **Entrada materializada** — `FpBench.input/1` devolve `[1, ..., n]` uma
  vez, antes da medição.
- **Código medido puro** — sem estado nem efeitos colaterais.
- **Dois pipelines** — mesma estrutura, seletividade do filtro diferente
  (seção 4).

## 3. Conceitos de programação funcional

| Conceito | Onde aparece |
|---|---|
| Funções puras | `lib/` — resultado depende só dos argumentos |
| Imutabilidade | entrada intacta; estágios devolvem listas novas |
| Casamento de padrões | `do_*([], acc)` e `do_*([head \| tail], acc)` em `Recursive` |
| Recursão de cauda | auxiliares `do_*`; pilha constante (testado com 10⁶ elementos) |
| Funções de alta ordem | `map/2`, `filter/2`, `reduce/3`; `Enum`/`Stream` |
| Composição | operador `\|>` nos pipelines |
| Avaliação preguiçosa | `Stream.map/2`, `Stream.filter/2`, `Stream.scan/2,3` |
| Fusão de estágios | `Stream` (elemento a elemento); `recursive_fused` (manual) |

## 4. Módulos

### `FpBench` (`lib/fp_bench.ex`)

| Função | Papel |
|---|---|
| `input/1` | entrada `[1, ..., n]` |
| `default_sizes/0` | `[1_000, 10_000, 100_000]` |
| `double/1`, `even?/1`, `multiple_of_4?/1`, `sum_squares/2` | funções por elemento |
| `expected_pipeline/1` | forma fechada `n·(n+1)` (todo `2·i` é par) |
| `expected_pipeline_selective/1` | `2·k·(k+1)` com `k = ⌊n/2⌋` |

### `FpBench.Recursive` (`lib/fp_bench/recursive.ex`)

Cada função pública delega a um auxiliar com acumulador; a chamada
recursiva é a última expressão da cláusula.

- `sum/1` — `do_sum([h \| t], acc) -> do_sum(t, acc + h)`
- `map/2` e `filter/2` — prepend O(1) + uma inversão no caso-base (evita
  `acc ++ [x]`, que seria O(n²))
- `reverse/1` — o acumulador já é a lista invertida
- `reduce/3` — fold à esquerda, convenção de `Enum.reduce/3`
- `pipeline/1` e `pipeline_selective/1` — `map |> filter |> sum` em três
  passadas (duas listas intermediárias)
- `pipeline_fused/1` e `pipeline_selective_fused/1` — uma passada, sem
  listas intermediárias (controle para isolar o custo das intermediárias)

### `FpBench.Eager` (`lib/fp_bench/eager.ex`)

Delegação a `Enum.sum/1`, `Enum.map/2`, `Enum.filter/2`, `Enum.reverse/1`
e `Enum.reduce/3`. Cada estágio do pipeline materializa a lista inteira
antes do próximo.

### `FpBench.Lazy` (`lib/fp_bench/lazy.ex`)

`Stream` devolve uma receita; a avaliação ocorre só quando `Enum` força o
stream, uma vez, no último passo.

- `map/2`, `filter/2` — `Stream.*` + `Enum.to_list/1`
- `sum/1`, `reduce/3` — `Stream.scan/2,3`; o último valor emitido é o resultado
- `reverse/1` — estrito por natureza (`Stream.chunk_while/4`)
- `pipeline_stream/1`, `pipeline_selective_stream/1` — pipelines não forçados
- `pipeline/1`, `pipeline_selective/1` — forçados por `Enum.sum/1`

### Pipelines

| | `pipeline` | `pipeline_selective` |
|---|---|---|
| Estágios | `double` → `even?` → soma | `double` → `multiple_of_4?` → soma |
| Fração mantida pelo filtro | 100% | 50% |
| 2ª lista intermediária (`eager` / `recursive`) | `n` | `⌊n/2⌋` |
| Listas intermediárias (`lazy` / `fused`) | nenhuma | nenhuma |
| Resultado em `input(n)` | `n·(n+1)` | `2·k·(k+1)`, `k = ⌊n/2⌋` |

### Testes (`test/`)

| Arquivo | Cobertura |
|---|---|
| `equivalence_test.exs` | três estilos + `recursive_fused` ≡ oráculo `:lists`; formas fechadas; filtro seletivo = 50%; `n` até 10⁶ |
| `lazy_test.exs` | nenhum elemento antes de forçar; streams infinitos; fusão elemento a elemento |
| `recursive_test.exs` | casos-base, ordem, listas próprias, aridade, pilha constante |
| `fp_bench_test.exs` | `input/1`, formas fechadas, doctests |

### Benchmark (`bench/run.exs`)

Um `Benchee.run/2` por operação, todos os estilos e tamanhos configurados.
Saídas: `results/<operacao>.csv`, `results/html/` (opcional),
`results/environment.txt`. Entradas geradas antes da medição;
`pre_check: true`.

Variáveis: `BENCH_SIZES`, `BENCH_FULL`, `BENCH_OPS`, `BENCH_TIME`,
`BENCH_WARMUP`, `BENCH_MEMORY_TIME`, `BENCH_QUICK`, `BENCH_OUT`, `BENCH_HTML`
(detalhes no README).

### Energia (`bench/energy.exs`, `bench/energy_rapl.sh`)

Carga fixa (sem Benchee) + leitura RAPL antes/depois, com tratamento de
*wraparound*. Saída: `results/energy.csv`.

## 5. Protocolo experimental

**Independentes:** estilo (`recursive`, `eager`, `lazy`; + `recursive_fused`
nos pipelines), operação e `n ∈ {1.000, 10.000, 100.000}` (`BENCH_FULL=1`
acrescenta 1.000.000).

**Dependentes:** tempo (média, mediana, desvio, p99), memória alocada;
energia opcional.

**Benchee padrão:** warmup 2 s, time 5 s, memory_time 1 s.
`BENCH_QUICK=1` usa 0,2 / 0,5 / 0,2 s.

**Controles:** mesma entrada, mesmas funções por elemento, mesma sessão
BEAM; aquecimento; memória em janela separada; `mix test` antes das
medições. O WSL compartilha CPU com o host Windows.

**Ambiente:** `results/environment.txt` e cabeçalho do Benchee (CPU,
memória, SO) — ver [`RESULTADOS.md`](RESULTADOS.md).

## 6. Ameaças à validade

- **Interna:** ruído do SO, frequência da CPU, GC da BEAM, JIT; no WSL, VM
  compartilhada com o host.
- **Construção:** memória do Benchee vem do rastreamento de GC; RAPL mede o
  pacote inteiro da CPU; `Lazy.sum/1` usa `Stream.scan` (escolha de projeto).
- **Externa:** depende de OTP (JIT desde OTP 24), hardware e SO;
  microbenchmarks com listas de inteiros não generalizam para I/O ou
  concorrência.
- **Pipelines:** apenas duas seletividades (100% e 50%) e estágios baratos
  por elemento.

## 7. Energia (RAPL)

- Contadores em `/sys/class/powercap/intel-rapl:*` (µJ).
- Desde o kernel 5.10, `energy_uj` exige root (mitigação *PLATYPUS*).
- `energy_rapl.sh` inclui a inicialização da VM; para isolá-la, medir dois
  números de iterações e usar a diferença.
- WSL e Windows não expõem RAPL.

## 8. Correspondência com o artigo

| Metodologia (`metodologia.tex`) | Artefato |
|---|---|
| Estilos comparados | `lib/fp_bench/{recursive,eager,lazy}.ex` |
| Carga de trabalho | `FpBench.input/1` e funções em `lib/fp_bench.ex` |
| Pipelines e formas fechadas | `pipeline/1`, `pipeline_selective/1`, `expected_pipeline*/1` |
| Equivalência semântica | `test/fp_bench/equivalence_test.exs` |
| Preguiça do `Stream` | `test/fp_bench/lazy_test.exs` |
| Instrumento | `bench/run.exs` |
| Dados | `results/*.csv`, `results/environment.txt` |
| Energia | `bench/energy.exs`, `bench/energy_rapl.sh` |
