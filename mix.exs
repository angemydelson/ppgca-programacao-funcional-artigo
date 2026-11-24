defmodule FpBench.MixProject do
  use Mix.Project

  def project do
    [
      app: :fp_bench,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "FpBench",
      description: "Comparação empírica: recursão, Enum e Stream em Elixir (FpBench)."
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:benchee, "~> 1.3", only: [:dev, :test]},
      {:benchee_html, "~> 1.0", only: [:dev, :test]},
      {:benchee_csv, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      bench: ["run bench/run.exs"],
      "bench.quick": [fn _ -> System.put_env("BENCH_QUICK", "1") end, "run bench/run.exs"]
    ]
  end
end
