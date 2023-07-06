defmodule Kompost.Kompo.Postgres.Controller.InstanceControllerIntegrationTest do
  use ExUnit.Case, async: true

  alias Kompost.Test.GlobalResourceHelper
  alias Kompost.Test.Kompo.Postgres.ResourceHelper

  @namespace "pgcinst-controller-integration"

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
        K8s.Client.delete_all("kompost.chuge.li/v1alpha1", "PostgresClusterInstance")
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.run()

      Process.sleep(500)
    end)

    [conn: conn, timeout: timeout]
  end

  setup do
    [resource_name: "test-#{:rand.uniform(10000)}"]
  end

  describe "Secret Reference" do
    @tag :integration
    @tag :postgres
    test "Reads Secret from operator namespace", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      GlobalResourceHelper.k8s_apply!(
        ResourceHelper.password_secret(resource_name, "kompost"),
        conn
      )

      created_instance =
        resource_name
        |> ResourceHelper.cluster_instance_with_secret_ref()
        |> GlobalResourceHelper.k8s_apply!(conn)

      GlobalResourceHelper.wait_for_condition!(created_instance, conn, "Privileged", timeout)
    end
  end

  describe "Allowed Namespace Annotations" do
    @tag :integration
    @tag :postgres
    test "Can be accessed by any namespace if no annotation set", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      created_instance =
        resource_name
        |> ResourceHelper.cluster_instance_with_plain_pw()
        |> GlobalResourceHelper.k8s_apply!(conn)

      GlobalResourceHelper.wait_for_condition!(created_instance, conn, "Privileged", timeout)

      created_db =
        resource_name
        |> ResourceHelper.database(@namespace, {:cluster, created_instance})
        |> GlobalResourceHelper.k8s_apply!(conn)

      GlobalResourceHelper.wait_for_condition!(created_db, conn, "InspectorUser", timeout)
      GlobalResourceHelper.wait_for_condition!(created_db, conn, "AppUser", timeout)
    end

    @tag :integration
    @tag :postgres
    test "Can be accessed if namespace is allowed literally", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      created_instance =
        resource_name
        |> ResourceHelper.cluster_instance_with_plain_pw(
          System.fetch_env!("POSTGRES_PASSWORD"),
          annotations: %{"kompost.chuge.li/allowed-namespaces" => "#{@namespace}, other"}
        )
        |> GlobalResourceHelper.k8s_apply!(conn)

      GlobalResourceHelper.wait_for_condition!(created_instance, conn, "Privileged", timeout)

      created_db =
        resource_name
        |> ResourceHelper.database(@namespace, {:cluster, created_instance})
        |> GlobalResourceHelper.k8s_apply!(conn)

      GlobalResourceHelper.wait_for_condition!(created_db, conn, "InspectorUser", timeout)
      GlobalResourceHelper.wait_for_condition!(created_db, conn, "AppUser", timeout)
    end

    @tag :integration
    @tag :postgres
    test "Can be accessed if namespace is allowed via regex", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      created_instance =
        resource_name
        |> ResourceHelper.cluster_instance_with_plain_pw(
          System.fetch_env!("POSTGRES_PASSWORD"),
          annotations: %{"kompost.chuge.li/allowed-namespaces" => "pgcinst-[a-z\-]+, other"}
        )
        |> GlobalResourceHelper.k8s_apply!(conn)

      GlobalResourceHelper.wait_for_condition!(created_instance, conn, "Privileged", timeout)

      created_db =
        resource_name
        |> ResourceHelper.database(@namespace, {:cluster, created_instance})
        |> GlobalResourceHelper.k8s_apply!(conn)

      GlobalResourceHelper.wait_for_condition!(created_db, conn, "InspectorUser", timeout)
      GlobalResourceHelper.wait_for_condition!(created_db, conn, "AppUser", timeout)
    end

    @tag :integration
    @tag :postgres
    test "Cannot be accessed if namespace is not allowed", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      created_instance =
        resource_name
        |> ResourceHelper.cluster_instance_with_plain_pw(
          System.fetch_env!("POSTGRES_PASSWORD"),
          annotations: %{
            "kompost.chuge.li/allowed-namespaces" =>
              "pgcinst-controller, pgcinst-controller-integration-2"
          }
        )
        |> GlobalResourceHelper.k8s_apply!(conn)

      GlobalResourceHelper.wait_for_condition!(created_instance, conn, "Privileged", timeout)

      created_db =
        resource_name
        |> ResourceHelper.database(@namespace, {:cluster, created_instance})
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_db = GlobalResourceHelper.wait_until_observed!(created_db, conn, timeout)

      conditions = Map.new(created_db["status"]["conditions"], &{&1["type"], &1})
      assert "False" == conditions["ClusterInstanceAccess"]["status"]

      assert conditions["ClusterInstanceAccess"]["message"] =~
               "The referenced PostgresClusterInstance cannot be accesed."
    end
  end
end
