defmodule Kompost.Kompo.Postgres.DatabaseIntegrationTest do
  use ExUnit.Case, async: true

  alias Kompost.Kompo.Postgres.Database, as: MUT

  alias Kompost.Test.Kompo.Postgres.PostgrexHelper

  setup_all do
    :ok
  end

  describe "apply_extensions/2 and drop_extensions/2" do
    setup do
      conn =
        start_supervised!(PostgrexHelper.child_spec(), id: :postgres)

      db_name = "database_integration_test_#{:rand.uniform(10000)}"
      Postgrex.query!(conn, "CREATE DATABASE #{db_name}", [])

      db_conn =
        start_supervised!(PostgrexHelper.child_spec(database: db_name), id: :db)

      on_exit(fn ->
        {:ok, conn} =
          Postgrex.start_link(PostgrexHelper.conn_args())

        Postgrex.query!(conn, "DROP DATABASE IF EXISTS #{db_name}", [])
      end)

      [conn: conn, db_conn: db_conn, db_name: db_name]
    end

    @tag :integration
    @tag :postgres
    test "apply creates extensions if they don't exist", %{db_conn: db_conn} do
      result = Postgrex.query!(db_conn, "SELECT extname FROM pg_extension", [])
      extensions = result.rows |> List.flatten()
      assert "pgcrypto" not in extensions
      assert "uuid-ossp" not in extensions

      assert :ok == MUT.apply_extensions(db_conn, ["pgcrypto", "uuid-ossp"])

      result = Postgrex.query!(db_conn, "SELECT extname FROM pg_extension", [])
      extensions = result.rows |> List.flatten()
      assert "pgcrypto" in extensions
      assert "uuid-ossp" in extensions
    end

    @tag :integration
    @tag :postgres
    test "apply removes extensions from DB if they don't exist", %{db_conn: db_conn} do
      Postgrex.query!(db_conn, ~s(CREATE EXTENSION IF NOT EXISTS "pgcrypto"), [])
      Postgrex.query!(db_conn, ~s(CREATE EXTENSION IF NOT EXISTS "uuid-ossp"), [])
      result = Postgrex.query!(db_conn, "SELECT extname FROM pg_extension", [])

      extensions = result.rows |> List.flatten()
      assert "pgcrypto" in extensions
      assert "uuid-ossp" in extensions

      assert :ok == MUT.drop_extensions(db_conn, ["pgcrypto", "uuid-ossp"])

      result = Postgrex.query!(db_conn, "SELECT extname FROM pg_extension", [])
      extensions = result.rows |> List.flatten()
      assert "pgcrypto" not in extensions
      assert "uuid-ossp" not in extensions
    end
  end
end
