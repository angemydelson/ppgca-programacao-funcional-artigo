defmodule FpBench.LazyTest do
  @moduledoc "Propriedades de preguiça e fusão de estágios do `Stream`."
  use ExUnit.Case, async: true

  alias FpBench.Lazy

  defp traced(list) do
    parent = self()

    Stream.map(list, fn x ->
      send(parent, {:pulled, x})
      x
    end)
  end

  test "pipeline_stream/1 does not evaluate any element before being forced" do
    stream = Lazy.pipeline_stream(traced([1, 2, 3]))

    refute_received {:pulled, _}
    assert Enum.sum(stream) == 12
    assert_received {:pulled, 1}
    assert_received {:pulled, 2}
    assert_received {:pulled, 3}
  end

  test "pipeline_stream/1 only pulls the elements that are demanded" do
    [1, 2, 3, 4, 5]
    |> traced()
    |> Lazy.pipeline_stream()
    |> Enum.take(2)

    assert_received {:pulled, 1}
    assert_received {:pulled, 2}
    refute_received {:pulled, 3}
  end

  test "pipeline_stream/1 works on infinite streams" do
    naturals = Stream.iterate(1, &(&1 + 1))
    assert naturals |> Lazy.pipeline_stream() |> Enum.take(5) == [2, 4, 6, 8, 10]
  end

  test "stages are fused: each element passes through all stages before the next" do
    parent = self()

    [1, 2]
    |> Stream.map(fn x -> send(parent, {:map, x}) && x * 2 end)
    |> Stream.filter(fn x -> send(parent, {:filter, x}) && rem(x, 2) == 0 end)
    |> Enum.to_list()

    {:messages, messages} = Process.info(self(), :messages)
    assert messages == [{:map, 1}, {:filter, 2}, {:map, 2}, {:filter, 4}]
  end

  test "pipeline_selective_stream/1 does not evaluate any element before being forced" do
    stream = Lazy.pipeline_selective_stream(traced([1, 2, 3, 4]))

    refute_received {:pulled, _}
    assert Enum.to_list(stream) == [4, 8]
    for x <- 1..4, do: assert_received({:pulled, ^x})
  end

  test "pipeline_selective_stream/1 pulls only until enough elements pass the filter" do
    assert 1..10 |> traced() |> Lazy.pipeline_selective_stream() |> Enum.take(2) == [4, 8]

    for x <- 1..4, do: assert_received({:pulled, ^x})
    refute_received {:pulled, 5}
  end

  test "pipeline_selective_stream/1 works on infinite streams" do
    naturals = Stream.iterate(1, &(&1 + 1))
    assert naturals |> Lazy.pipeline_selective_stream() |> Enum.take(3) == [4, 8, 12]
  end

  test "fusion with a selective filter: discarded elements never reach later stages" do
    parent = self()

    [1, 2, 3]
    |> Stream.map(fn x -> send(parent, {:map, x}) && x * 2 end)
    |> Stream.filter(fn x -> send(parent, {:filter, x}) && rem(x, 4) == 0 end)
    |> Stream.map(fn x -> send(parent, {:after, x}) && x end)
    |> Enum.to_list()

    {:messages, messages} = Process.info(self(), :messages)

    assert messages == [
             {:map, 1},
             {:filter, 2},
             {:map, 2},
             {:filter, 4},
             {:after, 4},
             {:map, 3},
             {:filter, 6}
           ]
  end

  test "lazy operations accept any enumerable (e.g. ranges)" do
    assert Lazy.sum(1..10) == 55
    assert Lazy.reverse(1..3) == [3, 2, 1]
    assert Lazy.pipeline(1..3) == 12
    assert Lazy.pipeline_selective(1..4) == 12
  end

  test "lazy operations handle empty and single-element enumerables" do
    assert Lazy.sum([]) == 0
    assert Lazy.reverse([]) == []
    assert Lazy.reduce([], :initial, fn _, acc -> acc end) == :initial
    assert Lazy.pipeline([]) == 0
    assert Lazy.pipeline_selective([]) == 0
    assert Lazy.sum([7]) == 7
    assert Lazy.reverse([7]) == [7]
    assert Lazy.pipeline_selective([2]) == 4
  end
end
