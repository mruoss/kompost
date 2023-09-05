defmodule Kompost.MixProject do
  use Mix.Project

  def project do
    [
      app: :kompost,
      version: "0.3.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: cli_env(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"],
      releases: releases()
    ]
  end

  defp cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.travis": :test,
      "coveralls.github": :test,
      "coveralls.xml": :test,
      "coveralls.json": :test
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Kompost.Application, [env: Mix.env()]},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support" | elixirc_paths(:prod)]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 0.7.6"},
      # {:bonny, path: "/Users/mruoss/src/community/bonny"},
      # {:bonny, github: "coryodaniel/bonny", branch: "master"},
      {:bonny, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:k8s_webhoox, "~> 0.2.0"},
      {:plug, "~> 1.0"},
      {:postgrex, "~> 0.17.0"},
      {:slugger, "~> 0.3.0"},

      # Temporal.io
      {:temporalio, "~> 1.0"},
      {:google_protos, "~> 0.3.0"},

      # Dev dependencies
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:dotenv_parser, "~> 2.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.17.0", only: :test}
    ]
  end

  defp releases do
    [
      kompost: [
        include_erts: false,
        include_executables_for: [:unix]
      ]
    ]
  end
end
