defmodule Operator.MixProject do
  use Mix.Project

  @app :operator

  def project do
    [
      app: @app,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Operator.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spawn, path: "../../apps/spawn"},
      {:metrics_endpoint, path: "../../apps/metrics_endpoint"},
      {:bandit, "~> 0.5"},
      {:bonny, "~> 0.5"},
      {:bakeware, ">= 0.0.0", runtime: false}
    ]
  end

  defp releases do
    [
      operator: [
        include_executables_for: [:unix],
        applications: [operator: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
