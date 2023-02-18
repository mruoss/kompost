defmodule Kompost.MixProject do
  use Mix.Project

  def project do
    [
      app: :kompost,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:bonny, github: "coryodaniel/bonny", branch: "master"},
      {:jason, "~> 1.0"},
      {:postgrex, "~> 0.16.0"},

      # Dev dependencies
      {:dotenv_parser, "~> 2.0", only: [:dev, :test], runtime: false}
    ]
  end
end
