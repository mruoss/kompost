defmodule Kompost.Kompo.Temporal.V1Alpha1.TemporalApiServer do
  @moduledoc """
  Connection to a Temporal Cluster
  """

  import YamlElixir.Sigil

  use Bonny.API.Version,
    hub: true

  @impl true
  def manifest() do
    struct!(
      defaults(),
      name: "v1alpha1",
      schema: ~y"""
      :openAPIV3Schema:
        :type: object
        :required: ["spec"]
        :properties:
          :spec:
            type: object
            anyOf:
            - required: ["host", "port"]
            - required: ["host", "port"]
            properties:
              host:
                type: string
              port:
                type: integer
      """a
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
