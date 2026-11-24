defmodule FpBench.EquivalenceTest do
  @moduledoc "Equivalência entre Recursive, Eager, Lazy e o oráculo `:lists`."
  use ExUnit.Case, async: true

  alias FpBench.{Eager, Lazy, Recursive}

  @styles [recursive: Recursive, eager: Eager, lazy: Lazy]
  @sizes [0, 1, 2, 3, 10, 1_000, 10_000]

  defp cases do
    Enum.flat_map(@sizes, fn n ->
      [
        {"input(#{n})", FpBench.input(n)},
        {"random(#{n})", random_list(n, n + 1)}
      ]
    end)
  end

  defp random_list(n, seed) do
    state = :rand.seed_s(:exsss, {seed, seed * 7, seed * 13})

    {list, _state} =
      Enum.map_reduce(1..n//1, state, fn _, st ->
        {value, st} = :rand.uniform_s(2_001, st)
        {value - 1_001, st}
      end)

    list
  end

  defp assert_all_styles(label, expected, fun) do
    for {style, module} <- @styles do
      assert fun.(module) == expected, "#{style} differs on #{label}"
    end
  end

  test "sum/1 is equivalent in all styles" do
    for {label, list} <- cases() do
      assert_all_styles(label, :lists.sum(list), fn m -> m.sum(list) end)
    end
  end

  test "map/2 is equivalent in all styles" do
    for {label, list} <- cases() do
      expected = :lists.map(&FpBench.double/1, list)
      assert_all_styles(label, expected, fn m -> m.map(list, &FpBench.double/1) end)
    end
  end

  test "filter/2 is equivalent in all styles" do
    for {label, list} <- cases() do
      expected = :lists.filter(&FpBench.even?/1, list)
      assert_all_styles(label, expected, fn m -> m.filter(list, &FpBench.even?/1) end)
    end
  end

  test "reverse/1 is equivalent in all styles" do
    for {label, list} <- cases() do
      assert_all_styles(label, :lists.reverse(list), fn m -> m.reverse(list) end)
    end
  end

  test "reduce/3 is equivalent in all styles" do
    for {label, list} <- cases() do
      expected = :lists.foldl(&FpBench.sum_squares/2, 0, list)
      assert_all_styles(label, expected, fn m -> m.reduce(list, 0, &FpBench.sum_squares/2) end)
    end
  end

  test "reduce/3 respects element order (non-commutative reducer)" do
    cons = fn x, acc -> [x | acc] end

    for {label, list} <- cases() do
      expected = :lists.foldl(cons, [], list)
      assert_all_styles(label, expected, fn m -> m.reduce(list, [], cons) end)
    end
  end

  test "pipeline/1 (map -> filter -> sum) is equivalent in all styles" do
    for {label, list} <- cases() do
      doubled = :lists.map(&FpBench.double/1, list)
      expected = :lists.sum(:lists.filter(&FpBench.even?/1, doubled))

      assert_all_styles(label, expected, fn m -> m.pipeline(list) end)
      assert Recursive.pipeline_fused(list) == expected, "recursive_fused differs on #{label}"
    end
  end

  test "pipeline/1 matches the closed form n * (n + 1) on the benchmark input" do
    for n <- @sizes do
      list = FpBench.input(n)
      expected = FpBench.expected_pipeline(n)

      assert_all_styles("input(#{n})", expected, fn m -> m.pipeline(list) end)
      assert Recursive.pipeline_fused(list) == expected
    end
  end

  test "pipeline_selective/1 (map -> keep multiples of 4 -> sum) is equivalent" do
    for {label, list} <- cases() do
      doubled = :lists.map(&FpBench.double/1, list)
      expected = :lists.sum(:lists.filter(&FpBench.multiple_of_4?/1, doubled))

      assert_all_styles(label, expected, fn m -> m.pipeline_selective(list) end)

      assert Recursive.pipeline_selective_fused(list) == expected,
             "recursive_fused differs on #{label}"
    end
  end

  test "pipeline_selective/1 matches the closed form 2k(k + 1), k = div(n, 2)" do
    for n <- @sizes do
      list = FpBench.input(n)
      expected = FpBench.expected_pipeline_selective(n)

      assert_all_styles("input(#{n})", expected, fn m -> m.pipeline_selective(list) end)
      assert Recursive.pipeline_selective_fused(list) == expected
    end
  end

  test "the selective filter keeps exactly half of the doubled benchmark input" do
    for n <- [2, 10, 1_000, 10_000] do
      kept =
        n
        |> FpBench.input()
        |> Enum.map(&FpBench.double/1)
        |> Enum.filter(&FpBench.multiple_of_4?/1)

      assert length(kept) == div(n, 2)
    end
  end

  test "single-element lists" do
    for x <- [-3, 0, 1, 2, 7] do
      list = [x]
      assert_all_styles("[#{x}]", x, fn m -> m.sum(list) end)
      assert_all_styles("[#{x}]", [2 * x], fn m -> m.map(list, &FpBench.double/1) end)
      assert_all_styles("[#{x}]", list, fn m -> m.reverse(list) end)
      assert_all_styles("[#{x}]", x * x, fn m -> m.reduce(list, 0, &FpBench.sum_squares/2) end)
      assert_all_styles("[#{x}]", 2 * x, fn m -> m.pipeline(list) end)
    end
  end

  test "all styles handle the largest benchmark input (1_000_000)" do
    list = FpBench.input(1_000_000)
    expected = FpBench.expected_pipeline(1_000_000)
    expected_selective = FpBench.expected_pipeline_selective(1_000_000)

    assert_all_styles("input(1_000_000)", 500_000_500_000, fn m -> m.sum(list) end)
    assert_all_styles("input(1_000_000)", expected, fn m -> m.pipeline(list) end)
    assert Recursive.pipeline_fused(list) == expected

    assert_all_styles("input(1_000_000)", expected_selective, fn m ->
      m.pipeline_selective(list)
    end)

    assert Recursive.pipeline_selective_fused(list) == expected_selective
  end
end
