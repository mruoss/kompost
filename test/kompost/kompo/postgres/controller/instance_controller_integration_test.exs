defmodule Kompost.Kompo.Postgres.Controller.InstanceControllerIntegrationTest do
  use ExUnit.Case, async: true

  import YamlElixir.Sigil

  @resource_label %{"test" => "postgres-instance-controller-integration"}

  @spec resource(name :: binary()) :: map()
  defp resource(name) do
    ~y"""
    apiVersion: kompost.io/v1alpha1
    kind: PostgresInstance
    metadata:
      name: #{name}
      namespace: default
    spec:
      hostname: 127.0.0.1
      port: #{System.fetch_env!("EXPOSED_PORT")}
      username: #{System.fetch_env!("POSTGRES_USER")}
    """
    |> put_in(~w(metadata labels), @resource_label)
  end

  @spec resource_with_secret_ref(name :: binary()) :: map()
  defp resource_with_secret_ref(name) do
    name
    |> resource()
    |> put_in(~w(spec passwordSecretRef), %{
      "name" => name,
      "key" => System.fetch_env!("POSTGRES_PASSWORD")
    })
  end

  @spec resource_with_plain_pw(name :: binary(), password :: binary()) :: map()
  defp resource_with_plain_pw(name, password \\ System.fetch_env!("POSTGRES_PASSWORD")) do
    name
    |> resource()
    |> put_in(~w(spec plainPassword), password)
  end

  @spec password_secret(name :: binary()) :: map()
  defp password_secret(name) do
    ~y"""
    apiVersion: v1
    kind: Secret
    metadata:
      name: #{name}
      namespace: default
    stringData:
      password: password
    """
    |> put_in(~w(metadata labels), @resource_label)
  end

  setup_all do
    timeout =
      "TEST_WAIT_TIMEOUT"
      |> System.get_env("5000")
      |> String.to_integer()

    conn = Kompost.Test.IntegrationHelper.conn!()

    on_exit(fn ->
      selector = K8s.Selector.label(@resource_label)

      {:ok, _} =
        K8s.Client.delete_all("kompost.io/v1alpha1", "PostgresInstance", namespace: "default")
        |> K8s.Operation.put_selector(selector)
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.run()

      {:ok, _} =
        K8s.Client.delete_all("v1", "Secret", namespace: "default")
        |> K8s.Operation.put_selector(selector)
        |> K8s.Client.put_conn(conn)
        |> K8s.Client.run()
    end)

    [conn: conn, timeout: timeout]
  end

  setup do
    [resource_name: "test-#{:rand.uniform(10000)}"]
  end

  describe "credentials" do
    @tag :integration
    test "Credentials condition status is False if the password secret does not exist", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      assert {:ok, created_resource} =
               resource_with_secret_ref(resource_name)
               |> K8s.Client.apply()
               |> K8s.Client.put_conn(conn)
               |> K8s.Client.run()

      get_op =
        K8s.Client.get("kompost.io/v1alpha1", "PostgresInstance",
          name: resource_name,
          namespace: "default"
        )
        |> K8s.Client.put_conn(conn)

      {:ok, created_resource} =
        K8s.Client.wait_until(get_op,
          find: ["status", "observedGeneration"],
          eval: created_resource["metadata"]["generation"],
          timeout: Integer.floor_div(timeout, 1000)
        )

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "False" == conditions["Credentials"]["status"]
    end

    @tag :integration
    test "Credentials condition status is True if password secret exists", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      assert {:ok, _} =
               password_secret(resource_name)
               |> K8s.Client.apply()
               |> K8s.Client.put_conn(conn)
               |> K8s.Client.run()

      assert {:ok, created_resource} =
               resource_with_secret_ref(resource_name)
               |> K8s.Client.apply()
               |> K8s.Client.put_conn(conn)
               |> K8s.Client.run()

      get_op =
        K8s.Client.get("kompost.io/v1alpha1", "PostgresInstance",
          name: resource_name,
          namespace: "default"
        )
        |> K8s.Client.put_conn(conn)

      {:ok, created_resource} =
        K8s.Client.wait_until(get_op,
          find: ["status", "observedGeneration"],
          eval: created_resource["metadata"]["generation"],
          timeout: Integer.floor_div(timeout, 1000)
        )

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "True" == conditions["Credentials"]["status"]
    end

    @tag :integration
    test "Credentials condition status is True if the plain password in resource", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      assert {:ok, created_resource} =
               resource_with_plain_pw(resource_name)
               |> K8s.Client.apply()
               |> K8s.Client.put_conn(conn)
               |> K8s.Client.run()

      get_op =
        K8s.Client.get("kompost.io/v1alpha1", "PostgresInstance",
          name: resource_name,
          namespace: "default"
        )
        |> K8s.Client.put_conn(conn)

      {:ok, created_resource} =
        K8s.Client.wait_until(get_op,
          find: ["status", "observedGeneration"],
          eval: created_resource["metadata"]["generation"],
          timeout: Integer.floor_div(timeout, 1000)
        )

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "True" == conditions["Credentials"]["status"]
    end
  end

  describe "connection arguments" do
    @tag :integration
    test "Connected condition status is true if arguments are correct", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      assert {:ok, _} =
               password_secret(resource_name)
               |> K8s.Client.apply()
               |> K8s.Client.put_conn(conn)
               |> K8s.Client.run()

      assert {:ok, created_resource} =
               resource_with_secret_ref(resource_name)
               |> K8s.Client.apply()
               |> K8s.Client.put_conn(conn)
               |> K8s.Client.run()

      get_op =
        K8s.Client.get("kompost.io/v1alpha1", "PostgresInstance",
          name: resource_name,
          namespace: "default"
        )
        |> K8s.Client.put_conn(conn)

      {:ok, created_resource} =
        K8s.Client.wait_until(get_op,
          find: ["status", "observedGeneration"],
          eval: created_resource["metadata"]["generation"],
          timeout: Integer.floor_div(timeout, 1000)
        )

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "True" == conditions["Connected"]["status"]
    end

    @tag :integration
    test "Connected condition status is false if arguments are incorrect", %{
      conn: conn,
      timeout: timeout,
      resource_name: resource_name
    } do
      assert {:ok, created_resource} =
               resource_with_plain_pw(resource_name, "wrong_password")
               |> K8s.Client.apply()
               |> K8s.Client.put_conn(conn)
               |> K8s.Client.run()

      get_op =
        K8s.Client.get("kompost.io/v1alpha1", "PostgresInstance",
          name: resource_name,
          namespace: "default"
        )
        |> K8s.Client.put_conn(conn)

      {:ok, created_resource} =
        K8s.Client.wait_until(get_op,
          find: ["status", "observedGeneration"],
          eval: created_resource["metadata"]["generation"],
          timeout: Integer.floor_div(timeout, 1000)
        )

      conditions = Map.new(created_resource["status"]["conditions"], &{&1["type"], &1})
      assert "False" == conditions["Connected"]["status"]
    end
  end
end
