# Resultados

Medição completa no WSL 2 (não `BENCH_QUICK`). Fonte: `results/*.csv`.
Procedimento: [`REPRODUCAO.md`](REPRODUCAO.md).

## 1. Ambiente

| Item | Valor |
|---|---|
| Data | 2026-11-20 |
| CPU | i7-1355U |
| Schedulers | 12 |
| RAM (VM WSL) | ~7,6 GB |
| Host | Windows + WSL 2 (Ubuntu) |
| Elixir / OTP | 1.17.3 / 27.1.2 |
| Benchee | warmup 2 s / time 5 s / memory_time 1 s |
| Tamanhos | 1.000, 10.000, 100.000 |
| Operações | `pipeline`, `pipeline_selective` |
| Energia | não medida (WSL sem RAPL) |

## 2. Verificação

| Checagem | Resultado |
|---|---|
| `mix test` | 25 doctests + 37 testes, 0 failures |
| `mix format --check-formatted` | ok |

## 3. Tempo (mediana)

### `pipeline` (filtro 100%)

| n | fused | Stream | Enum | recursão 3 passos |
|---|---|---|---|---|
| 1.000 | **7,35 µs** | 52,23 µs | 42,86 µs | 48,10 µs |
| 10.000 | **76,72 µs** | 594 µs | 600 µs | 1083 µs |
| 100.000 | **1,00 ms** | 6,37 ms | 11,69 ms | 21,77 ms |

### `pipeline_selective` (filtro 50%)

| n | fused | Stream | Enum | recursão 3 passos |
|---|---|---|---|---|
| 1.000 | **10,34 µs** | 39,08 µs | 37,65 µs | 35,37 µs |
| 10.000 | **103 µs** | 430 µs | 431 µs | 452 µs |
| 100.000 | **1,28 ms** | 5,35 ms | 13,77 ms | 13,47 ms |

## 4. Memória (heap cumulativo, `n = 100.000`)

| Estilo | pipeline | seletivo |
|---|---|---|
| Fusão | **0 B** | **0 B** |
| Enum | 3,05 MB | 2,29 MB |
| Stream | 6,10 MB | 4,20 MB |
| Recursão 3 passos | 6,10 MB | 4,58 MB |

Coluna *Memory* do Benchee: alocação cumulativa no heap (não RSS nem
memória viva pós-GC).

## 5. Energia

Não medida. RAPL em Linux nativo: [`AMBIENTE.md`](AMBIENTE.md),
[`REPRODUCAO.md`](REPRODUCAO.md).

## 6. Notas

Em `n = 10³` e `10⁴` a ordem entre Enum, Stream e recursão em 3 passos
oscila; em `n = 10⁵` estabiliza. Desvio relativo alto em `n` pequeno é
típico neste ambiente (notebook / WSL).

## 7. Síntese (`n = 10⁵`)

| Aspecto | Observação |
|---|---|
| Tempo | fusão ≪ Stream ≪ Enum; no seletivo, Enum ≈ recursão 3 passos; no pipeline 100%, recursão 3 passos é a mais lenta |
| Stream vs Enum | Stream ~1,8× (pipeline) a ~2,6× (seletivo) mais rápido; aloca mais no heap |
| Memória | fusão 0 B; filtro seletivo reduz alocação eager (2ª lista menor) |
| Energia | fora do escopo neste ambiente |
