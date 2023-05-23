defmodule Kompost.Kompo.Temporal.V1Alpha1.TemporalNamespace do
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
            required: ["apiServerRef", "description", "workflowExecutionRetentionPeriod"]
            properties:
              apiServerRef:
                description: "Referemce to a resource of kind TemporalApiServer"
                type: object
                properties:
                  namespace:
                    type: string
                  name:
                    type: string
              description:
                type: string
                description: "Namespace description"
              ownerEmail:
                type: string
              workflowExecutionRetentionPeriod:
                description: "Workflow execution retention period in seconds"
                type: integer
                minimum: 3600
      """a
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
