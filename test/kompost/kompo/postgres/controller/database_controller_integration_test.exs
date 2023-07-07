defmodule Kompost.Kompo.Postgres.Controller.DatabaseControllerIntegrationTest do
  use ExUnit.Case, async: true

  alias Kompost.Test.GlobalResourceHelper
  alias Kompost.Test.Kompo.Postgres.ResourceHelper

  @namespace "postgres-database-controller-integration"

  setup_all do
    timeout =
      "TEST_WAIT_TIMEOUT"
      |> System.get_env("5000")
      |> String.to_integer()

    conn = Kompost.Test.IntegrationHelper.conn!()
    GlobalResourceHelper.create_namespace(@namespace, conn)

    on_exit(fn ->
      {:ok, _} =
        K8s.Client.delete_all("kompost.chuge.li/v1alpha1", "PostgresDatabase",
          namespace: @namespace
        )
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.run()

      Process.sleep(500)

      {:ok, _} =
        K8s.Client.delete_all("kompost.chuge.li/v1alpha1", "PostgresInstance",
          namespace: @namespace
        )
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.run()

      Process.sleep(500)
    end)

    instance =
      "database-integration-test-#{:rand.uniform(10000)}"
      |> ResourceHelper.instance_with_plain_pw(@namespace)
      |> GlobalResourceHelper.k8s_apply!(conn)
      |> GlobalResourceHelper.wait_until_observed!(conn, timeout)

    [conn: conn, instance: instance, timeout: timeout]
  end

  setup do
    resource_name = "test-#{:rand.uniform(10000)}"

    [resource_name: resource_name]
  end

  describe "credentials" do
    @tag :integration
    @tag :postgres
    test "Conditions are True if all is well", %{
      conn: conn,
      resource_name: resource_name,
      instance: instance,
      timeout: timeout
    } do
      created_resource =
        resource_name
        |> ResourceHelper.database(@namespace, {:namespaced, instance})
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert %{"status" => "True"} = conditions["Connection"]
      assert %{"status" => "True"} = conditions["Database"]
      assert %{"status" => "True"} = conditions["AppUser"]
      assert %{"status" => "True"} = conditions["InspectorUser"]
    end

    @tag :integration
    @tag :postgres
    test "Connection condition is False if connection is not found", %{
      conn: conn,
      resource_name: resource_name,
      timeout: timeout
    } do
      created_resource =
        resource_name
        |> ResourceHelper.database(
          @namespace,
          {:namespaced, %{"metadata" => %{"namespace" => @namespace, "name" => "does-not-exist"}}}
        )
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert %{"status" => "False"} = conditions["Connection"]
    end
  end

  describe "descendants and database" do
    @tag :integration
    @tag :postgres
    test "Secrets are created and can be used to connect to DB", %{
      conn: conn,
      resource_name: resource_name,
      instance: instance,
      timeout: timeout
    } do
      created_resource =
        resource_name
        |> ResourceHelper.database(
          @namespace,
          {:namespaced, instance}
        )
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      assert [_ | _] = created_resource["status"]["users"]

      for user_secret <- created_resource["status"]["users"] do
        {:ok, %{"data" => data}} =
          K8s.Client.get("v1", "Secret", name: user_secret["secret"], namespace: @namespace)
          |> K8s.Client.put_conn(conn)
          |> K8s.Client.run()

        %{
          "DB_NAME" => database,
          "DB_PASS" => password,
          "DB_PORT" => port,
          "DB_USER" => username,
          "DB_SSL" => "false",
          "DB_SSL_VERIFY" => "false"
        } = Map.new(data, fn {key, value} -> {key, Base.decode64!(value)} end)

        conn_args = [
          hostname: "127.0.0.1",
          port: port,
          username: username,
          password: password,
          database: database
        ]

        conn = start_link_supervised!({Postgrex, conn_args}, id: username)
        assert {:ok, _} = Postgrex.query(conn, "SELECT * FROM pg_catalog.pg_tables", [])
      end
    end

    @tag :integration
    @tag :postgres
    test "Parameters are applied upon DB creation", %{
      conn: conn,
      resource_name: resource_name,
      instance: instance,
      timeout: timeout
    } do
      created_resource =
        resource_name
        |> ResourceHelper.database(
          @namespace,
          {:namespaced, instance},
          %{
            template: "template0",
            encoding: "SQL_ASCII",
            locale: "C",
            lc_collate: "C",
            lc_ctype: "C",
            connection_limit: 50,
            is_template: true
          }
        )
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      GlobalResourceHelper.wait_for_condition!(created_resource, conn, "Connection", timeout)
      GlobalResourceHelper.wait_for_condition!(created_resource, conn, "Database", timeout)

      conn_args = [
        hostname: "127.0.0.1",
        port: System.fetch_env!("POSTGRES_EXPOSED_PORT"),
        username: System.fetch_env!("POSTGRES_USER"),
        password: System.fetch_env!("POSTGRES_PASSWORD"),
        database: "postgres"
      ]

      conn = start_link_supervised!({Postgrex, conn_args}, id: "root")

      assert {:ok, _, %{rows: [[0, "C", "C", 50, true]]}} =
               Postgrex.prepare_execute(
                 conn,
                 "",
                 """
                 SELECT
                    encoding,
                    datcollate,
                    datctype,
                    datconnlimit,
                    datistemplate
                 FROM pg_database
                 WHERE datname=$1
                 """,
                 [created_resource["status"]["sql_db_name"]]
               )
    end

    @tag :integration
    @tag :postgres
    test "Database and users are created and removed on the server", %{
      conn: conn,
      resource_name: resource_name,
      instance: instance,
      timeout: timeout
    } do
      created_resource =
        resource_name
        |> ResourceHelper.database(
          @namespace,
          {:namespaced, instance}
        )
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conn_args = [
        hostname: "127.0.0.1",
        port: System.fetch_env!("POSTGRES_EXPOSED_PORT"),
        username: System.fetch_env!("POSTGRES_USER"),
        password: System.fetch_env!("POSTGRES_PASSWORD"),
        database: "postgres"
      ]

      db_conn = start_link_supervised!({Postgrex, conn_args}, id: "root")

      result =
        Postgrex.query!(
          db_conn,
          ~s/SELECT datname FROM pg_catalog.pg_database WHERE datname = $1;/,
          [created_resource["status"]["sql_db_name"]]
        )

      assert 1 == result.num_rows

      created_resource["status"]["users"]
      |> Enum.each(fn user ->
        result =
          Postgrex.query!(
            db_conn,
            ~s/SELECT 1 FROM pg_roles WHERE rolname=$1;/,
            [user["username"]]
          )

        assert 1 == result.num_rows
      end)

      ### Removing Database ###

      {:ok, _} =
        K8s.Client.delete(created_resource)
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.wait_until(timeout: timeout)

      created_resource["status"]["users"]
      |> Enum.each(fn user ->
        result =
          Postgrex.query!(
            db_conn,
            ~s/SELECT 1 FROM pg_roles WHERE rolname=$1;/,
            [user["username"]]
          )

        assert 0 == result.num_rows
      end)

      result =
        Postgrex.query!(
          db_conn,
          ~s/SELECT datname FROM pg_catalog.pg_database WHERE datname = $1;/,
          [created_resource["status"]["sql_db_name"]]
        )

      assert 0 == result.num_rows
    end
  end
end
