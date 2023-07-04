defmodule Kompost.Test.Kompo.Postgres.ResourceHelper do
  @moduledoc false

  import Kompost.Test.GlobalResourceHelper
  import YamlElixir.Sigil

  @spec cluster_instance(name :: binary(), opts :: Keyword.t()) :: map()
  defp cluster_instance(name, opts) do
    ~y"""
    apiVersion: kompost.chuge.li/v1alpha1
    kind: PostgresClusterInstance
    metadata:
      name: #{name}
    spec:
      hostname: #{System.get_env("POSTGRES_HOST", "127.0.0.1")}
      port: #{System.fetch_env!("POSTGRES_EXPOSED_PORT")}
      username: #{System.fetch_env!("POSTGRES_USER")}
    """
    |> apply_opts(opts)
  end

  @spec cluster_instance_with_secret_ref(name :: binary(), opts :: Keyword.t()) :: map()
  def cluster_instance_with_secret_ref(name, opts \\ []) do
    name
    |> cluster_instance(opts)
    |> put_in(~w(spec passwordSecretRef), %{
      "name" => name,
      "key" => "password"
    })
  end

  @spec cluster_instance_with_plain_pw(
          name :: binary(),
          password :: binary(),
          opts :: Keyword.t()
        ) ::
          map()
  def cluster_instance_with_plain_pw(
        name,
        password \\ System.fetch_env!("POSTGRES_PASSWORD"),
        opts \\ []
      ) do
    name
    |> cluster_instance(opts)
    |> put_in(~w(spec plainPassword), password)
  end

  @spec instance(name :: binary(), namespace :: binary(), opts :: Keyword.t()) :: map()
  def instance(name, namespace, opts \\ []) do
    ~y"""
    apiVersion: kompost.chuge.li/v1alpha1
    kind: PostgresInstance
    metadata:
      name: #{name}
      namespace: #{namespace}
    spec:
      hostname: #{System.get_env("POSTGRES_HOST", "127.0.0.1")}
      port: #{System.fetch_env!("POSTGRES_EXPOSED_PORT")}
      username: #{System.fetch_env!("POSTGRES_USER")}
    """
    |> apply_opts(opts)
  end

  @spec instance_with_secret_ref(name :: binary(), namespace :: binary(), opts :: Keyword.t()) ::
          map()
  def instance_with_secret_ref(name, namespace, opts \\ []) do
    name
    |> instance(namespace, opts)
    |> put_in(~w(spec passwordSecretRef), %{
      "name" => name,
      "key" => "password"
    })
  end

  @spec instance_with_plain_pw(
          name :: binary(),
          namespace :: binary(),
          password :: binary(),
          opts :: Keyword.t()
        ) ::
          map()
  def instance_with_plain_pw(
        name,
        namespace,
        password \\ System.fetch_env!("POSTGRES_PASSWORD"),
        opts \\ []
      ) do
    name
    |> instance(namespace, opts)
    |> put_in(~w(spec plainPassword), password)
  end

  @spec database(
          name :: binary(),
          namespace :: binary(),
          instance :: {:cluster | :namespaced, map()},
          params :: map(),
          opts :: Keyword.t()
        ) ::
          map()
  def database(name, namespace, instance, params \\ %{}, opts \\ []) do
    database =
      ~y"""
      apiVersion: kompost.chuge.li/v1alpha1
      kind: PostgresDatabase
      metadata:
        name: #{name}
        namespace: #{namespace}
      """
      |> Map.put("spec", %{"params" => params})
      |> apply_opts(opts)

    case instance do
      {:cluster, cluster_instance} ->
        put_in(database, ~w(spec clusterInstanceRef), %{
          "name" => cluster_instance["metadata"]["name"]
        })

      {:namespaced, ns_instance} ->
        put_in(database, ~w(spec instanceRef), %{
          "name" => ns_instance["metadata"]["name"]
        })
    end
  end

  @spec password_secret(name :: binary(), namespace :: binary()) :: map()
  def password_secret(name, namespace) do
    ~y"""
    apiVersion: v1
    kind: Secret
    metadata:
      name: #{name}
      namespace: #{namespace}
    stringData:
      password: #{System.fetch_env!("POSTGRES_PASSWORD")}
    """
  end
end
