defmodule FpBench do
  @moduledoc """
  Helpers compartilhados por `FpBench.Recursive`, `FpBench.Eager` e
  `FpBench.Lazy` (mesma API e mesmas funções por elemento).

  Pipelines:

    * `pipeline` — double → even? → sum (100%; forma fechada `n*(n+1)`)
    * `pipeline_selective` — double → multiple_of_4? → sum
      (50%; forma fechada `2*k*(k+1)`, `k = div(n, 2)`)
  """

  @default_sizes [1_000, 10_000, 100_000]

  @doc """
  Entrada do experimento: lista `[1, 2, ..., n]` (materializada).

      iex> FpBench.input(5)
      [1, 2, 3, 4, 5]

      iex> FpBench.input(0)
      []
  """
  @spec input(non_neg_integer()) :: [pos_integer()]
  def input(n) when is_integer(n) and n >= 0, do: Enum.to_list(1..n//1)

  @doc """
  Tamanhos padrão do benchmark.

      iex> FpBench.default_sizes()
      [1_000, 10_000, 100_000]
  """
  @spec default_sizes() :: [pos_integer()]
  def default_sizes, do: @default_sizes

  @doc """
  Função de `map` / pipelines: dobra o valor.

      iex> FpBench.double(21)
      42
  """
  @spec double(integer()) :: integer()
  def double(x), do: x * 2

  @doc """
  Predicado de `filter` / `pipeline/1`.

      iex> FpBench.even?(4)
      true

      iex> FpBench.even?(-3)
      false
  """
  @spec even?(integer()) :: boolean()
  def even?(x), do: rem(x, 2) == 0

  @doc """
  Predicado de `pipeline_selective/1`.

      iex> FpBench.multiple_of_4?(8)
      true

      iex> FpBench.multiple_of_4?(6)
      false

      iex> FpBench.multiple_of_4?(-12)
      true
  """
  @spec multiple_of_4?(integer()) :: boolean()
  def multiple_of_4?(x), do: rem(x, 4) == 0

  @doc """
  Redutor de `reduce/3`: soma dos quadrados (`fun.(elemento, acc)`).

      iex> FpBench.sum_squares(3, 1)
      10
  """
  @spec sum_squares(integer(), integer()) :: integer()
  def sum_squares(x, acc), do: acc + x * x

  @doc """
  Forma fechada de `pipeline/1` sobre `input(n)`: `n * (n + 1)`.

      iex> FpBench.expected_pipeline(3)
      12

      iex> FpBench.expected_pipeline(0)
      0
  """
  @spec expected_pipeline(non_neg_integer()) :: non_neg_integer()
  def expected_pipeline(n) when is_integer(n) and n >= 0, do: n * (n + 1)

  @doc """
  Forma fechada de `pipeline_selective/1` sobre `input(n)`:
  `2 * k * (k + 1)` com `k = div(n, 2)`.

      iex> FpBench.expected_pipeline_selective(4)
      12

      iex> FpBench.expected_pipeline_selective(5)
      12

      iex> FpBench.expected_pipeline_selective(1)
      0
  """
  @spec expected_pipeline_selective(non_neg_integer()) :: non_neg_integer()
  def expected_pipeline_selective(n) when is_integer(n) and n >= 0 do
    k = div(n, 2)
    2 * k * (k + 1)
  end
end
