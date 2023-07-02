defmodule Kompost.Test.Kompo.Postgres.ResourceHelper do
  @moduledoc false

  import Kompost.Test.GlobalResourceHelper
  import YamlElixir.Sigil

  @spec cluster_instance(name :: binary(), opts :: Keyword.t()) :: map()
  def cluster_instance(name, opts \\ []) do
    ~y"""
    apiVersion: kompost.chuge.li/v1alpha1
    kind: PostgresClusterInstance
    metadata:
      name: #{name}
    spec:
      hostname: #{System.get_env("POSTGRES_HOST", "127.0.0.1")}
      port: #{System.fetch_env!("POSTGRES_EXPOSED_PORT")}
      username: #{System.fetch_env!("POSTGRES_USER")}
      plainPassword: #{System.fetch_env!("POSTGRES_PASSWORD")}
    """
    |> apply_opts(opts)
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
      "key" => System.fetch_env!("POSTGRES_PASSWORD")
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
          instance :: map(),
          params :: map(),
          opts :: Keyword.t()
        ) ::
          map()
  def database(name, namespace, instance, params \\ %{}, opts \\ []) do
    ~y"""
    apiVersion: kompost.chuge.li/v1alpha1
    kind: PostgresDatabase
    metadata:
      name: #{name}
      namespace: #{namespace}
    spec:
      instanceRef:
        name: #{instance["metadata"]["name"]}
    """
    |> put_in(~w(spec params), params)
    |> apply_opts(opts)
  end
end
