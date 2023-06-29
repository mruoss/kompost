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
    |> k8s_apply!(conn)
  end

  @spec apply_opts(resource :: map(), opts :: Keyword.t()) :: map()
  def apply_opts(resource, opts) do
    labels = Keyword.get(opts, :labels, %{})
    annotations = Keyword.get(opts, :annotations, %{})

    resource
    |> put_in(~w(metadata labels), labels)
    |> put_in(~w(metadata annotations), annotations)
  end

  defdelegate k8s_apply!(resource, conn), to: Kompost.Tools.Resource
  defdelegate delete!(resource, conn), to: Kompost.Tools.Resource
  defdelegate wait_until_observed!(resource, conn, timeout), to: Kompost.Tools.Resource
  defdelegate wait_until!(resource, conn, find, eval, timeout), to: Kompost.Tools.Resource

  defdelegate wait_for_condition!(resource, conn, condition, status \\ "True", timeout),
    to: Kompost.Tools.Resource
end
