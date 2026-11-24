defmodule FpBenchTest do
  use ExUnit.Case, async: true

  doctest FpBench
  doctest FpBench.Recursive
  doctest FpBench.Eager
  doctest FpBench.Lazy

  describe "input/1" do
    test "builds the list 1..n" do
      assert FpBench.input(3) == [1, 2, 3]
      assert length(FpBench.input(10_000)) == 10_000
    end

    test "returns an empty list for 0" do
      assert FpBench.input(0) == []
    end

    test "rejects negative sizes" do
      assert_raise FunctionClauseError, fn -> FpBench.input(-1) end
    end
  end

  test "expected_pipeline/1 matches a direct computation" do
    for n <- [0, 1, 7, 1_000] do
      direct = for(x <- 1..n//1, rem(2 * x, 2) == 0, do: 2 * x) |> Enum.sum()
      assert FpBench.expected_pipeline(n) == direct
    end
  end

  test "expected_pipeline_selective/1 matches a direct computation" do
    for n <- [0, 1, 2, 3, 4, 5, 7, 1_000, 1_001] do
      direct = for(x <- 1..n//1, rem(2 * x, 4) == 0, do: 2 * x) |> Enum.sum()
      assert FpBench.expected_pipeline_selective(n) == direct
    end
  end

  test "multiple_of_4?/1 handles zero and negatives" do
    assert FpBench.multiple_of_4?(0)
    assert FpBench.multiple_of_4?(-4)
    refute FpBench.multiple_of_4?(-2)
  end

  test "closed-form helpers reject negative sizes" do
    assert_raise FunctionClauseError, fn -> FpBench.expected_pipeline(-1) end
    assert_raise FunctionClauseError, fn -> FpBench.expected_pipeline_selective(-1) end
  end
end
