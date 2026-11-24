# Carga fixa para medição de energia (sem Benchee).
#
#   mix run bench/energy.exs <op> <estilo> <tamanho> <iterações>
#   mix run bench/energy.exs pipeline lazy 100000 200
#
# op: sum | map | filter | reverse | reduce | pipeline | pipeline_selective
# estilo: recursive | eager | lazy | recursive_fused (só pipelines)

alias FpBench.{Eager, Lazy, Recursive}

usage = "usage: mix run bench/energy.exs <operation> <style> <size> <iterations>"

[op, style, size, iterations] =
  case System.argv() do
    [_, _, _, _] = args -> args
    _ -> raise ArgumentError, usage
  end

size = String.to_integer(size)
iterations = String.to_integer(iterations)

if size < 0 or iterations < 1 do
  raise ArgumentError, "size must be >= 0 and iterations >= 1. " <> usage
end

module =
  case style do
    "recursive" -> Recursive
    "recursive_fused" -> Recursive
    "eager" -> Eager
    "lazy" -> Lazy
    other -> raise ArgumentError, "unknown style #{inspect(other)}. " <> usage
  end

job =
  case {op, style} do
    {"pipeline", "recursive_fused"} -> &Recursive.pipeline_fused/1
    {"pipeline_selective", "recursive_fused"} -> &Recursive.pipeline_selective_fused/1
    {_, "recursive_fused"} -> raise ArgumentError, "recursive_fused only exists for pipelines"
    {"pipeline_selective", _} -> &module.pipeline_selective/1
    {"sum", _} -> &module.sum/1
    {"map", _} -> fn list -> module.map(list, &FpBench.double/1) end
    {"filter", _} -> fn list -> module.filter(list, &FpBench.even?/1) end
    {"reverse", _} -> &module.reverse/1
    {"reduce", _} -> fn list -> module.reduce(list, 0, &FpBench.sum_squares/2) end
    {"pipeline", _} -> &module.pipeline/1
    {other, _} -> raise ArgumentError, "unknown operation #{inspect(other)}. " <> usage
  end

list = FpBench.input(size)

job.(list)

{microseconds, _} =
  :timer.tc(fn ->
    Enum.each(1..iterations//1, fn _ -> job.(list) end)
  end)

IO.puts("op=#{op} style=#{style} size=#{size} iterations=#{iterations} wall_us=#{microseconds}")
