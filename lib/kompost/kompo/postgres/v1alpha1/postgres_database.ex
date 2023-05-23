defmodule Kompost.Kompo.Postgres.V1Alpha1.PostgresDatabase do
  @moduledoc """
  Postgres Database CRD v1alpha1 version.
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
            required: ["instanceRef"]
            properties:
              instanceRef:
                type: object
                properties:
                  namespace:
                    type: string
                  name:
                    type: string
          :status:
            :type: :object
            :properties:
              sql_db_name:
                type: string
              users:
                type: array
                items:
                  type: object
                  properties:
                    username:
                      type: string
                    secret:
                      type: string
      """a,
      additionalPrinterColumns: [
        %{
          name: "Postgres DB name",
          type: "string",
          description: "Name of the database on the Postgres instance",
          jsonPath: ".status.sql_db_name"
        }
      ]
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
