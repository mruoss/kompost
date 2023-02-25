defmodule Kompost.MixProject do
  use Mix.Project

  def project do
    [
      app: :kompost,
      version: "0.1.2",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: cli_env(),
      test_coverage: [tool: ExCoveralls],
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
      {:bonny, "~> 1.1"},
      # {:bonny, path: "/Users/mruoss/src/community/bonny"},
      # {:bonny, github: "coryodaniel/bonny", branch: "master"},
      {:jason, "~> 1.0"},
      {:postgrex, "~> 0.16.0"},
      {:slugger, "~> 0.3.0"},

      # Dev dependencies
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:dotenv_parser, "~> 2.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.15.3", only: :test}
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
