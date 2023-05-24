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
      |> GlobalResourceHelper.k8s_apply(conn)
      |> GlobalResourceHelper.wait_until_observed(conn, timeout)

    [conn: conn, instance: instance, timeout: timeout]
  end

  setup do
    resource_name = "test-#{:rand.uniform(10000)}"

    [resource_name: resource_name]
  end

  describe "credentials" do
    @tag :integration
    test "Conditions are True if all is well", %{
      conn: conn,
      resource_name: resource_name,
      instance: instance,
      timeout: timeout
    } do
      created_resource =
        resource_name
        |> ResourceHelper.database(@namespace, instance)
        |> GlobalResourceHelper.k8s_apply(conn)

      created_resource = GlobalResourceHelper.wait_until_observed(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert %{"status" => "True"} = conditions["Connection"]
      assert %{"status" => "True"} = conditions["Database"]
      assert %{"status" => "True"} = conditions["AppUser"]
      assert %{"status" => "True"} = conditions["InspectorUser"]
    end

    @tag :integration
    test "Connection condition is False if connection is not found", %{
      conn: conn,
      resource_name: resource_name,
      timeout: timeout
    } do
      created_resource =
        resource_name
        |> ResourceHelper.database(
          @namespace,
          %{"metadata" => %{"namespace" => @namespace, "name" => "does-not-exist"}}
        )
        |> GlobalResourceHelper.k8s_apply(conn)

      created_resource = GlobalResourceHelper.wait_until_observed(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert %{"status" => "False"} = conditions["Connection"]
    end
  end

  describe "descendants are created and data can be used to connect to DB" do
    @tag :integration
    test "Secrets are created", %{
      conn: conn,
      resource_name: resource_name,
      instance: instance,
      timeout: timeout
    } do
      created_resource =
        resource_name
        |> ResourceHelper.database(
          @namespace,
          instance
        )
        |> GlobalResourceHelper.k8s_apply(conn)

      created_resource = GlobalResourceHelper.wait_until_observed(created_resource, conn, timeout)

      assert [_ | _] = created_resource["status"]["users"]

      for user_secret <- created_resource["status"]["users"] do
        {:ok, %{"data" => data}} =
          K8s.Client.get("v1", "Secret", name: user_secret["secret"], namespace: @namespace)
          |> K8s.Client.put_conn(conn)
          |> K8s.Client.run()

        %{
          "DB_HOST" => hostname,
          "DB_NAME" => database,
          "DB_PASS" => password,
          "DB_PORT" => port,
          "DB_USER" => username
        } = Map.new(data, fn {key, value} -> {key, Base.decode64!(value)} end)

        conn_args = [
          hostname: hostname,
          port: port,
          username: username,
          password: password,
          database: database
        ]

        conn = start_link_supervised!({Postgrex, conn_args}, id: username)
        assert {:ok, _} = Postgrex.query(conn, "SELECT * FROM pg_catalog.pg_tables", [])
      end
    end
  end
end
