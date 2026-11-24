# Benchmark: Recursive / Eager / Lazy (Benchee).
#
#   mix run bench/run.exs
#   mix bench
#
# Env (opcional): BENCH_SIZES, BENCH_FULL, BENCH_OPS, BENCH_TIME, BENCH_WARMUP,
# BENCH_MEMORY_TIME, BENCH_QUICK, BENCH_HTML, BENCH_OUT.
# Saída: <BENCH_OUT>/<op>.csv, environment.txt; HTML se BENCH_HTML=1.

alias FpBench.{Eager, Lazy, Recursive}

parse_list = fn value, cast ->
  value
  |> String.split(",", trim: true)
  |> Enum.map(&(&1 |> String.trim() |> cast.()))
end

parse_number = fn value ->
  case Float.parse(value) do
    {number, ""} -> number
    _ -> raise ArgumentError, "invalid number: #{inspect(value)}"
  end
end

env_number = fn name, default ->
  case System.get_env(name) do
    nil -> default
    value -> parse_number.(value)
  end
end

quick? = System.get_env("BENCH_QUICK") == "1"
html? = System.get_env("BENCH_HTML") == "1"
out_dir = System.get_env("BENCH_OUT") || "results"

sizes =
  case System.get_env("BENCH_SIZES") do
    nil -> FpBench.default_sizes()
    value -> parse_list.(value, &String.to_integer/1)
  end

sizes = if System.get_env("BENCH_FULL") == "1", do: Enum.uniq(sizes ++ [1_000_000]), else: sizes

if sizes == [] or Enum.any?(sizes, &(&1 <= 0)) do
  raise ArgumentError, "BENCH_SIZES must be a non-empty list of positive integers"
end

all_ops = ~w(sum map filter reverse reduce pipeline pipeline_selective)

ops =
  case System.get_env("BENCH_OPS") do
    nil -> all_ops
    value -> parse_list.(value, & &1)
  end

unknown = ops -- all_ops
if unknown != [], do: raise(ArgumentError, "unknown operations: #{inspect(unknown)}")

{time, warmup, memory_time} =
  if quick? do
    {0.5, 0.2, 0.2}
  else
    {
      env_number.("BENCH_TIME", 5),
      env_number.("BENCH_WARMUP", 2),
      env_number.("BENCH_MEMORY_TIME", 1)
    }
  end

format_size = fn n ->
  n
  |> Integer.to_string()
  |> String.reverse()
  |> String.graphemes()
  |> Enum.chunk_every(3)
  |> Enum.join("_")
  |> String.reverse()
end

# CSV só com estatísticas (sem *_raw.csv).
write_stats_csv! = fn suite, path ->
  header =
    [
      "Name",
      "Input",
      "Iterations per Second",
      "Run Time Average",
      "Run Time Median",
      "Run Time Standard Deviation",
      "Run Time Standard Deviation Ratio",
      "Run Time Sample Size",
      "Memory Usage Average",
      "Memory Usage Median",
      "Memory Usage Sample Size"
    ]
    |> Enum.join(",")

  rows =
    suite.scenarios
    |> Enum.sort_by(fn s -> {s.input_name, s.name} end)
    |> Enum.map(fn s ->
      rt = s.run_time_data.statistics
      mem = s.memory_usage_data.statistics

      [
        s.name,
        s.input_name,
        rt.ips,
        rt.average,
        rt.median,
        rt.std_dev,
        rt.std_dev_ratio,
        rt.sample_size,
        mem.average,
        mem.median,
        mem.sample_size
      ]
      |> Enum.map(fn
        nil -> ""
        value when is_binary(value) -> value
        value -> to_string(value)
      end)
      |> Enum.join(",")
    end)

  File.write!(path, Enum.join([header | rows], "\n") <> "\n")
  IO.puts("statistics CSV written to #{path}")
end

inputs = Enum.map(sizes, fn n -> {format_size.(n), FpBench.input(n)} end)

jobs = %{
  "sum" => %{
    "recursive" => fn list -> Recursive.sum(list) end,
    "eager" => fn list -> Eager.sum(list) end,
    "lazy" => fn list -> Lazy.sum(list) end
  },
  "map" => %{
    "recursive" => fn list -> Recursive.map(list, &FpBench.double/1) end,
    "eager" => fn list -> Eager.map(list, &FpBench.double/1) end,
    "lazy" => fn list -> Lazy.map(list, &FpBench.double/1) end
  },
  "filter" => %{
    "recursive" => fn list -> Recursive.filter(list, &FpBench.even?/1) end,
    "eager" => fn list -> Eager.filter(list, &FpBench.even?/1) end,
    "lazy" => fn list -> Lazy.filter(list, &FpBench.even?/1) end
  },
  "reverse" => %{
    "recursive" => fn list -> Recursive.reverse(list) end,
    "eager" => fn list -> Eager.reverse(list) end,
    "lazy" => fn list -> Lazy.reverse(list) end
  },
  "reduce" => %{
    "recursive" => fn list -> Recursive.reduce(list, 0, &FpBench.sum_squares/2) end,
    "eager" => fn list -> Eager.reduce(list, 0, &FpBench.sum_squares/2) end,
    "lazy" => fn list -> Lazy.reduce(list, 0, &FpBench.sum_squares/2) end
  },
  "pipeline" => %{
    "recursive" => fn list -> Recursive.pipeline(list) end,
    "recursive_fused" => fn list -> Recursive.pipeline_fused(list) end,
    "eager" => fn list -> Eager.pipeline(list) end,
    "lazy" => fn list -> Lazy.pipeline(list) end
  },
  "pipeline_selective" => %{
    "recursive" => fn list -> Recursive.pipeline_selective(list) end,
    "recursive_fused" => fn list -> Recursive.pipeline_selective_fused(list) end,
    "eager" => fn list -> Eager.pipeline_selective(list) end,
    "lazy" => fn list -> Lazy.pipeline_selective(list) end
  }
}

File.mkdir_p!(out_dir)
if html?, do: File.mkdir_p!(Path.join(out_dir, "html"))

environment = """
==> FpBench
    Elixir #{System.version()} / OTP #{System.otp_release()} / #{:erlang.system_info(:system_architecture)}
    os: #{inspect(:os.type())}
    jit: #{inspect(:erlang.system_info(:emu_flavor))}
    schedulers: #{System.schedulers_online()}
    sizes: #{inspect(sizes)}
    operations: #{inspect(ops)}
    time: #{time}s  warmup: #{warmup}s  memory_time: #{memory_time}s  quick: #{quick?}
    html: #{html?}  out: #{out_dir}
    started_at: #{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}
"""

IO.puts(environment)
File.write!(Path.join(out_dir, "environment.txt"), environment)

for op <- ops do
  IO.puts("\n==> Operation: #{op}")

  formatters =
    if html? do
      [
        Benchee.Formatters.Console,
        {Benchee.Formatters.HTML,
         file: Path.join([out_dir, "html", "#{op}.html"]), auto_open: false}
      ]
    else
      [Benchee.Formatters.Console]
    end

  suite =
    Benchee.run(
      Map.fetch!(jobs, op),
      title: "FpBench - #{op}",
      inputs: inputs,
      time: time,
      warmup: warmup,
      memory_time: memory_time,
      pre_check: true,
      formatters: formatters
    )

  write_stats_csv!.(suite, Path.join(out_dir, "#{op}.csv"))
end

IO.puts("\n==> Done. CSV in #{out_dir}/" <> if(html?, do: " (HTML enabled).", else: "."))
