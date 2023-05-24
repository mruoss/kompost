defmodule Kompost.Test.Kompo.Temporal.ResourceHelper do
  @moduledoc false

  import Kompost.Test.GlobalResourceHelper
  import YamlElixir.Sigil

  @spec api_server(name :: binary(), ns :: binary(), opts :: Keyword.t()) :: map()
  def api_server(name, ns, opts \\ []) do
    ~y"""
    apiVersion: kompost.chuge.li/v1alpha1
    kind: TemporalApiServer
    metadata:
      name: #{name}
      namespace: #{ns}
    spec:
      host: 127.0.0.1
      port: #{System.fetch_env!("TEMPORAL_EXPOSED_PORT")}
    """
    |> apply_opts(opts)
  end

  @spec namespace(
          name :: binary(),
          ns :: binary(),
          spec :: map(),
          api_server :: map(),
          opts :: Keyword.t()
        ) ::
          map()
  def namespace(name, ns, api_server, spec, opts \\ []) do
    ~y"""
    apiVersion: kompost.chuge.li/v1alpha1
    kind: TemporalNamespace
    metadata:
      name: #{name}
      namespace: #{ns}
    """
    |> Map.put("spec", spec)
    |> put_in(~w(spec apiServerRef), %{
      "name" => api_server["metadata"]["name"],
      "namespace" => api_server["metadata"]["namespace"]
    })
    |> apply_opts(opts)
  end
end
