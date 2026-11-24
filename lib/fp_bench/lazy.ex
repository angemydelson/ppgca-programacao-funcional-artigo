defmodule FpBench.Lazy do
  @moduledoc """
  Operações via `Stream`. Estágios só são avaliados quando forçados (em geral
  por `Enum` no fim).

  `sum/1` e `reduce/3` usam `Stream.scan`; `reverse/1` usa
  `Stream.chunk_while`. `pipeline_stream/1` e `pipeline_selective_stream/1`
  devolvem streams não forçados.

  ## Examples

      iex> FpBench.Lazy.sum([1, 2, 3])
      6

      iex> FpBench.Lazy.reverse([1, 2, 3])
      [3, 2, 1]

      iex> FpBench.Lazy.pipeline_stream(Stream.iterate(1, &(&1 + 1))) |> Enum.take(3)
      [2, 4, 6]

      iex> FpBench.Lazy.pipeline_selective_stream(Stream.iterate(1, &(&1 + 1))) |> Enum.take(3)
      [4, 8, 12]
  """

  @doc "Soma via `Stream.scan/2`, forçada no fim."
  @spec sum(Enumerable.t()) :: number()
  def sum(enumerable) do
    enumerable
    |> Stream.scan(&+/2)
    |> last(0)
  end

  @doc "Mapa lazy forçado com `Enum.to_list/1`."
  @spec map(Enumerable.t(), (term() -> term())) :: [term()]
  def map(enumerable, fun) do
    enumerable
    |> Stream.map(fun)
    |> Enum.to_list()
  end

  @doc "Filtro lazy forçado com `Enum.to_list/1`."
  @spec filter(Enumerable.t(), (term() -> as_boolean(term()))) :: [term()]
  def filter(enumerable, pred) do
    enumerable
    |> Stream.filter(pred)
    |> Enum.to_list()
  end

  @doc "Inversão via `Stream.chunk_while/4` (operação estrita)."
  @spec reverse(Enumerable.t()) :: [term()]
  def reverse(enumerable) do
    enumerable
    |> Stream.chunk_while([], &prepend/2, &emit_reversed/1)
    |> last([])
  end

  @doc "Fold à esquerda via `Stream.scan/3`, forçado no fim."
  @spec reduce(Enumerable.t(), acc, (term(), acc -> acc)) :: acc when acc: term()
  def reduce(enumerable, acc, fun) do
    enumerable
    |> Stream.scan(acc, fun)
    |> last(acc)
  end

  @doc "Pipeline map → filter (double, pares) sem forçar."
  @spec pipeline_stream(Enumerable.t()) :: Enumerable.t()
  def pipeline_stream(enumerable) do
    enumerable
    |> Stream.map(&FpBench.double/1)
    |> Stream.filter(&FpBench.even?/1)
  end

  @doc "Pipeline map → filter → sum (double, pares, soma)."
  @spec pipeline(Enumerable.t()) :: integer()
  def pipeline(enumerable) do
    enumerable
    |> pipeline_stream()
    |> Enum.sum()
  end

  @doc "Pipeline seletivo map → filter (double, múltiplos de 4) sem forçar."
  @spec pipeline_selective_stream(Enumerable.t()) :: Enumerable.t()
  def pipeline_selective_stream(enumerable) do
    enumerable
    |> Stream.map(&FpBench.double/1)
    |> Stream.filter(&FpBench.multiple_of_4?/1)
  end

  @doc "Pipeline seletivo map → filter → sum (double, múltiplos de 4, soma)."
  @spec pipeline_selective(Enumerable.t()) :: integer()
  def pipeline_selective(enumerable) do
    enumerable
    |> pipeline_selective_stream()
    |> Enum.sum()
  end

  defp prepend(element, acc), do: {:cont, [element | acc]}

  defp emit_reversed(acc), do: {:cont, acc, []}

  defp last(stream, default), do: Enum.reduce(stream, default, fn element, _ -> element end)
end
