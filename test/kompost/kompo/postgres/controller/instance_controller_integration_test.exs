defmodule Kompost.Kompo.Postgres.Controller.ClusterInstanceControllerIntegrationTest do
  use ExUnit.Case, async: true

  import YamlElixir.Sigil

  alias Kompost.Test.GlobalResourceHelper
  alias Kompost.Test.Kompo.Postgres.ResourceHelper

  @namespace "postgres-instance-controller-integration"

  @spec password_secret(name :: binary()) :: map()
  defp password_secret(name) do
    ~y"""
    apiVersion: v1
    kind: Secret
    metadata:
      name: #{name}
      namespace: #{@namespace}
    stringData:
      password: password
    """
  end

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

    [conn: conn, timeout: timeout]
  end

  setup do
    [resource_name: "test-#{:rand.uniform(10000)}"]
  end

  describe "credentials" do
    @tag :integration
    @tag :postgres
    test "Credentials condition status is False if the password secret does not exist", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      created_resource =
        resource_name
        |> ResourceHelper.instance_with_secret_ref(@namespace)
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "False" == conditions["Credentials"]["status"]
    end

    @tag :integration
    @tag :postgres
    test "Credentials condition status is True if password secret exists", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      GlobalResourceHelper.k8s_apply!(password_secret(resource_name), conn)

      created_resource =
        resource_name
        |> ResourceHelper.instance_with_secret_ref(@namespace)
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "True" == conditions["Credentials"]["status"]
    end

    @tag :integration
    @tag :postgres
    test "Credentials condition status is True if the plain password in resource", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      created_resource =
        resource_name
        |> ResourceHelper.instance_with_plain_pw(@namespace)
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "True" == conditions["Credentials"]["status"]
    end
  end

  describe "connection arguments" do
    @tag :integration
    @tag :postgres
    test "Connected condition status is true if arguments are correct", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      GlobalResourceHelper.k8s_apply!(password_secret(resource_name), conn)

      created_resource =
        resource_name
        |> ResourceHelper.instance_with_secret_ref(@namespace)
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "True" == conditions["Connected"]["status"]
    end

    @tag :integration
    @tag :postgres
    test "Connected condition status is false if arguments are incorrect", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      created_resource =
        resource_name
        |> ResourceHelper.instance_with_plain_pw(@namespace, "wrong_password")
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "False" == conditions["Connected"]["status"]
    end
  end

  describe "privileges" do
    @tag :integration
    @tag :postgres
    test "Privileged condition status is true if user is superuser", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      GlobalResourceHelper.k8s_apply!(password_secret(resource_name), conn)

      created_resource =
        resource_name
        |> ResourceHelper.instance_with_secret_ref(@namespace)
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "True" == conditions["Privileged"]["status"]
    end
  end
end
