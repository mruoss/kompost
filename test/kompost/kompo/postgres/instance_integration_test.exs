defmodule Kompost.Kompo.Postgres.InstanceIntegrationTest do
  use ExUnit.Case, async: true

  alias Kompost.Kompo.Postgres.Instance, as: MUT

  setup_all do
    {:ok, conn} =
      Postgrex.start_link(
        host: System.get_env("POSTGRES_HOST", "127.0.0.1"),
        port: System.fetch_env!("POSTGRES_EXPOSED_PORT"),
        username: System.fetch_env!("POSTGRES_USER"),
        password: System.fetch_env!("POSTGRES_PASSWORD"),
        host: "127.0.0.1",
        database: "postgres"
      )

    Postgrex.query(
      conn,
      ~s/CREATE ROLE nocreaterole WITH PASSWORD 'password' CREATEDB NOCREATEROLE NOINHERIT LOGIN/,
      []
    )

    Postgrex.query(
      conn,
      ~s/CREATE ROLE nocreatedb WITH PASSWORD 'password' NOCREATEDB CREATEROLE NOINHERIT LOGIN/,
      []
    )

    on_exit(fn ->
      Postgrex.query!(conn, ~s/DROP ROLE IF EXISTS nocreatedb/, [])
      Postgrex.query!(conn, ~s/DROP ROLE IF EXISTS nocreaterole/, [])
    end)

    :ok
  end

  @tag :integration
  @tag :postgres
  test "returns :ok when all good" do
    result =
      start_supervised!({
        Postgrex,
        host: System.get_env("POSTGRES_HOST", "127.0.0.1"),
        port: System.fetch_env!("POSTGRES_EXPOSED_PORT"),
        username: System.fetch_env!("POSTGRES_USER"),
        password: System.fetch_env!("POSTGRES_PASSWORD"),
        host: "127.0.0.1",
        database: "postgres"
      })
      |> MUT.check_privileges()

    assert :ok == result
  end

  @tag :integration
  @tag :postgres
  test "returns error when user has no privilege to create databases" do
    result =
      start_supervised!(
        {Postgrex,
         host: System.get_env("POSTGRES_HOST", "127.0.0.1"),
         port: System.fetch_env!("POSTGRES_EXPOSED_PORT"),
         username: "nocreatedb",
         password: "password",
         host: "127.0.0.1",
         database: "postgres"}
      )
      |> MUT.check_privileges()

    assert {:error, "The user does not have the privilege to create databases"} ==
             result
  end

  @tag :integration
  @tag :postgres
  test "returns error when user has no privilege to create roles" do
    result =
      start_supervised!(
        {Postgrex,
         host: System.get_env("POSTGRES_HOST", "127.0.0.1"),
         port: System.fetch_env!("POSTGRES_EXPOSED_PORT"),
         username: "nocreaterole",
         password: "password",
         host: "127.0.0.1",
         database: "postgres"}
      )
      |> MUT.check_privileges()

    assert {:error, reason} = result
    assert reason =~ "The user does not have the privilege to create users"
  end
end
