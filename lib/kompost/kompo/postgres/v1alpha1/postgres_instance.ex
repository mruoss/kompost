defmodule Kompost.Kompo.Postgres.V1Alpha1.PostgresInstance do
  @moduledoc """
  Postgres Instance CRD v1alpha1 version.
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
            - required: ["hostname", "port", "username", "passwordSecretRef"]
            - required: ["hostname", "port", "username", "plainPassword"]
            properties:
              hostname:
                type: string
              port:
                type: integer
              username:
                type: string
              passwordSecretRef:
                type: object
                required: ["name", "key"]
                properties:
                  name:
                    type: string
                  key:
                    type: string
              plainPassword:
                type: string
                description: "It's not safe to save passwords in plaintext. Consider using passwordSecretRef instead."
              ssl:
                type: object
                properties:
                  enabled:
                    type: boolean
                    description: "Set to true if ssl should be used."
                  verify:
                    type: string
                    description: "'verify_none' or 'verify_peer'. Defaults to 'verify_none'"
                  ca:
                    type: string
                    description: "CA certificates used to validate the server cert against."
      """a
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
