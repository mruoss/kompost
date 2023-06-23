defmodule Kompost.Kompo.Temporal.Controller.NamespaceControllerIntegrationTest do
  use ExUnit.Case, async: true

  alias Kompost.Test.GlobalResourceHelper
  alias Kompost.Test.Kompo.Temporal.ResourceHelper

  @namespace "temporal-namespace-controller-integration"

  setup_all do
    timeout =
      "TEST_WAIT_TIMEOUT"
      |> System.get_env("5000")
      |> String.to_integer()

    conn = Kompost.Test.IntegrationHelper.conn!()
    GlobalResourceHelper.create_namespace(@namespace, conn)

    on_exit(fn ->
      {:ok, _} =
        K8s.Client.delete_all("kompost.chuge.li/v1alpha1", "TemporalNamespace",
          namespace: @namespace
        )
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.run()

      Process.sleep(500)

      {:ok, _} =
        K8s.Client.delete_all("kompost.chuge.li/v1alpha1", "TemporalApiServer",
          namespace: @namespace
        )
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.run()

      Process.sleep(500)
    end)

    api_server =
      "namespace-integration-test-#{:rand.uniform(10000)}"
      |> ResourceHelper.api_server(@namespace)
      |> GlobalResourceHelper.k8s_apply(conn)
      |> GlobalResourceHelper.wait_until_observed(conn, timeout)

    GlobalResourceHelper.wait_for_condition(api_server, conn, "Connected", timeout)

    [conn: conn, timeout: timeout, api_server: api_server]
  end

  setup do
    [resource_name: "test-#{:rand.uniform(10000)}"]
  end

  describe "Connected" do
    @tag :integration
    test "Connected condition status is False if connection to temporal could not be established",
         %{
           conn: conn,
           timeout: timeout,
           resource_name: resource_name
         } do
      created_resource =
        resource_name
        |> ResourceHelper.namespace(
          @namespace,
          %{"metadata" => %{"namespace" => @namespace, "name" => "inexistent"}},
          %{
            "description" => "Test Namespace",
            "workflowExecutionRetentionPeriod" => 7000
          }
        )
        |> GlobalResourceHelper.k8s_apply(conn)

      created_resource = GlobalResourceHelper.wait_until_observed(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "False" == conditions["Connected"]["status"]
    end

    @tag :integration
    test "Connected condition status is True if connection to temporal was established",
         %{
           conn: conn,
           timeout: timeout,
           resource_name: resource_name,
           api_server: api_server
         } do
      created_resource =
        resource_name
        |> ResourceHelper.namespace(
          @namespace,
          api_server,
          %{
            "description" => "Test Namespace",
            "workflowExecutionRetentionPeriod" => 7000
          }
        )
        |> GlobalResourceHelper.k8s_apply(conn)

      GlobalResourceHelper.wait_for_condition(created_resource, conn, "Connected", timeout)
    end
  end

  describe "Created" do
    # Currently don't know how to provoke this
    # @tag :integration
    # test "Created condition status is False if Namespace could not be created",
    #      %{
    #        conn: conn,
    #        timeout: timeout,
    #        resource_name: resource_name,
    #        api_server: api_server
    #      } do
    #   created_resource =
    #     resource_name
    #     |> ResourceHelper.namespace(
    #       @namespace,
    #       api_server,
    #       %{
    #         "description" => "Test Namespace",
    #         "workflowExecutionRetentionPeriod" => -7000
    #       }
    #     )
    #     |> GlobalResourceHelper.k8s_apply(conn)

    #   created_resource = GlobalResourceHelper.wait_until_observed(created_resource, conn, timeout)

    #   conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
    #   assert "True" == conditions["Connected"]["status"]
    #   assert "False" == conditions["Created"]["status"]
    # end

    @tag :integration
    test "Created condition status is True if Namespace was created",
         %{
           conn: conn,
           timeout: timeout,
           resource_name: resource_name,
           api_server: api_server
         } do
      created_resource =
        resource_name
        |> ResourceHelper.namespace(
          @namespace,
          api_server,
          %{
            "description" => "Test Namespace",
            "workflowExecutionRetentionPeriod" => 24 * 60 * 60
          }
        )
        |> GlobalResourceHelper.k8s_apply(conn)

      GlobalResourceHelper.wait_for_condition(created_resource, conn, "Connected", timeout)
      GlobalResourceHelper.wait_for_condition(created_resource, conn, "Created", timeout)
    end
  end
end
