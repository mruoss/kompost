defmodule Kompost.Kompo.Postgres.Controller.DatabaseControllerE2eTest do
  use ExUnit.Case, async: true

  alias Kompost.Test.GlobalResourceHelper
  alias Kompost.Test.Kompo.Postgres.ResourceHelper

  @namespace "postgres-database-controller-e2e"

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

  describe "Admission Webhooks" do
    @tag :e2e
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

      result =
        created_resource
        |> Bonny.Resource.drop_managed_fields()
        |> Bonny.Resource.drop_rv()
        |> put_in(~w(spec params encoding), "UTF8")
        |> GlobalResourceHelper.k8s_apply(conn)

      assert {:error, %K8s.Client.APIError{message: message}} = result
      assert message =~ "The field .spec.params.encoding is immutable."
    end
  end
end
