defmodule Kompost.Test.Kompo.Postgres.PostgrexHelper do
  @moduledoc """
  Test Helper for Postgrex connections.
  """

  @spec child_spec(Keyword.t()) :: {Postgrex, Keyword.t()}
  def child_spec(overrides \\ []) do
    {
      Postgrex,
      conn_args(overrides)
    }
  end

  @spec conn_args(Keyword.t()) :: Keyword.t()
  def conn_args(overrides \\ []) do
    Keyword.merge(
      [
        host: System.get_env("POSTGRES_HOST", "127.0.0.1"),
        port: System.fetch_env!("POSTGRES_EXPOSED_PORT"),
        username: System.fetch_env!("POSTGRES_USER"),
        password: System.fetch_env!("POSTGRES_PASSWORD"),
        host: "127.0.0.1",
        database: "postgres"
      ],
      overrides
    )
  end
end
