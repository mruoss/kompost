defmodule Kompost.Test.Kompo.Postgres.ResourceHelper do
  @moduledoc false

  import YamlElixir.Sigil

  @spec instance(name :: binary(), opts :: Keyword.t()) :: map()
  def instance(name, opts) do
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
    |> apply_opts(opts)
  end

  @spec instance_with_secret_ref(name :: binary(), opts :: Keyword.t()) :: map()
  def instance_with_secret_ref(name, opts) do
    name
    |> instance(opts)
    |> put_in(~w(spec passwordSecretRef), %{
      "name" => name,
      "key" => System.fetch_env!("POSTGRES_PASSWORD")
    })
  end

  @spec instance_with_plain_pw(name :: binary(), password :: binary(), opts :: Keyword.t()) ::
          map()
  def instance_with_plain_pw(name, password \\ System.fetch_env!("POSTGRES_PASSWORD"), opts) do
    name
    |> instance(opts)
    |> put_in(~w(spec plainPassword), password)
  end

  @spec database(name :: binary(), instance :: map(), opts :: Keyword.t()) :: map()
  def database(name, instance, opts) do
    ~y"""
    apiVersion: kompost.io/v1alpha1
    kind: PostgresDatabase
    metadata:
      name: #{name}
      namespace: default
    spec:
      instanceRef:
        name: #{instance["metadata"]["name"]}
        namespace: #{instance["metadata"]["namespace"]}
    """
    |> apply_opts(opts)
  end

  @spec apply_opts(resource :: map(), opts :: Keyword.t()) :: map()
  defp apply_opts(resource, opts) do
    labels = Keyword.get(opts, :labels, %{})
    annotations = Keyword.get(opts, :annotations, %{})

    resource
    |> put_in(~w(metadata labels), labels)
    |> put_in(~w(metadata annotations), annotations)
  end

  @spec apply(map, K8s.Conn.t()) :: map()
  def apply(resource, conn) do
    {:ok, applied_resource} =
      resource
      |> K8s.Client.apply()
      |> K8s.Client.put_conn(conn)
      |> K8s.Client.run()

    applied_resource
  end

  @spec delete(map, K8s.Conn.t()) :: {:ok, map()}
  def delete(resource, conn) do
    {:ok, _} =
      resource
      |> K8s.Client.delete()
      |> K8s.Client.put_conn(conn)
      |> K8s.Client.run()
  end

  @spec wait_until_observed(map, K8s.Conn.t(), non_neg_integer()) :: map
  def wait_until_observed(resource, conn, timeout) do
    get_op =
      resource
      |> K8s.Client.get()
      |> K8s.Client.put_conn(conn)

    {:ok, resource} =
      K8s.Client.wait_until(get_op,
        find: ["status", "observedGeneration"],
        eval: resource["metadata"]["generation"],
        timeout: timeout
      )

    resource
  end
end
