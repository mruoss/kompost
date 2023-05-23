defmodule Kompost.Test.GlobalResourceHelper do
  @moduledoc """
  Global Resource Helper
  """

  import YamlElixir.Sigil

  @spec create_namespace(name :: binary(), conn :: K8s.Conn.t()) :: map()
  def create_namespace(name, conn) do
    ~y"""
    apiVersion: v1
    kind: Namespace
    metadata:
      name: #{name}
    """
    |> k8s_apply(conn)
  end

  @spec apply_opts(resource :: map(), opts :: Keyword.t()) :: map()
  def apply_opts(resource, opts) do
    labels = Keyword.get(opts, :labels, %{})
    annotations = Keyword.get(opts, :annotations, %{})

    resource
    |> put_in(~w(metadata labels), labels)
    |> put_in(~w(metadata annotations), annotations)
  end

  @spec k8s_apply(map, K8s.Conn.t()) :: map()
  def k8s_apply(resource, conn) do
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
