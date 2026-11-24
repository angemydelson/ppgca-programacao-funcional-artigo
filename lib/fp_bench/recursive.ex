defmodule FpBench.Recursive do
  @moduledoc """
  Operações sobre listas com recursão de cauda e acumulador.

  `pipeline/1` e `pipeline_selective/1` compõem `map` → `filter` → `sum` em
  três passos. `pipeline_fused/1` e `pipeline_selective_fused/1` fazem o
  mesmo cálculo em uma passada.

  ## Examples

      iex> FpBench.Recursive.sum([1, 2, 3])
      6

      iex> FpBench.Recursive.map([1, 2, 3], &FpBench.double/1)
      [2, 4, 6]

      iex> FpBench.Recursive.reverse([1, 2, 3])
      [3, 2, 1]
  """

  @doc "Soma dos elementos."
  @spec sum([number()]) :: number()
  def sum(list) when is_list(list), do: do_sum(list, 0)

  defp do_sum([], acc), do: acc
  defp do_sum([head | tail], acc), do: do_sum(tail, acc + head)

  @doc "Aplica `fun` a cada elemento, preservando a ordem."
  @spec map([term()], (term() -> term())) :: [term()]
  def map(list, fun) when is_list(list) and is_function(fun, 1), do: do_map(list, fun, [])

  defp do_map([], _fun, acc), do: reverse(acc)
  defp do_map([head | tail], fun, acc), do: do_map(tail, fun, [fun.(head) | acc])

  @doc "Mantém elementos para os quais `pred` é truthy, preservando a ordem."
  @spec filter([term()], (term() -> as_boolean(term()))) :: [term()]
  def filter(list, pred) when is_list(list) and is_function(pred, 1),
    do: do_filter(list, pred, [])

  defp do_filter([], _pred, acc), do: reverse(acc)

  defp do_filter([head | tail], pred, acc) do
    if pred.(head) do
      do_filter(tail, pred, [head | acc])
    else
      do_filter(tail, pred, acc)
    end
  end

  @doc "Inverte a lista."
  @spec reverse([term()]) :: [term()]
  def reverse(list) when is_list(list), do: do_reverse(list, [])

  defp do_reverse([], acc), do: acc
  defp do_reverse([head | tail], acc), do: do_reverse(tail, [head | acc])

  @doc "Fold à esquerda (`fun.(elemento, acc)`), como `Enum.reduce/3`."
  @spec reduce([term()], acc, (term(), acc -> acc)) :: acc when acc: term()
  def reduce(list, acc, fun) when is_list(list) and is_function(fun, 2),
    do: do_reduce(list, acc, fun)

  defp do_reduce([], acc, _fun), do: acc
  defp do_reduce([head | tail], acc, fun), do: do_reduce(tail, fun.(head, acc), fun)

  @doc "Pipeline map → filter → sum (double, pares, soma) em três passos."
  @spec pipeline([integer()]) :: integer()
  def pipeline(list) when is_list(list) do
    list
    |> map(&FpBench.double/1)
    |> filter(&FpBench.even?/1)
    |> sum()
  end

  @doc "Mesmo resultado de `pipeline/1` em uma passada (fusão manual)."
  @spec pipeline_fused([integer()]) :: integer()
  def pipeline_fused(list) when is_list(list), do: do_pipeline(list, 0)

  defp do_pipeline([], acc), do: acc

  defp do_pipeline([head | tail], acc) do
    doubled = FpBench.double(head)

    if FpBench.even?(doubled) do
      do_pipeline(tail, acc + doubled)
    else
      do_pipeline(tail, acc)
    end
  end

  @doc "Pipeline seletivo map → filter → sum (double, múltiplos de 4, soma)."
  @spec pipeline_selective([integer()]) :: integer()
  def pipeline_selective(list) when is_list(list) do
    list
    |> map(&FpBench.double/1)
    |> filter(&FpBench.multiple_of_4?/1)
    |> sum()
  end

  @doc "Mesmo resultado de `pipeline_selective/1` em uma passada (fusão manual)."
  @spec pipeline_selective_fused([integer()]) :: integer()
  def pipeline_selective_fused(list) when is_list(list), do: do_pipeline_selective(list, 0)

  defp do_pipeline_selective([], acc), do: acc

  defp do_pipeline_selective([head | tail], acc) do
    doubled = FpBench.double(head)

    if FpBench.multiple_of_4?(doubled) do
      do_pipeline_selective(tail, acc + doubled)
    else
      do_pipeline_selective(tail, acc)
    end
  end
end
