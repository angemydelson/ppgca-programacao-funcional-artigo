defmodule FpBench.Eager do
  @moduledoc """
  Operações via `Enum`. Cada estágio materializa o resultado antes do próximo.

  ## Examples

      iex> FpBench.Eager.filter([1, 2, 3, 4], &FpBench.even?/1)
      [2, 4]

      iex> FpBench.Eager.pipeline([1, 2, 3])
      12

      iex> FpBench.Eager.pipeline_selective([1, 2, 3, 4])
      12
  """

  @doc "Soma com `Enum.sum/1`."
  @spec sum(Enumerable.t()) :: number()
  def sum(enumerable), do: Enum.sum(enumerable)

  @doc "Mapa com `Enum.map/2`."
  @spec map(Enumerable.t(), (term() -> term())) :: [term()]
  def map(enumerable, fun), do: Enum.map(enumerable, fun)

  @doc "Filtro com `Enum.filter/2`."
  @spec filter(Enumerable.t(), (term() -> as_boolean(term()))) :: [term()]
  def filter(enumerable, pred), do: Enum.filter(enumerable, pred)

  @doc "Inversão com `Enum.reverse/1`."
  @spec reverse(Enumerable.t()) :: [term()]
  def reverse(enumerable), do: Enum.reverse(enumerable)

  @doc "Fold à esquerda com `Enum.reduce/3`."
  @spec reduce(Enumerable.t(), acc, (term(), acc -> acc)) :: acc when acc: term()
  def reduce(enumerable, acc, fun), do: Enum.reduce(enumerable, acc, fun)

  @doc "Pipeline map → filter → sum (double, pares, soma)."
  @spec pipeline(Enumerable.t()) :: integer()
  def pipeline(enumerable) do
    enumerable
    |> Enum.map(&FpBench.double/1)
    |> Enum.filter(&FpBench.even?/1)
    |> Enum.sum()
  end

  @doc "Pipeline seletivo map → filter → sum (double, múltiplos de 4, soma)."
  @spec pipeline_selective(Enumerable.t()) :: integer()
  def pipeline_selective(enumerable) do
    enumerable
    |> Enum.map(&FpBench.double/1)
    |> Enum.filter(&FpBench.multiple_of_4?/1)
    |> Enum.sum()
  end
end
