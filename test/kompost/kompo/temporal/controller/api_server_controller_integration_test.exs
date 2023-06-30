defmodule Kompost.Kompo.Temporal.Controller.ApiServerControllerIntegrationTest do
  use ExUnit.Case, async: true

  alias Kompost.Test.GlobalResourceHelper
  alias Kompost.Test.Kompo.Temporal.ResourceHelper

  @namespace "temporal-api-server-controller-integration"

  setup_all do
    timeout =
      "TEST_WAIT_TIMEOUT"
      |> System.get_env("5000")
      |> String.to_integer()

    conn = Kompost.Test.IntegrationHelper.conn!()
    GlobalResourceHelper.create_namespace(@namespace, conn)

    on_exit(fn ->
      {:ok, _} =
        K8s.Client.delete_all("kompost.chuge.li/v1alpha1", "TemporalApiServer",
          namespace: @namespace
        )
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.run()

      Process.sleep(1000)
    end)

    api_server =
      "namespace-integration-test-#{:rand.uniform(10000)}"
      |> ResourceHelper.api_server(@namespace)
      |> GlobalResourceHelper.k8s_apply!(conn)
      |> GlobalResourceHelper.wait_until_observed!(conn, timeout)

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
        |> ResourceHelper.api_server(@namespace)
        |> put_in(~w(spec host), "nonexistent")
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "False" == conditions["Connected"]["status"]
    end

    @tag :integration
    test "Connected condition status is True if connection to temporal was established",
         %{
           conn: conn,
           timeout: timeout,
           resource_name: resource_name
         } do
      created_resource =
        resource_name
        |> ResourceHelper.api_server(@namespace)
        |> GlobalResourceHelper.k8s_apply!(conn)

      created_resource =
        GlobalResourceHelper.wait_until_observed!(created_resource, conn, timeout)

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "True" == conditions["Connected"]["status"]
    end
  end
end
