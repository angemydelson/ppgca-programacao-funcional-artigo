defmodule FpBench.RecursiveTest do
  use ExUnit.Case, async: true

  alias FpBench.Recursive

  test "functions that build lists preserve the original order" do
    assert Recursive.map([1, 2, 3], &(&1 + 10)) == [11, 12, 13]
    assert Recursive.filter([5, 4, 3, 2, 1], &(&1 > 2)) == [5, 4, 3]
  end

  test "base cases return the accumulator's initial value" do
    assert Recursive.sum([]) == 0
    assert Recursive.map([], &FpBench.double/1) == []
    assert Recursive.filter([], &FpBench.even?/1) == []
    assert Recursive.reverse([]) == []
    assert Recursive.reduce([], :initial, fn _, acc -> acc end) == :initial
    assert Recursive.pipeline([]) == 0
    assert Recursive.pipeline_fused([]) == 0
    assert Recursive.pipeline_selective([]) == 0
    assert Recursive.pipeline_selective_fused([]) == 0
  end

  test "single-element lists" do
    assert Recursive.sum([5]) == 5
    assert Recursive.map([5], &FpBench.double/1) == [10]
    assert Recursive.filter([5], &FpBench.even?/1) == []
    assert Recursive.reverse([5]) == [5]
    assert Recursive.pipeline_selective([1]) == 0
    assert Recursive.pipeline_selective_fused([2]) == 4
  end

  test "only accepts proper lists" do
    assert_raise FunctionClauseError, fn -> Recursive.sum(1..3) end
    assert_raise FunctionClauseError, fn -> Recursive.pipeline_selective(1..3) end
    assert_raise FunctionClauseError, fn -> Recursive.pipeline_selective_fused(1..3) end
  end

  test "functions that receive functions check their arity" do
    assert_raise FunctionClauseError, fn -> Recursive.map([1], fn _, _ -> :bad end) end
    assert_raise FunctionClauseError, fn -> Recursive.reduce([1], 0, fn _ -> :bad end) end
  end

  test "deep recursion runs in constant stack space (tail calls)" do
    list = FpBench.input(1_000_000)
    assert Recursive.sum(list) == 500_000_500_000
    expected = FpBench.expected_pipeline_selective(1_000_000)
    assert Recursive.pipeline_selective_fused(list) == expected
  end

  test "filter treats any truthy value as true" do
    assert Recursive.filter([1, nil, 2, false], & &1) == [1, 2]
  end
end
